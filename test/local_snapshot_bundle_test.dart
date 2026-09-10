import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  late ReceiptDraftUiController receipts;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('snapshot-bundle-');
    persistence = await LocalPersistence.open(directory: directory);
    receipts = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(persistence.receiptDrafts),
      receiptDraftUiLabOwnerPermissions(),
    );
    await receipts.load();
  });
  tearDown(() async {
    receipts.dispose();
    await persistence.close();
    await directory.delete(recursive: true);
  });

  Future<File> retainPhoto() async {
    final source = File('${directory.path}/picker.jpg');
    await source.writeAsBytes([1, 3, 5, 7], flush: true);
    return LocalAttachmentStore(
      persistence.database,
    ).retain(source: source, organizationId: 'business', ownerId: 'alex');
  }

  test(
    'bundle retains registered photos and receipt bytes independently of live files',
    () async {
      final photo = await retainPhoto();
      final source = File('${directory.path}/receipt.pdf');
      await source.writeAsBytes([2, 4, 6], flush: true);
      final receipt = (await receipts.create(
        draftId: 'receipt',
        title: 'Receipt',
        expenseDate: DateTime.utc(2030, 1, 2),
        evidence: [
          ReceiptEvidenceImport(
            sourcePath: source.path,
            originalName: 'receipt.pdf',
            kind: ReceiptDraftEvidenceKind.pdf,
          ),
        ],
        occurredAtUtc: DateTime.utc(2030, 1, 2),
      ))!;
      final removed = await receipts.update(
        draftId: receipt.draftId,
        title: receipt.title,
        expenseDate: receipt.expenseDate,
        retainedEvidenceIds: [],
        addedEvidence: [],
        occurredAtUtc: DateTime.utc(2030, 1, 3),
      );
      expect(removed!.activeEvidence, isEmpty);
      expect(removed.evidence, hasLength(1));
      final bundle = await LocalSnapshotBundle.capture(persistence.database);
      expect(bundle.attachments, hasLength(2));
      final manifest =
          jsonDecode(
                await File(
                  '${bundle.directory.path}/manifest.json',
                ).readAsString(),
              )
              as Map;
      expect(manifest['attachments'], hasLength(2));
      await photo.delete();
      await File(receipt.activeEvidence.single.localPath).delete();
      for (final entry in bundle.attachments) {
        final file = File(
          '${bundle.directory.path}/files/${entry.relativePath}',
        );
        expect(
          await file.readAsBytes(),
          entry.relativePath.startsWith('attachments/')
              ? [1, 3, 5, 7]
              : [2, 4, 6],
        );
      }
      expect(await bundle.database.file.exists(), isTrue);
    },
  );

  for (final failure in ['missing', 'changed', 'symlink']) {
    test(
      '$failure retained file fails capture without publishing a partial bundle',
      () async {
        final photo = await retainPhoto();
        final prior = await LocalSnapshotBundle.capture(persistence.database);
        final previousManifest = await File(
          '${prior.directory.path}/manifest.json',
        ).readAsBytes();
        if (failure == 'changed') {
          await photo.writeAsBytes([7, 5, 3, 1], flush: true);
        } else {
          await photo.delete();
          if (failure == 'symlink') {
            // Even matching bytes outside the registered location are rejected.
            await Link(photo.path).create('${directory.path}/picker.jpg');
          }
        }
        await expectLater(
          LocalSnapshotBundle.capture(persistence.database),
          throwsA(anything),
        );
        expect(
          await File('${prior.directory.path}/manifest.json').readAsBytes(),
          previousManifest,
        );
        expect(
          (await prior.directory.parent.list().toList()).map((e) => e.path),
          [prior.directory.path],
        );
        await persistence.database.verifyIntegrity();
      },
    );
  }
}
