import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/local_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  final permissions = expenseUiLabOwnerPermissions();
  final now = DateTime.utc(2030, 1, 2);
  const checkpoint = LocalDraftCheckpoint(
    domain: 'expenses/manual-entry',
    draftId: 'draft-expense',
    revision: 1,
  );
  StoredExpenseRecord input() => StoredExpenseRecord(
    expenseId: 'expense-test',
    organizationId: permissions.organizationId,
    createdByEmployeeId: permissions.actorEmployeeId,
    paidByEmployeeId: permissions.actorEmployeeId,
    expenseDate: now,
    vendorName: 'Supplier',
    categoryId: 'materials',
    categoryLabelSnapshot: 'Materials',
    total: ExpenseMoney(minorUnits: 1250, currencyCode: 'USD'),
    approval: const ExpenseApproval(state: ExpenseApprovalState.notRequired),
    lifecycle: ExpenseLifecycle(
      revision: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    ),
  );

  Future<void> draft({String owner = 'alex', int expected = 0}) async {
    await persistence.drafts.save(
      organizationId: permissions.organizationId,
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
      ownerId: owner,
      expectedRevision: expected,
      payload: {
        'vendor': 'Supplier',
        'amount': expected == 0 ? '12.' : '12.50',
      },
      occurredAt: now,
    );
  }

  Future<StoredExpenseRecord> confirm() =>
      AuthorizedExpenseService(persistence.expenses).create(
        record: input(),
        permissions: permissions,
        occurredAtUtc: now,
        draftCheckpoint: checkpoint,
      );

  Future<void> expectUnconfirmed({
    String owner = 'alex',
    int revision = 1,
  }) async {
    expect(
      await persistence.expenses.query(
        ExpenseQuery(access: permissions.readAccess!),
      ),
      isEmpty,
    );
    final row = await persistence.drafts.find(
      organizationId: permissions.organizationId,
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
      ownerId: owner,
    );
    expect(row?.revision, revision);
    expect(
      await persistence.database
          .select(persistence.database.localRecords)
          .get(),
      isEmpty,
    );
    expect(
      await persistence.database
          .select(persistence.database.localRecordRevisions)
          .get(),
      isEmpty,
    );
    expect(
      await persistence.database
          .select(persistence.database.localCommands)
          .get(),
      isEmpty,
    );
    expect(
      await persistence.database
          .select(persistence.database.localChangeOutbox)
          .get(),
      isEmpty,
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expense-draft-atomic-');
    persistence = await LocalPersistence.open(directory: directory);
  });
  tearDown(() async {
    await persistence.close();
    await directory.delete(recursive: true);
  });

  test(
    'failed draft deletion rolls back expense, history and caches; retry commits',
    () async {
      await draft();
      await persistence.database.customStatement('''
      CREATE TRIGGER fail_draft_consume BEFORE DELETE ON local_drafts
      BEGIN SELECT RAISE(ABORT, 'injected draft deletion failure'); END
    ''');
      await expectLater(confirm(), throwsA(isA<ExpenseStorageException>()));
      await expectUnconfirmed();
      await persistence.database.customStatement(
        'DROP TRIGGER fail_draft_consume',
      );
      final created = await confirm();
      expect(created.lifecycle.revision, 1);
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final records = await persistence.expenses.query(
        ExpenseQuery(access: permissions.readAccess!),
      );
      expect(records.single.toJson(), created.toJson());
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
    'newer input prevents confirmation without publishing record changes',
    () async {
      await draft();
      await draft(expected: 1);
      await expectLater(confirm(), throwsA(isA<ExpenseStorageException>()));
      await expectUnconfirmed(revision: 2);
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      await expectUnconfirmed(revision: 2);
    },
  );

  test(
    'company-wide expense permissions do not consume another actor draft',
    () async {
      await draft(owner: 'jordan');
      await expectLater(confirm(), throwsA(isA<ExpenseStorageException>()));
      await expectUnconfirmed(owner: 'jordan');
    },
  );

  test(
    'legacy storage rejects atomic confirmation before writing an expense',
    () async {
      final legacy = await LocalExpenseRepository.open(
        Directory('${directory.path}/legacy'),
      );
      await expectLater(
        AuthorizedExpenseService(legacy).create(
          record: input(),
          permissions: permissions,
          occurredAtUtc: now,
          draftCheckpoint: checkpoint,
        ),
        throwsA(isA<ExpenseStorageException>()),
      );
      expect(
        await legacy.query(ExpenseQuery(access: permissions.readAccess!)),
        isEmpty,
      );
    },
  );

  test(
    'controller keeps committed projection on failure and rejects old edit bases',
    () async {
      await AuthorizedExpenseService(
        persistence.expenses,
      ).create(record: input(), permissions: permissions, occurredAtUtc: now);
      final controller = ExpenseUiRepositoryController(
        ExpenseUiRepositoryBridge(
          service: AuthorizedExpenseService(persistence.expenses),
          employeeLabelForId: expenseUiLabEmployeeLabel,
          jobLabelForId: (_) => null,
        ),
        permissions,
      );
      addTearDown(controller.dispose);
      expect(await controller.load(), isTrue);
      final initial = controller.records.single;
      await draft();
      expect(
        await controller.update(
          record: initial.copyWith(vendor: 'Missing edit base'),
          occurredAtUtc: now,
          draftCheckpoint: checkpoint,
        ),
        isNull,
      );
      expect(controller.failure?.kind, ExpenseUiBridgeFailureKind.conflict);
      expect(controller.revisionForId(initial.id), 1);
      await persistence.database.customStatement('''
      CREATE TRIGGER fail_expense_edit BEFORE DELETE ON local_drafts
      BEGIN SELECT RAISE(ABORT, 'injected confirmation failure'); END
    ''');
      expect(
        await controller.update(
          record: initial.copyWith(vendor: 'Updated supplier'),
          occurredAtUtc: now,
          expectedRevision: 1,
          draftCheckpoint: checkpoint,
        ),
        isNull,
      );
      expect(controller.records.single.vendor, initial.vendor);
      expect(controller.revisionForId(initial.id), 1);
      await persistence.database.customStatement(
        'DROP TRIGGER fail_expense_edit',
      );
      expect(
        await controller.update(
          record: initial.copyWith(vendor: 'Updated supplier'),
          occurredAtUtc: now,
          expectedRevision: 1,
          draftCheckpoint: checkpoint,
        ),
        isNotNull,
      );
      expect(controller.revisionForId(initial.id), 2);
      await draft();
      expect(
        await controller.update(
          record: initial.copyWith(vendor: 'Stale supplier'),
          occurredAtUtc: now,
          expectedRevision: 1,
          draftCheckpoint: checkpoint,
        ),
        isNull,
      );
      expect(controller.failure?.kind, ExpenseUiBridgeFailureKind.conflict);
      expect(controller.records.single.vendor, 'Updated supplier');
      expect(controller.revisionForId(initial.id), 2);
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final saved = (await persistence.expenses.query(
        ExpenseQuery(access: permissions.readAccess!),
      )).single;
      expect(saved.vendorName, 'Updated supplier');
      expect(saved.lifecycle.revision, 2);
      expect(saved.priorVersions, hasLength(1));
      expect(
        await persistence.drafts.list(
          organizationId: permissions.organizationId,
          domain: checkpoint.domain,
          ownerId: permissions.actorEmployeeId,
        ),
        hasLength(1),
      );
    },
  );
}
