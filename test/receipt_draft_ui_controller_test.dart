import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'ui-lab-receipt-draft-controller-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('selected evidence and stable draft identity survive restart', () async {
    final source = File('${directory.path}/source.jpg');
    await source.writeAsBytes([1, 3, 5, 7]);
    var repository = await FileReceiptDraftRepository.open(
      Directory('${directory.path}/drafts'),
    );
    var controller = _controller(repository);
    addTearDown(controller.dispose);
    expect(await controller.load(), isTrue);

    final created = await controller.create(
      draftId: 'draft-stable-1',
      title: 'Supply receipt',
      expenseDate: DateTime(2026, 9, 1),
      evidence: [
        ReceiptEvidenceImport(
          sourcePath: source.path,
          originalName: 'source.jpg',
          kind: ReceiptDraftEvidenceKind.photo,
        ),
      ],
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );

    expect(created?.draftId, 'draft-stable-1');
    expect(created?.activeEvidence.single.originalName, 'source.jpg');
    expect(created?.activeEvidence.single.localPath, isNot(source.path));
    expect(
      await File(created!.activeEvidence.single.localPath).exists(),
      isTrue,
    );

    repository = await FileReceiptDraftRepository.open(
      Directory('${directory.path}/drafts'),
    );
    controller = _controller(repository);
    addTearDown(controller.dispose);
    expect(await controller.load(), isTrue);
    expect(controller.records.single.draftId, 'draft-stable-1');
    expect(controller.records.single.activeEvidence, hasLength(1));
  });

  test(
    'failed update keeps last known-good draft and reports storage',
    () async {
      var writeCount = 0;
      final repository = await FileReceiptDraftRepository.open(
        Directory('${directory.path}/drafts'),
        snapshotWriter: (target, bytes) async {
          writeCount += 1;
          if (writeCount == 2) {
            throw const FileSystemException('Simulated storage pressure');
          }
          await target.writeAsBytes(bytes, flush: true);
        },
      );
      final controller = _controller(repository);
      addTearDown(controller.dispose);
      await controller.load();
      final created = await controller.create(
        draftId: 'draft-last-good',
        title: 'Original title',
        expenseDate: DateTime(2026, 9, 1),
        evidence: const [],
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      expect(created, isNotNull);

      final failed = await controller.update(
        draftId: created!.draftId,
        title: 'Unsaved title',
        expenseDate: created.expenseDate,
        retainedEvidenceIds: const [],
        addedEvidence: const [],
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      );

      expect(failed, isNull);
      expect(controller.failure?.kind, ReceiptDraftUiFailureKind.storage);
      expect(controller.records.single.title, 'Original title');
      final reopened = _controller(
        await FileReceiptDraftRepository.open(
          Directory('${directory.path}/drafts'),
        ),
      );
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.records.single.title, 'Original title');
    },
  );

  test(
    'reviewed evidence order survives controller update and restart',
    () async {
      final first = File('${directory.path}/first.jpg');
      final second = File('${directory.path}/second.jpg');
      await first.writeAsBytes([1, 2, 3]);
      await second.writeAsBytes([4, 5, 6]);
      var repository = await FileReceiptDraftRepository.open(
        Directory('${directory.path}/drafts'),
      );
      var controller = _controller(repository);
      addTearDown(controller.dispose);
      await controller.load();
      final created = await controller.create(
        draftId: 'draft-ordered-evidence',
        title: 'Ordered receipt',
        expenseDate: DateTime(2026, 9, 1),
        evidence: [
          ReceiptEvidenceImport(
            sourcePath: first.path,
            originalName: 'first.jpg',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
          ReceiptEvidenceImport(
            sourcePath: second.path,
            originalName: 'second.jpg',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
        ],
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      final reversedIds = created!.activeEvidence.reversed
          .map((item) => item.evidenceId)
          .toList();

      final updated = await controller.update(
        draftId: created.draftId,
        title: created.title,
        expenseDate: created.expenseDate,
        retainedEvidenceIds: reversedIds,
        addedEvidence: const [],
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      );

      expect(updated!.activeEvidence.map((item) => item.originalName), [
        'second.jpg',
        'first.jpg',
      ]);
      expect(updated.activeEvidence.map((item) => item.order), [0, 1]);

      repository = await FileReceiptDraftRepository.open(
        Directory('${directory.path}/drafts'),
      );
      controller = _controller(repository);
      addTearDown(controller.dispose);
      await controller.load();
      expect(
        controller.records.single.activeEvidence.map(
          (item) => item.originalName,
        ),
        ['second.jpg', 'first.jpg'],
      );
    },
  );

  test('read denial exposes no draft metadata', () async {
    final repository = await FileReceiptDraftRepository.open(
      Directory('${directory.path}/drafts'),
    );
    final controller = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(repository),
      ReceiptDraftCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'alex',
        permissionRevision: 'permissions-1',
        readScope: null,
      ),
    );
    addTearDown(controller.dispose);

    expect(await controller.load(), isFalse);
    expect(controller.records, isEmpty);
    expect(controller.failure?.kind, ReceiptDraftUiFailureKind.permission);
  });
}

ReceiptDraftUiController _controller(ReceiptDraftRepository repository) =>
    ReceiptDraftUiController(
      AuthorizedReceiptDraftService(repository),
      ReceiptDraftCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'alex',
        permissionRevision: 'permissions-1',
        readScope: ReceiptDraftReadScope.company,
        canCreate: true,
        canEditOwn: true,
        canEditTeam: true,
        canSubmitOwn: true,
        canSubmitTeam: true,
        canDiscardOwn: true,
        canDiscardTeam: true,
      ),
    );
