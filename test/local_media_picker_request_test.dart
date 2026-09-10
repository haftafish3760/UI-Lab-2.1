import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';

void main() {
  test(
    'picker ownership survives reopen; adoption rollback and stale retry are safe',
    () async {
      final root = await Directory.systemTemp.createTemp('media-request-');
      final file = File('${root.path}/db.sqlite');
      var db = LocalDatabase.file(file);
      var requests = LocalMediaPickerRequestStore(db);
      Future<LocalMediaPickerRequest> begin({String owner = 'alice'}) =>
          requests.begin(
            organizationId: 'company',
            ownerId: owner,
            destination: MediaPickerDestination.receipt,
            targetId: 'receipt-1',
            targetRevision: 3,
            source: MediaPickerSource.camera,
          );
      try {
        await db.customSelect('SELECT 1').get();
        await db.customStatement(
          "CREATE TRIGGER fail_intent BEFORE INSERT ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected intent failure'); END",
        );
        await expectLater(begin(), throwsA(isA<Exception>()));
        expect(
          await requests.findFor(organizationId: 'company', ownerId: 'alice'),
          isNull,
        );
        await db.customStatement('DROP TRIGGER fail_intent');
        final pending = await begin();
        await expectLater(
          begin(owner: 'bob'),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(
          await requests.findFor(organizationId: 'company', ownerId: 'bob'),
          isNull,
        );
        expect(
          await requests.findFor(organizationId: 'other', ownerId: 'alice'),
          isNull,
        );
        await db.close();
        db = LocalDatabase.file(file);
        requests = LocalMediaPickerRequestStore(db);
        var recovered = (await requests.findFor(
          organizationId: 'company',
          ownerId: 'alice',
        ))!;
        expect(recovered.toJson(), pending.toJson());
        final source = File('${root.path}/photo.jpg');
        await source.writeAsBytes([1, 2, 3]);
        final retained = await LocalAttachmentStore(
          db,
        ).retain(source: source, organizationId: 'company', ownerId: 'alice');
        recovered = await requests.retainResults(
          request: recovered,
          organizationId: 'company',
          ownerId: 'alice',
          attachmentIds: [retained.uri.pathSegments.last.split('.').first],
        );

        var calls = 0;
        Future<void> adopt() async {
          calls++;
          await LocalRecordStore(db).commit(
            organizationId: 'company',
            commandId: 'adopt-${pending.requestId}',
            writes: [
              LocalRecordWrite(
                domain: 'qa/media',
                recordId: 'photo-1',
                ownerId: 'alice',
                expectedRevision: 0,
                payload: {'requestId': pending.requestId},
              ),
            ],
            occurredAt: DateTime.now(),
          );
        }

        Future<void> consume({String owner = 'alice'}) => requests.consume(
          request: recovered,
          organizationId: 'company',
          ownerId: owner,
          commit: adopt,
        );
        await expectLater(
          consume(owner: 'bob'),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(calls, 0);
        await db.customStatement(
          "CREATE TRIGGER fail_ack BEFORE DELETE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected ack failure'); END",
        );
        await expectLater(consume(), throwsA(isA<Exception>()));
        expect(
          await LocalRecordStore(db).read(
            organizationId: 'company',
            domain: 'qa/media',
            ownerIds: {'alice'},
          ),
          isEmpty,
        );
        expect(
          (await requests.findFor(
            organizationId: 'company',
            ownerId: 'alice',
          ))!.requestId,
          pending.requestId,
        );
        await db.customStatement('DROP TRIGGER fail_ack');
        await consume();
        expect(
          await requests.findFor(organizationId: 'company', ownerId: 'alice'),
          isNull,
        );
        expect(
          (await LocalRecordStore(db).read(
            organizationId: 'company',
            domain: 'qa/media',
            ownerIds: {'alice'},
          )).single.revision,
          1,
        );
        final next = await begin();
        expect(next.requestId, isNot(pending.requestId));
        await expectLater(consume(), throwsA(isA<LocalRecordConflict>()));
        expect(calls, 2); // Only the rolled-back adoption and successful retry.
        expect(
          (await requests.findFor(
            organizationId: 'company',
            ownerId: 'alice',
          ))!.requestId,
          next.requestId,
        );
        await db.close();
        db = LocalDatabase.file(file);
        await db.verifyIntegrity();
        requests = LocalMediaPickerRequestStore(db);
        expect(
          (await requests.findFor(
            organizationId: 'company',
            ownerId: 'alice',
          ))!.requestId,
          next.requestId,
        );
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );

  test('unrecognized pending request is never overwritten', () async {
    final root = await Directory.systemTemp.createTemp('media-unknown-');
    final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
    try {
      await db.customStatement('INSERT INTO local_metadata VALUES (?, ?)', [
        LocalMediaPickerRequestStore.metadataKey,
        '{"version":99}',
      ]);
      final requests = LocalMediaPickerRequestStore(db);
      await expectLater(
        requests.begin(
          organizationId: 'company',
          ownerId: 'alice',
          destination: MediaPickerDestination.estimate,
          targetId: 'draft-1',
          targetRevision: 1,
          source: MediaPickerSource.library,
        ),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect(
        (await db.customSelect('SELECT value FROM local_metadata').get()).single
            .read<String>('value'),
        '{"version":99}',
      );
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test(
    'retained results are scoped, immutable and preserved after a failed checkpoint',
    () async {
      final root = await Directory.systemTemp.createTemp('media-results-');
      final file = File('${root.path}/db.sqlite');
      var db = LocalDatabase.file(file);
      try {
        var requests = LocalMediaPickerRequestStore(db);
        final pending = await requests.begin(
          organizationId: 'company',
          ownerId: 'alice',
          destination: MediaPickerDestination.estimate,
          targetId: 'input-1',
          targetRevision: 2,
          source: MediaPickerSource.library,
        );
        var invoked = false;
        await expectLater(
          requests.consume(
            request: pending,
            organizationId: 'company',
            ownerId: 'alice',
            commit: () async {
              invoked = true;
            },
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(invoked, isFalse);
        final source = File('${root.path}/photo.jpg');
        await source.writeAsBytes([4, 5, 6]);
        Future<String> retain(String owner) async {
          final retained = await LocalAttachmentStore(
            db,
          ).retain(source: source, organizationId: 'company', ownerId: owner);
          return retained.uri.pathSegments.last.split('.').first;
        }

        final owned = await retain('alice');
        final other = await retain('bob');
        Future<LocalMediaPickerRequest> checkpoint(List<String> ids) =>
            requests.retainResults(
              request: pending,
              organizationId: 'company',
              ownerId: 'alice',
              attachmentIds: ids,
            );
        await expectLater(
          checkpoint([other]),
          throwsA(isA<LocalRecordConflict>()),
        );
        await expectLater(
          checkpoint([owned, owned]),
          throwsA(isA<ArgumentError>()),
        );
        await db.customStatement(
          "CREATE TRIGGER fail_result BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected result failure'); END",
        );
        await expectLater(checkpoint([owned]), throwsA(isA<Exception>()));
        expect(
          (await requests.findFor(
            organizationId: 'company',
            ownerId: 'alice',
          ))!.retainedAttachmentIds,
          isNull,
        );
        await db.customStatement('DROP TRIGGER fail_result');
        final staged = await checkpoint([owned]);
        expect((await checkpoint([owned])).toJson(), staged.toJson());
        final replacement = await retain('alice');
        await expectLater(
          checkpoint([replacement]),
          throwsA(isA<LocalRecordConflict>()),
        );
        await expectLater(
          requests.cancel(
            request: pending,
            organizationId: 'company',
            ownerId: 'alice',
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        await db.close();
        db = LocalDatabase.file(file);
        requests = LocalMediaPickerRequestStore(db);
        final reopened = (await requests.findFor(
          organizationId: 'company',
          ownerId: 'alice',
        ))!;
        expect(reopened.retainedAttachmentIds, [owned]);
        await requests.cancel(
          request: reopened,
          organizationId: 'company',
          ownerId: 'alice',
        );
        expect(
          await requests.findFor(organizationId: 'company', ownerId: 'alice'),
          isNull,
        );
        expect(
          (await LocalAttachmentStore(db).verifiedFiles(
            organizationId: 'company',
            ownerIds: {'alice'},
          )).length,
          2,
        );
        await db.verifyIntegrity();
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
}
