import 'dart:io';
import 'package:ui_lab_2_1/src/data/receipts/receipt_combined_preview.dart';
import 'package:image/image.dart' as img;
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_service.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_draft_state.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'resource refusal guidance survives SQLite restart with originals',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stitch_resource_',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      var session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      final workloads = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(probeAvailable: false),
      );
      await expectLater(
        ReceiptStitchDraftWorkflow(
          review,
          stitcher: ReceiptStitchService(workloads: workloads),
        ).process(),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      await review.session.close();
      await persistence.close();
      await workloads.dispose();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      expect(review.input.stitchState!.reasonCode, 'resource_probeUnavailable');
      expect(
        review.input.stitchState!.retryGuidance,
        contains('check available device storage'),
      );
      expect(review.input.stitchState!.attachmentId, isNull);
      for (final evidence in source.activeEvidence) {
        expect(await File(evidence.localPath).readAsBytes(), [1, 2, 3]);
      }
      await review.session.close();
      await persistence.close();
    },
  );
  test(
    'processed preview is retained and resolves after SQLite restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stitch_retained_',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      var session = await openEvidenceSession(persistence);
      final imports = <ReceiptEvidenceImport>[];
      for (var i = 0; i < 2; i++) {
        final image = img.Image(width: 320, height: 600);
        img.fill(image, color: img.ColorRgb8(245, 245, 245));
        for (var row = 0; row < 10; row++) {
          img.drawString(
            image,
            'PART ${i * 10 + row} 12.50',
            font: img.arial24,
            x: 20,
            y: 30 + row * 50,
            color: img.ColorRgb8(20, 20, 20),
          );
        }
        final file = File(
          '${directory.path}${Platform.pathSeparator}photo_$i.png',
        );
        await file.writeAsBytes(img.encodePng(image));
        imports.add(
          ReceiptEvidenceImport(
            sourcePath: file.path,
            originalName: 'photo_$i.png',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
        );
      }
      final source = (await session.receipts.create(
        draftId: 'stitched',
        title: 'Long receipt',
        expenseDate: DateTime(2030, 1, 2),
        evidence: imports,
        occurredAtUtc: DateTime.utc(2030, 1, 2),
      ))!;
      var review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      final workloads = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(
          physicalRamMb: 4096,
          availableRamMb: 2048,
          freeStorageBytes: 1024 * 1024 * 1024,
          thermal: 'nominal',
        ),
      );
      await ReceiptStitchDraftWorkflow(
        review,
        stitcher: ReceiptStitchService(workloads: workloads),
      ).process(manualZeroOverlapPairs: const [true]);
      expect(review.input.stitchState!.stage, ReceiptStitchDraftStage.ready);
      final attachmentId = review.input.stitchState!.attachmentId!;
      await workloads.dispose();
      await review.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      expect(review.input.stitchState!.attachmentId, attachmentId);
      final files = await LocalAttachmentStore(persistence.database)
          .verifiedFiles(
            organizationId: review.session.organizationId,
            ownerIds: {review.session.ownerId},
            attachmentIds: {attachmentId},
          );
      expect(img.decodeImage(await files.single.readAsBytes()), isNotNull);
      expect(await session.verifiedCombinedPreview(review), files.single.path);
      final otherSession = await openEvidenceSession(persistence);
      await expectLater(
        otherSession.verifiedCombinedPreview(review),
        throwsStateError,
      );
      for (final original in source.activeEvidence) {
        expect(await File(original.localPath).exists(), isTrue);
      }
      final confirmed = await review.confirm();
      expect(confirmed.activeStitchState!.attachmentId, attachmentId);
      await review.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: confirmed.lifecycle.revision,
      );
      expect(review.input.stitchState!.attachmentId, attachmentId);
      await review.session.close();
      await persistence.close();
    },
  );
  test(
    'SQLite reopen retains interrupted stitching and verifies original identities',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stitch_draft_recovery_',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      var session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      final state = ReceiptStitchDraftState(
        evidenceIds: source.activeEvidence.map((e) => e.evidenceId),
        sourceHashes: source.activeEvidence.map((e) => e.sha256),
        stage: ReceiptStitchDraftStage.processing,
      );
      workflow.updateInput(workflow.input.withStitchState(state).select(1));
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      expect(workflow.recoveryAvailable, isTrue);
      expect(workflow.input.stitchState!.toJson(), state.toJson());
      expect(workflow.input.stitchState!.needsRetry, isTrue);
      expect(workflow.input.move(0, 1).stitchState, isNull);
      expect(workflow.input.remove(0).stitchState, isNull);
      final wrongSource = ReceiptStitchDraftState(
        evidenceIds: state.evidenceIds,
        sourceHashes: List.filled(2, '0' * 64),
        stage: ReceiptStitchDraftStage.processing,
      );
      expect(
        () => workflow.updateInput(workflow.input.withStitchState(wrongSource)),
        throwsStateError,
      );
      for (final evidence in source.activeEvidence) {
        expect(await File(evidence.localPath).readAsBytes(), [1, 2, 3]);
      }
      await workflow.session.close();
      await persistence.close();
    },
  );
}
