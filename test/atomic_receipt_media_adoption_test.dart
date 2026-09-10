import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/receipts/atomic_receipt_media_adoption.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';

void main() {
  test(
    'media acknowledgment failure rolls back receipt and caches; retry adopts one original',
    () async {
      final root = await Directory.systemTemp.createTemp('receipt-media-');
      var persistence = await LocalPersistence.open(directory: root);
      final permissions = receiptDraftUiLabOwnerPermissions();
      var controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(persistence.receiptDrafts),
        permissions,
      );
      try {
        await controller.load();
        final receipt = (await controller.create(
          draftId: 'receipt',
          title: 'Receipt',
          expenseDate: DateTime(2030),
          evidence: const [],
          occurredAtUtc: DateTime.utc(2030),
        ))!;
        final requests = LocalMediaPickerRequestStore(persistence.database);
        final pending = await requests.begin(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          destination: MediaPickerDestination.receipt,
          targetId: receipt.draftId,
          targetRevision: receipt.lifecycle.revision,
          source: MediaPickerSource.camera,
        );
        final source = File('${root.path}/camera.jpg');
        await source.writeAsBytes([1, 2, 3, 4, 5]);
        await requests.recordReturnedFiles(
          request: pending,
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          files: [
            MediaPickerReturnedFile(
              path: source.path,
              name: 'Original receipt.jpg',
            ),
          ],
        );
        final retained =
            await MediaPickerResultRetention(
              requests: requests,
              attachments: LocalAttachmentStore(persistence.database),
            ).retain(
              requestId: pending.requestId,
              organizationId: permissions.organizationId,
              ownerId: permissions.actorEmployeeId,
            );
        final service = AtomicReceiptMediaAdoption(persistence.receiptDrafts);
        Future<void> adopt() async {
          await service.adopt(
            request: retained,
            permissions: permissions,
            occurredAtUtc: DateTime.utc(2030, 1, 2),
          );
        }

        await persistence.database.customStatement(
          "CREATE TRIGGER fail_media_ack BEFORE DELETE ON local_metadata WHEN OLD.metadata_key = 'native.image-picker.request.v1' BEGIN SELECT RAISE(ABORT, 'injected acknowledgment failure'); END",
        );
        await expectLater(adopt(), throwsA(isA<Exception>()));
        await controller.load();
        expect(
          controller.recordById('receipt')!.lifecycle.revision,
          receipt.lifecycle.revision,
        );
        expect(controller.recordById('receipt')!.activeEvidence, isEmpty);
        final sql = await persistence.database
            .customSelect(
              "SELECT revision FROM local_records WHERE domain = 'receipt-drafts/records' AND record_id = 'receipt'",
            )
            .getSingle();
        expect(sql.read<int>('revision'), receipt.lifecycle.revision);
        expect(
          (await requests.findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          ))!.requestId,
          retained.requestId,
        );
        await persistence.database.customStatement(
          'DROP TRIGGER fail_media_ack',
        );
        await adopt();
        await controller.load();
        final updated = controller.recordById('receipt')!;
        expect(updated.lifecycle.revision, receipt.lifecycle.revision + 1);
        expect(
          updated.activeEvidence.single.originalName,
          'Original receipt.jpg',
        );
        expect(
          await File(updated.activeEvidence.single.localPath).readAsBytes(),
          [1, 2, 3, 4, 5],
        );
        expect(
          await requests.findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          ),
          isNull,
        );
        await expectLater(
          adopt(),
          throwsA(isA<ReceiptDraftRevisionConflictException>()),
        );
        controller.dispose();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: root);
        controller = ReceiptDraftUiController(
          AuthorizedReceiptDraftService(persistence.receiptDrafts),
          permissions,
        );
        await controller.load();
        expect(controller.recordById('receipt')!.activeEvidence, hasLength(1));
        expect(
          controller.recordById('receipt')!.lifecycle.revision,
          updated.lifecycle.revision,
        );
        expect(
          (await persistence.database
                  .customSelect(
                    "SELECT COUNT(*) AS n FROM local_records WHERE domain = 'expenses/records'",
                  )
                  .getSingle())
              .read<int>('n'),
          0,
        );
        await persistence.database.verifyIntegrity();
      } finally {
        controller.dispose();
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
}
