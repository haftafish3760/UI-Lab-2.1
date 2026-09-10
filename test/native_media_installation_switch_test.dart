import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';
import 'support/storage/fake_native_media_gateway.dart';

void main() {
  for (final retained in [false, true]) {
    test(
      'installation pause protects native handoff: retained=$retained',
      () async {
        final root = await Directory.systemTemp.createTemp('native-switch-');
        final db = LocalDatabase.file(File('${root.path}/db.sqlite'));
        final requests = LocalMediaPickerRequestStore(db);
        final gateway = FakeJournaledNativeMediaGateway();
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
          final request = await requests.begin(
            organizationId: 'org',
            ownerId: 'alice',
            destination: MediaPickerDestination.receipt,
            targetId: 'receipt',
            targetRevision: 1,
            source: MediaPickerSource.camera,
          );
          gateway.requestId = request.requestId;
          gateway.onAcknowledge = (_) async =>
              throw StateError('native unavailable');
          if (retained) {
            final source = await File(
              '${root.path}/photo.jpg',
            ).writeAsBytes([1, 3, 5]);
            gateway.lost = [
              MediaPickerReturnedFile(path: source.path, name: 'photo.jpg'),
            ];
            await expectLater(
              coordinator.recover(organizationId: 'org', ownerId: 'alice'),
              throwsStateError,
            );
          }
          await expectLater(coordinator.pauseOperations(), throwsStateError);
          final pending = await requests.findFor(
            organizationId: 'org',
            ownerId: 'alice',
          );
          expect(pending!.requestId, request.requestId);
          if (retained) {
            expect(pending.retainedAttachmentIds, hasLength(1));
            gateway.onAcknowledge = (_) async {};
          } else {
            // A failed pause must release its lease so explicit discard can run.
            await coordinator.discardSelection(
              request: pending,
              organizationId: 'org',
              ownerId: 'alice',
            );
          }
          final lease = await coordinator.pauseOperations();
          lease.release();
          if (retained) expect(gateway.acknowledgements, 3);
          await db.verifyIntegrity();
        } finally {
          await db.close();
          await root.delete(recursive: true);
        }
      },
    );
  }
}
