import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

void main() {
  test(
    'native source checkpoint survives failed retention and restart; retry retains once',
    () async {
      final root = await Directory.systemTemp.createTemp('media-source-');
      final file = File('${root.path}/db.sqlite');
      var db = LocalDatabase.file(file);
      try {
        var requests = LocalMediaPickerRequestStore(db);
        var retention = MediaPickerResultRetention(
          requests: requests,
          attachments: LocalAttachmentStore(db),
        );
        final pending = await requests.begin(
          organizationId: 'org',
          ownerId: 'alice',
          destination: MediaPickerDestination.estimate,
          targetId: 'input-1',
          targetRevision: 4,
          source: MediaPickerSource.library,
        );
        var source = File('${root.path}/selected.jpg');
        final sources = [
          MediaPickerReturnedFile(
            path: source.path,
            name: 'Original photo.jpg',
          ),
        ];
        await db.customStatement(
          "CREATE TRIGGER fail_native_result BEFORE UPDATE ON local_metadata BEGIN SELECT RAISE(ABORT, 'injected native checkpoint failure'); END",
        );
        await expectLater(
          requests.recordReturnedFiles(
            request: pending,
            organizationId: 'org',
            ownerId: 'alice',
            files: sources,
          ),
          throwsA(isA<Exception>()),
        );
        expect(
          (await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          ))!.returnedFiles,
          isNull,
        );
        await db.customStatement('DROP TRIGGER fail_native_result');
        final received = await requests.recordReturnedFiles(
          request: pending,
          organizationId: 'org',
          ownerId: 'alice',
          files: sources,
        );
        sources.clear();
        expect(received.returnedFiles!.single.name, 'Original photo.jpg');
        await expectLater(
          retention.retain(
            requestId: pending.requestId,
            organizationId: 'org',
            ownerId: 'alice',
          ),
          throwsA(isA<FileSystemException>()),
        );
        expect(
          (await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          ))!.returnedFiles!.single.path,
          source.path,
        );
        await expectLater(
          requests.recordReturnedFiles(
            request: pending,
            organizationId: 'org',
            ownerId: 'alice',
            files: [
              MediaPickerReturnedFile(
                path: '${root.path}/different.jpg',
                name: 'Different',
              ),
            ],
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        await db.close();
        db = LocalDatabase.file(file);
        requests = LocalMediaPickerRequestStore(db);
        retention = MediaPickerResultRetention(
          requests: requests,
          attachments: LocalAttachmentStore(db),
        );
        final reopened = (await requests.findFor(
          organizationId: 'org',
          ownerId: 'alice',
        ))!;
        expect(reopened.toJson(), received.toJson());
        await source.writeAsBytes([1, 3, 5, 7]);
        await expectLater(
          retention.retain(
            requestId: pending.requestId,
            organizationId: 'org',
            ownerId: 'bob',
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        final retained = await retention.retain(
          requestId: pending.requestId,
          organizationId: 'org',
          ownerId: 'alice',
        );
        expect(retained.retainedAttachmentIds, hasLength(1));
        expect(
          (await retention.retain(
            requestId: pending.requestId,
            organizationId: 'org',
            ownerId: 'alice',
          )).toJson(),
          retained.toJson(),
        );
        final bytes = await LocalAttachmentStore(
          db,
        ).verifiedFiles(organizationId: 'org', ownerIds: {'alice'});
        expect(bytes, hasLength(1));
        expect(await bytes.single.readAsBytes(), [1, 3, 5, 7]);
        await db.verifyIntegrity();
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
}
