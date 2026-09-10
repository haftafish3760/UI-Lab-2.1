import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';

import 'support/storage/fake_native_media_gateway.dart';

void main() {
  test(
    'native discard failure retains SQL intent and validates scope before retry',
    () async {
      final root = await Directory.systemTemp.createTemp('media-discard-');
      final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
      final requests = LocalMediaPickerRequestStore(db);
      final gateway = FakeJournaledNativeMediaGateway();
      var attempts = 0;
      gateway.onAbandon = () async {
        attempts++;
        throw StateError('native discard failed');
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
        await expectLater(
          coordinator.start(
            organizationId: 'org',
            ownerId: 'owner',
            destination: MediaPickerDestination.estimate,
            targetId: 'input',
            targetRevision: 1,
            source: MediaPickerSource.camera,
          ),
          throwsStateError,
        );
        final pending = (await requests.findFor(
          organizationId: 'org',
          ownerId: 'owner',
        ))!;
        expect(attempts, 1);
        await expectLater(
          coordinator.discardSelection(
            request: pending,
            organizationId: 'org',
            ownerId: 'other',
          ),
          throwsA(anything),
        );
        expect(attempts, 1);
        gateway.onAbandon = () async {
          attempts++;
        };
        await coordinator.discardSelection(
          request: pending,
          organizationId: 'org',
          ownerId: 'owner',
        );
        expect(attempts, 2);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'owner'),
          isNull,
        );
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'journal acknowledgement follows durable retention and retries after reopen',
    () async {
      final root = await Directory.systemTemp.createTemp('media-journal-ack-');
      var db = LocalDatabase.file(File('${root.path}/db.sqlite'));
      final source = File('${root.path}/source');
      final gateway = FakeJournaledNativeMediaGateway();
      NativeMediaPickerCoordinator createCoordinator() {
        final requests = LocalMediaPickerRequestStore(db);
        return NativeMediaPickerCoordinator(
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
      }

      try {
        gateway.lost = [
          MediaPickerReturnedFile(path: source.path, name: 'photo'),
        ];
        gateway.onAcknowledge = (request) async {
          final saved = (await LocalMediaPickerRequestStore(
            db,
          ).findFor(organizationId: 'org', ownerId: 'owner'))!;
          expect(saved.retainedAttachmentIds, request.retainedAttachmentIds);
          expect(saved.retainedAttachmentIds, hasLength(1));
          throw StateError('native acknowledgement interrupted');
        };
        await expectLater(
          createCoordinator().start(
            organizationId: 'org',
            ownerId: 'owner',
            destination: MediaPickerDestination.estimate,
            targetId: 'estimate-input',
            targetRevision: 1,
            source: MediaPickerSource.camera,
          ),
          throwsA(isA<FileSystemException>()),
        );
        expect(gateway.acknowledgements, 0);
        await source.writeAsBytes([4, 8, 15], flush: true);
        await expectLater(
          createCoordinator().recover(organizationId: 'org', ownerId: 'owner'),
          throwsStateError,
        );
        expect(gateway.acknowledgements, 1);
        await db.close();
        db = LocalDatabase.file(File('${root.path}/db.sqlite'));
        await source.delete();
        gateway.onAcknowledge = (request) async {
          final files = await LocalAttachmentStore(db).verifiedFiles(
            organizationId: 'org',
            ownerIds: {'owner'},
            attachmentIds: request.retainedAttachmentIds!.toSet(),
          );
          expect(await files.single.readAsBytes(), [4, 8, 15]);
        };
        final recovered = await createCoordinator().recover(
          organizationId: 'org',
          ownerId: 'owner',
        );
        expect(recovered!.retainedAttachmentIds, hasLength(1));
        expect(gateway.acknowledgements, 2);
        expect(
          gateway.picks,
          0,
          reason: 'Legacy pick API must not bypass request identity.',
        );
        expect(
          gateway.recoveries,
          0,
          reason: 'Retained input requires acknowledgement, not reimport.',
        );
      } finally {
        await db.close();
        await root.delete(recursive: true);
      }
    },
  );
}
