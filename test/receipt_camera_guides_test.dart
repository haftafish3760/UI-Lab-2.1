import 'dart:io';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_camera_guides.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory folder;
  late LocalPersistence persistence;
  late ReceiptDraftUiController controller;
  late StoredReceiptDraft receipt;
  late LocalMediaPickerRequest request;
  late ReceiptCameraGuideResolver resolver;
  final permissions = receiptDraftUiLabOwnerPermissions();
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('receipt_guide_');
    persistence = await LocalPersistence.open(directory: folder);
    controller = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(persistence.receiptDrafts),
      permissions,
    );
    await controller.load();
    final first = File('${folder.path}${Platform.pathSeparator}one.jpg');
    final last = File('${folder.path}${Platform.pathSeparator}two.jpg');
    await first.writeAsBytes([1, 3, 5]);
    await last.writeAsBytes([2, 4, 6, 8]);
    receipt = (await controller.create(
      draftId: 'long-receipt',
      title: 'Long receipt',
      expenseDate: DateTime(2026, 9, 19),
      evidence: [
        ReceiptEvidenceImport(
          sourcePath: first.path,
          originalName: 'one.jpg',
          kind: ReceiptDraftEvidenceKind.photo,
        ),
        ReceiptEvidenceImport(
          sourcePath: last.path,
          originalName: 'two.jpg',
          kind: ReceiptDraftEvidenceKind.photo,
        ),
      ],
      occurredAtUtc: DateTime.utc(2026, 9, 19),
    ))!;
    request = await LocalMediaPickerRequestStore(persistence.database).begin(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      destination: MediaPickerDestination.receipt,
      targetId: receipt.draftId,
      targetRevision: receipt.lifecycle.revision,
      source: MediaPickerSource.camera,
    );
    resolver = ReceiptCameraGuideResolver(
      persistence.receiptDrafts,
      permissions,
    );
  });
  tearDown(() async {
    controller.dispose();
    await persistence.close();
  });

  test(
    'append guide uses last retained photo and survives SQLite reopen',
    () async {
      await persistence.close();
      persistence = await LocalPersistence.open(directory: folder);
      resolver = ReceiptCameraGuideResolver(
        persistence.receiptDrafts,
        permissions,
      );
      final savedRequest =
          (await LocalMediaPickerRequestStore(persistence.database).findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          ))!;
      final result = await resolver.forAppend(savedRequest);
      final guide = result['previousGuide'] as Map;
      expect(await File(guide['path'] as String).readAsBytes(), [2, 4, 6, 8]);
      expect(guide['length'], 4);
      expect(result.containsKey('nextGuide'), isFalse);
    },
  );

  test('tampered reference cannot become ghost guide', () async {
    await File(
      receipt.activeEvidence.last.localPath,
    ).writeAsBytes([8, 6, 4, 2]);
    await expectLater(resolver.forAppend(request), throwsStateError);
  });

  test('changed receipt revision cannot silently select a new guide', () async {
    await AuthorizedReceiptDraftService(persistence.receiptDrafts).update(
      draft: receipt.copyWith(title: 'Changed after camera request'),
      addedEvidence: [],
      expectedRevision: receipt.lifecycle.revision,
      permissions: permissions,
      occurredAtUtc: DateTime.utc(2026, 9, 20),
    );
    await expectLater(resolver.forAppend(request), throwsStateError);
  });

  test('another owner cannot resolve the saved photo request', () async {
    final other = ReceiptCameraGuideResolver(
      persistence.receiptDrafts,
      ReceiptDraftCommandPermissions(
        organizationId: permissions.organizationId,
        actorEmployeeId: 'different-owner',
        permissionRevision: 'one',
        readScope: ReceiptDraftReadScope.company,
        canEditTeam: true,
      ),
    );
    await expectLater(other.forAppend(request), throwsStateError);
  });
}
