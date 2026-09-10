import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/data/storage/staged_domain_mutation.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/atomic_receipt_submission.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/local_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  late StoredReceiptDraft receipt;
  final resolvedReferences = <String>[];
  final now = DateTime.utc(2030, 1, 2);
  final permissions = expenseUiLabOwnerPermissions();
  const checkpoint = LocalDraftCheckpoint(
    domain: 'expenses/receipt-review',
    draftId: 'input',
    revision: 1,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic-receipt-');
    resolvedReferences.clear();
    persistence = await LocalPersistence.open(
      directory: directory,
      resolveRetainedPath: (reference) {
        resolvedReferences.add(reference);
        return reference;
      },
    );
    final source = File('${directory.path}/source.jpg');
    await source.writeAsBytes([1, 3, 5, 7]);
    final controller = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(persistence.receiptDrafts),
      receiptDraftUiLabOwnerPermissions(),
    );
    await controller.load();
    receipt = (await controller.create(
      draftId: 'receipt',
      title: 'Receipt',
      expenseDate: now,
      evidence: [
        ReceiptEvidenceImport(
          sourcePath: source.path,
          originalName: 'source.jpg',
          kind: ReceiptDraftEvidenceKind.photo,
        ),
      ],
      occurredAtUtc: now,
    ))!;
    controller.dispose();
    await persistence.drafts.save(
      organizationId: permissions.organizationId,
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
      ownerId: 'alex',
      expectedRevision: 0,
      payload: {
        'vendor': 'Supplier',
        'amount': '10.',
        'receiptSourceId': 'receipt',
        'receiptSourceRevision': 1,
      },
      occurredAt: now,
    );
  });
  tearDown(() async {
    await persistence.close();
    await directory.delete(recursive: true);
  });

  test(
    'relocated evidence keeps original references and all submission checks',
    () async {
      final original = File(receipt.activeEvidence.single.localPath);
      final relocatedRoot = Directory('${directory.path}/relocated');
      final relative = original.path.split('/evidence/').last;
      final target = File('${relocatedRoot.path}/evidence/$relative');
      await target.parent.create(recursive: true);
      await original.copy(target.path);
      await original.delete();
      final repository = LocalReceiptDraftRepository.withStorage(
        DomainMutationBuffer<List<StoredReceiptDraft>>([receipt]),
        relocatedRoot,
        resolveRetainedPath: (reference) {
          expect(reference, original.path);
          return target.path;
        },
      );
      final access = receiptDraftUiLabOwnerPermissions().readAccess!;
      await repository.verifySubmissionEvidence(
        draftId: receipt.draftId,
        access: access,
        expectedRevision: 1,
      );
      expect(
        (await repository.find(
          draftId: receipt.draftId,
          access: access,
        ))!.activeEvidence.single.localPath,
        original.path,
      );
      await target.writeAsBytes([9, 9, 9, 9]);
      await expectLater(
        repository.verifySubmissionEvidence(
          draftId: receipt.draftId,
          access: access,
          expectedRevision: 1,
        ),
        throwsA(isA<ReceiptDraftStorageException>()),
      );
      final outside = LocalReceiptDraftRepository.withStorage(
        DomainMutationBuffer<List<StoredReceiptDraft>>([receipt]),
        relocatedRoot,
        resolveRetainedPath: (_) => '${directory.path}/source.jpg',
      );
      await expectLater(
        outside.verifySubmissionEvidence(
          draftId: receipt.draftId,
          access: access,
          expectedRevision: 1,
        ),
        throwsA(isA<ReceiptDraftStorageException>()),
      );
    },
  );

  Future<bool> submit({
    ReceiptDraftCommandPermissions? receiptPermissions,
    int revision = 1,
    LocalDraftCheckpoint inputCheckpoint = checkpoint,
  }) async =>
      (await AtomicReceiptSubmission(
            expenses: persistence.expenses,
            receiptDrafts: persistence.receiptDrafts,
            employeeLabelForId: expenseUiLabEmployeeLabel,
            jobLabelForId: (_) => null,
          ).submit(
            draftId: receipt.draftId,
            expectedReceiptRevision: revision,
            reviewedRecord: ExpenseRecord(
              id: 'temporary',
              vendor: 'Supplier',
              category: ExpenseCategory.office,
              amount: 10,
              date: now,
              owner: 'Alex Morgan',
              paidByEmployeeId: 'alex',
              receiptImageCount: 1,
            ),
            paidByEmployeeId: 'alex',
            expensePermissions: permissions,
            receiptPermissions:
                receiptPermissions ?? receiptDraftUiLabOwnerPermissions(),
            occurredAtUtc: now,
            draftCheckpoint: inputCheckpoint,
          ))
          .succeeded;

  test(
    'restored installation submits relocated receipt without changing original database',
    () async {
      final snapshot = await LocalSnapshotBundle.capture(persistence.database);
      final prepared = await PreparedLocalRestore.prepare(
        source: await VerifiedLocalSnapshotBundle.open(snapshot.directory),
        liveDatabaseFile: persistence.database.storageFile!,
      );
      await persistence.close();
      // The original evidence is deliberately unavailable to the restored flow.
      await File(receipt.activeEvidence.single.localPath).delete();
      final reopened = await PreparedLocalRestore.reopen(prepared.directory);
      persistence = await LocalPersistence.open(
        directory: reopened.directory,
        resolveRetainedPath: reopened.resolveRetainedPath,
      );
      expect(await submit(), isTrue);
      await persistence.close();
      final again = await PreparedLocalRestore.reopen(prepared.directory);
      persistence = await LocalPersistence.open(
        directory: again.directory,
        resolveRetainedPath: again.resolveRetainedPath,
      );
      final beforeReplay =
          (await persistence.database
                  .select(persistence.database.localCommands)
                  .get())
              .length;
      expect(await submit(), isTrue);
      expect(
        (await persistence.database
                .select(persistence.database.localCommands)
                .get())
            .length,
        beforeReplay,
      );
      final nextSnapshot = await again.captureCheckpoint(persistence.database);
      final nextPrepared = await PreparedLocalRestore.prepare(
        source: await VerifiedLocalSnapshotBundle.open(nextSnapshot.directory),
        liveDatabaseFile: persistence.database.storageFile!,
      );
      expect(
        await File(
          nextPrepared.resolveRetainedPath(
            receipt.activeEvidence.single.localPath,
          ),
        ).readAsBytes(),
        [1, 3, 5, 7],
      );
      final original = await LocalPersistence.open(directory: directory);
      try {
        final retained = await original.receiptDrafts.find(
          draftId: receipt.draftId,
          access: receiptDraftUiLabOwnerPermissions().readAccess!,
        );
        expect(retained, isNotNull);
        expect(
          await original.drafts.find(
            organizationId: permissions.organizationId,
            domain: checkpoint.domain,
            draftId: checkpoint.draftId,
            ownerId: 'alex',
          ),
          isNotNull,
        );
        await original.database.verifyIntegrity();
      } finally {
        await original.close();
      }
    },
  );

  test('startup resolver reaches the atomic staged submission', () async {
    expect(await submit(), isTrue);
    expect(
      resolvedReferences,
      contains(receipt.activeEvidence.single.localPath),
    );
  });

  Future<void> expectUnconfirmed() async {
    expect(
      await persistence.expenses.query(
        ExpenseQuery(access: permissions.readAccess!),
      ),
      isEmpty,
    );
    final stored = await persistence.receiptDrafts.find(
      draftId: receipt.draftId,
      access: ReceiptDraftAccess.company(
        organizationId: permissions.organizationId,
        employeeId: 'alex',
      ),
      includeClosed: true,
    );
    expect(stored!.state, ReceiptDraftState.inProgress);
    expect(stored.lifecycle.revision, 1);
    expect(
      await persistence.drafts.list(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        ownerId: 'alex',
      ),
      hasLength(1),
    );
    expect(
      await persistence.database
          .select(persistence.database.localRecords)
          .get(),
      hasLength(1),
    );
  }

  test(
    'receipt closure failure rolls back expense and both live repositories; retry consumes draft',
    () async {
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_receipt_close BEFORE UPDATE ON local_records WHEN NEW.domain = 'receipt-drafts/records' BEGIN SELECT RAISE(ABORT, 'injected receipt close failure'); END",
      );
      expect(await submit(), isFalse);
      await expectUnconfirmed();
      await persistence.database.customStatement(
        'DROP TRIGGER fail_receipt_close',
      );
      expect(await submit(), isTrue);
      final expense = (await persistence.expenses.query(
        ExpenseQuery(access: permissions.readAccess!),
      )).single;
      expect(expense.expenseId, 'EXP-RECEIPT-receipt');
      expect(expense.receiptImageCount, 1);
      await persistence.close();
      resolvedReferences.clear();
      persistence = await LocalPersistence.open(
        directory: directory,
        resolveRetainedPath: (reference) {
          resolvedReferences.add(reference);
          return reference;
        },
      );
      final stored = await persistence.receiptDrafts.find(
        draftId: receipt.draftId,
        access: ReceiptDraftAccess.company(
          organizationId: permissions.organizationId,
          employeeId: 'alex',
        ),
        includeClosed: true,
      );
      final commandCount =
          (await persistence.database
                  .select(persistence.database.localCommands)
                  .get())
              .length;
      expect(await submit(), isTrue);
      expect(
        (await persistence.database
                .select(persistence.database.localCommands)
                .get())
            .length,
        commandCount,
      );
      expect(stored!.state, ReceiptDraftState.submitted);
      expect(stored.submittedExpenseId, expense.expenseId);
      expect(stored.lifecycle.revision, 2);
      expect(
        stored.activeEvidence.single.sha256,
        receipt.activeEvidence.single.sha256,
      );
      expect(
        (await persistence.expenses.query(
          ExpenseQuery(access: permissions.readAccess!),
        )).single.toJson(),
        expense.toJson(),
      );
      expect(
        await persistence.drafts.list(
          organizationId: permissions.organizationId,
          domain: checkpoint.domain,
          ownerId: 'alex',
        ),
        isEmpty,
      );
    },
  );

  test(
    'denied receipt submission and stale review do not publish staged expense',
    () async {
      expect(
        await submit(
          receiptPermissions: ReceiptDraftCommandPermissions(
            organizationId: permissions.organizationId,
            actorEmployeeId: 'alex',
            permissionRevision: 'denied',
            readScope: ReceiptDraftReadScope.company,
          ),
        ),
        isFalse,
      );
      await expectUnconfirmed();
      expect(await submit(revision: 2), isFalse);
      await expectUnconfirmed();
    },
  );

  test(
    'unrelated retained review cannot be consumed by receipt confirmation',
    () async {
      await persistence.drafts.save(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        draftId: checkpoint.draftId,
        ownerId: 'alex',
        expectedRevision: 1,
        payload: {
          'receiptSourceId': 'different-receipt',
          'receiptSourceRevision': 1,
          'amount': '10.',
        },
        occurredAt: now,
      );
      expect(
        await submit(
          inputCheckpoint: LocalDraftCheckpoint(
            domain: checkpoint.domain,
            draftId: checkpoint.draftId,
            revision: 2,
          ),
        ),
        isFalse,
      );
      await expectUnconfirmed();
      final retained = (await persistence.drafts.list(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        ownerId: 'alex',
      )).single;
      expect(retained.revision, 2);
      expect(
        persistence.drafts.decode(retained)['receiptSourceId'],
        'different-receipt',
      );
    },
  );

  for (final damage in ['missing', 'same-length corruption', 'truncated']) {
    test(
      'confirmation preserves input when retained evidence is $damage',
      () async {
        final file = File(receipt.activeEvidence.single.localPath);
        final original = await file.readAsBytes();
        if (damage == 'missing') {
          await file.delete();
        } else {
          await file.writeAsBytes(
            damage == 'truncated' ? [1] : [7, 5, 3, 1],
            flush: true,
          );
        }
        expect(await submit(), isFalse);
        await expectUnconfirmed();
        await persistence.close();
        resolvedReferences.clear();
        persistence = await LocalPersistence.open(
          directory: directory,
          resolveRetainedPath: (reference) {
            resolvedReferences.add(reference);
            return reference;
          },
        );
        expect(await submit(), isFalse);
        await expectUnconfirmed();
        await file.writeAsBytes(original, flush: true);
        expect(await submit(), isTrue);
      },
    );
  }

  test(
    'matching bytes outside the retained folder cannot replace evidence through a link',
    () async {
      final file = File(receipt.activeEvidence.single.localPath);
      final original = await file.readAsBytes();
      final outside = File('${directory.path}/outside.jpg');
      await outside.writeAsBytes(original, flush: true);
      await file.delete();
      final link = await Link(file.path).create(outside.path);
      expect(await submit(), isFalse);
      await expectUnconfirmed();
      await link.delete();
      await file.writeAsBytes(original, flush: true);
      expect(await submit(), isTrue);
    },
  );

  test('submission staging refuses evidence mutations', () async {
    await expectLater(
      persistence.receiptDrafts.withStagedSubmission(
        (stage) => stage.repository.update(
          draft: receipt,
          addedEvidence: const [],
          expectedRevision: 1,
          context: ReceiptDraftMutationContext(
            actorEmployeeId: 'alex',
            occurredAtUtc: now,
            permissionRevision: 'test',
          ),
        ),
      ),
      throwsA(isA<ReceiptDraftStorageException>()),
    );
    await expectUnconfirmed();
  });
}
