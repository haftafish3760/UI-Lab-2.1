import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';

import 'support/storage/fake_native_media_gateway.dart';

void main() {
  test(
    'pause waits for native result retention and rejects new launches',
    () async {
      final root = await Directory.systemTemp.createTemp('native-media-drain-');
      final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
      final requests = LocalMediaPickerRequestStore(db);
      final returned = Completer<List<MediaPickerReturnedFile>>();
      final launched = Completer<void>();
      final gateway = FakeNativeMediaGateway()
        ..onPick = () {
          launched.complete();
          return returned.future;
        };
      final coordinator = NativeMediaPickerCoordinator(
        requests: requests,
        retention: MediaPickerResultRetention(
          requests: requests,
          attachments: LocalAttachmentStore(db),
        ),
        gateway: gateway,
        authorize:
            ({
              required organizationId,
              required ownerId,
              required destination,
              required targetId,
              required targetRevision,
            }) async {},
      );
      try {
        final picked = coordinator.start(
          organizationId: 'org',
          ownerId: 'alice',
          destination: MediaPickerDestination.receipt,
          targetId: 'receipt',
          targetRevision: 1,
          source: MediaPickerSource.camera,
        );
        await launched.future;
        var drained = false;
        final pending = coordinator.pauseOperations().then((lease) {
          drained = true;
          return lease;
        });
        await expectLater(
          coordinator.recover(organizationId: 'org', ownerId: 'alice'),
          throwsStateError,
        );
        expect(drained, isFalse);
        final photo = File('${root.path}/photo.jpg');
        await photo.writeAsBytes([2, 4, 6], flush: true);
        returned.complete([
          MediaPickerReturnedFile(path: photo.path, name: 'Photo.jpg'),
        ]);
        final result = await picked;
        final lease = await pending;
        expect(result!.retainedAttachmentIds, hasLength(1));
        expect(
          (await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          ))!.retainedAttachmentIds,
          result.retainedAttachmentIds,
        );
        expect(gateway.picks, 1);
        expect(gateway.recoveries, 0);
        lease.release();
        expect(
          await coordinator.recover(organizationId: 'org', ownerId: 'alice'),
          isNotNull,
        );
      } finally {
        if (!returned.isCompleted) returned.complete([]);
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'durable intent precedes native launch; restart recovery is scoped and serialized',
    () async {
      final root = await Directory.systemTemp.createTemp('native-media-');
      final file = File('${root.path}/db.sqlite');
      var db = LocalDatabase.file(file);
      var requests = LocalMediaPickerRequestStore(db);
      final gateway = FakeNativeMediaGateway();
      var allowed = true;
      NativeMediaPickerCoordinator coordinator() =>
          NativeMediaPickerCoordinator(
            requests: requests,
            retention: MediaPickerResultRetention(
              requests: requests,
              attachments: LocalAttachmentStore(db),
            ),
            gateway: gateway,
            authorize:
                ({
                  required organizationId,
                  required ownerId,
                  required destination,
                  required targetId,
                  required targetRevision,
                }) async {
                  if (!allowed) throw StateError('denied');
                },
          );
      var media = coordinator();
      Future<LocalMediaPickerRequest?> start() => media.start(
        organizationId: 'org',
        ownerId: 'alice',
        destination: MediaPickerDestination.receipt,
        targetId: 'receipt',
        targetRevision: 1,
        source: MediaPickerSource.camera,
      );
      try {
        allowed = false;
        await expectLater(start(), throwsStateError);
        expect(gateway.picks, 0);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'alice'),
          isNull,
        );
        allowed = true;
        await db.customStatement(
          "CREATE TRIGGER fail_intent BEFORE INSERT ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected intent failure'); END",
        );
        await expectLater(start(), throwsA(isA<Exception>()));
        expect(gateway.picks, 0);
        await db.customStatement('DROP TRIGGER fail_intent');
        gateway.onPick = () async {
          final pending = await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          );
          expect(pending!.targetId, 'receipt');
          throw StateError('simulated activity destruction');
        };
        await expectLater(start(), throwsStateError);
        final pending = (await requests.findFor(
          organizationId: 'org',
          ownerId: 'alice',
        ))!;
        await db.close();
        db = LocalDatabase.file(file);
        requests = LocalMediaPickerRequestStore(db);
        media = coordinator();
        final source = File('${root.path}/camera.jpg');
        await source.writeAsBytes([2, 4, 6]);
        gateway.lost = [
          MediaPickerReturnedFile(
            path: source.path,
            name: 'Camera original.jpg',
          ),
        ];
        expect(
          await media.recover(organizationId: 'org', ownerId: 'bob'),
          isNull,
        );
        expect(gateway.recoveries, 0);
        allowed = false;
        await expectLater(
          media.recover(organizationId: 'org', ownerId: 'alice'),
          throwsStateError,
        );
        expect(gateway.recoveries, 0);
        allowed = true;
        final recovered = await Future.wait([
          media.recover(organizationId: 'org', ownerId: 'alice'),
          media.recover(organizationId: 'org', ownerId: 'alice'),
        ]);
        expect(gateway.recoveries, 1);
        expect(recovered.first!.requestId, pending.requestId);
        expect(recovered.first!.toJson(), recovered.last!.toJson());
        expect(recovered.first!.retainedAttachmentIds, hasLength(1));
        await requests.cancel(
          request: recovered.first!,
          organizationId: 'org',
          ownerId: 'alice',
        );
        gateway.onPick = () async => [];
        expect(await start(), isNull);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'alice'),
          isNull,
        );
        await db.verifyIntegrity();
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'empty recovery preserves intent; access revoked after return preserves source checkpoint',
    () async {
      final root = await Directory.systemTemp.createTemp('native-return-');
      final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
      final requests = LocalMediaPickerRequestStore(db);
      final gateway = FakeNativeMediaGateway();
      var allowed = true;
      final media = NativeMediaPickerCoordinator(
        requests: requests,
        retention: MediaPickerResultRetention(
          requests: requests,
          attachments: LocalAttachmentStore(db),
        ),
        gateway: gateway,
        authorize:
            ({
              required organizationId,
              required ownerId,
              required destination,
              required targetId,
              required targetRevision,
            }) async {
              if (!allowed) throw StateError('denied');
            },
      );
      try {
        final pending = await requests.begin(
          organizationId: 'org',
          ownerId: 'alice',
          destination: MediaPickerDestination.estimate,
          targetId: 'draft',
          targetRevision: 1,
          source: MediaPickerSource.library,
        );
        final empty = await media.recover(
          organizationId: 'org',
          ownerId: 'alice',
        );
        expect(empty!.requestId, pending.requestId);
        expect(empty.returnedFiles, isNull);
        await requests.cancel(
          request: empty,
          organizationId: 'org',
          ownerId: 'alice',
        );
        final source = File('${root.path}/photo.jpg');
        await source.writeAsBytes([9, 8, 7]);
        gateway.onPick = () async {
          allowed = false;
          return [
            MediaPickerReturnedFile(path: source.path, name: 'Photo.jpg'),
          ];
        };
        await expectLater(
          media.start(
            organizationId: 'org',
            ownerId: 'alice',
            destination: MediaPickerDestination.estimate,
            targetId: 'draft',
            targetRevision: 1,
            source: MediaPickerSource.library,
          ),
          throwsStateError,
        );
        final checkpoint = (await requests.findFor(
          organizationId: 'org',
          ownerId: 'alice',
        ))!;
        expect(checkpoint.returnedFiles!.single.name, 'Photo.jpg');
        expect(checkpoint.retainedAttachmentIds, isNull);
        allowed = true;
        final recovered = await media.recover(
          organizationId: 'org',
          ownerId: 'alice',
        );
        expect(recovered!.retainedAttachmentIds, hasLength(1));
        expect(gateway.recoveries, 1); // Only the earlier empty recovery.
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'file retry rejects wrong scope and stale identity; cancellation preserves a later request',
    () async {
      final root = await Directory.systemTemp.createTemp('file-retry-');
      final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
      final requests = LocalMediaPickerRequestStore(db);
      final gateway = FakeNativeMediaGateway();
      var allowed = true;
      final media = NativeMediaPickerCoordinator(
        requests: requests,
        retention: MediaPickerResultRetention(
          requests: requests,
          attachments: LocalAttachmentStore(db),
        ),
        gateway: gateway,
        authorize:
            ({
              required organizationId,
              required ownerId,
              required destination,
              required targetId,
              required targetRevision,
            }) async {
              expect(organizationId, 'org');
              expect(ownerId, 'alice');
              expect(destination, MediaPickerDestination.receipt);
              expect(targetId, 'saved-receipt');
              expect(targetRevision, 3);
              if (!allowed) throw StateError('revoked');
            },
      );
      Future<LocalMediaPickerRequest> begin() => requests.begin(
        organizationId: 'org',
        ownerId: 'alice',
        destination: MediaPickerDestination.receipt,
        targetId: 'saved-receipt',
        targetRevision: 3,
        source: MediaPickerSource.files,
      );
      Future<LocalMediaPickerRequest?> retry(
        String id, {
        String organization = 'org',
        String owner = 'alice',
      }) => media.resumeFileSelection(
        organizationId: organization,
        ownerId: owner,
        requestId: id,
      );
      try {
        final original = await begin();
        await expectLater(
          retry(original.requestId, owner: 'bob'),
          throwsStateError,
        );
        await expectLater(
          retry(original.requestId, organization: 'other'),
          throwsStateError,
        );
        await expectLater(retry('stale-request'), throwsStateError);
        allowed = false;
        await expectLater(retry(original.requestId), throwsStateError);
        expect(gateway.picks, 0);
        allowed = true;
        // Startup cannot consume the unrelated camera cache for a file request.
        gateway.lost = [
          MediaPickerReturnedFile(
            path: '${root.path}/unrelated.jpg',
            name: 'Unrelated.jpg',
          ),
        ];
        expect(
          (await media.recover(
            organizationId: 'org',
            ownerId: 'alice',
          ))!.requestId,
          original.requestId,
        );
        expect(gateway.recoveries, 0);
        expect(gateway.lost, hasLength(1));
        // Empty is an explicit picker cancellation, not a missing startup result.
        gateway.onPick = () async => [];
        expect(await retry(original.requestId), isNull);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'alice'),
          isNull,
        );
        final replacement = await begin();
        await expectLater(retry(original.requestId), throwsStateError);
        expect(
          (await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          ))!.requestId,
          replacement.requestId,
        );
        expect(gateway.picks, 1);

        final source = File('${root.path}/receipt.pdf');
        await source.writeAsBytes([1, 2, 3, 4]);
        gateway.onPick = () async {
          allowed = false;
          return [
            MediaPickerReturnedFile(path: source.path, name: 'Receipt.pdf'),
          ];
        };
        await expectLater(retry(replacement.requestId), throwsStateError);
        final checkpoint = (await requests.findFor(
          organizationId: 'org',
          ownerId: 'alice',
        ))!;
        expect(checkpoint.returnedFiles!.single.path, source.path);
        expect(checkpoint.retainedAttachmentIds, isNull);
        allowed = true;
        gateway.onPick = () async =>
            throw StateError('Must not replace a checkpointed selection');
        final retained = (await retry(replacement.requestId))!;
        expect(retained.retainedAttachmentIds, hasLength(1));
        expect(retained.targetId, 'saved-receipt');
        expect(retained.targetRevision, 3);
        expect(gateway.picks, 2);
        expect(
          (await retry(replacement.requestId))!.retainedAttachmentIds,
          retained.retainedAttachmentIds,
        );
        expect(gateway.picks, 2);
        expect(gateway.recoveries, 0);
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
}
