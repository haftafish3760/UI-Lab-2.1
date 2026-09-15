import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_seed.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_seed.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_seed.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  final access = ExpenseAccess.company(
    organizationId: expenseUiLabOrganizationId,
    employeeId: 'alex',
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'maintainiac-domain-sqlite-',
    );
    persistence = await LocalPersistence.open(directory: directory);
  });
  tearDown(() async {
    await persistence.close();
    await directory.delete(recursive: true);
  });

  test(
    'existing domain fixtures persist as individual SQL rows and reconcile on reopen',
    () async {
      await seedExpenseUiLabDemoDataIfEmpty(persistence.expenses);
      await seedRecurringExpenseUiLabDemoDataIfEmpty(
        persistence.recurringExpenses,
      );
      await seedReceiptDraftUiLabDemoDataIfEmpty(persistence.receiptDrafts);
      final before = await persistence.database
          .select(persistence.database.localRecords)
          .get();
      expect(
        before.map((row) => row.domain).toSet(),
        containsAll([
          'expenses/records',
          'recurring-expenses/templates',
          'recurring-expenses/occurrences',
          'receipt-drafts/records',
        ]),
      );
      final expenseBefore = await persistence.expenses.query(
        ExpenseQuery(access: access),
      );
      final totals = expenseBefore.fold(
        0,
        (sum, row) => sum + (row.total?.minorUnits ?? 0),
      );
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final expenseAfter = await persistence.expenses.query(
        ExpenseQuery(access: access),
      );
      expect(
        expenseAfter.map((r) => r.expenseId).toSet(),
        expenseBefore.map((r) => r.expenseId).toSet(),
      );
      expect(
        expenseAfter.fold(0, (sum, row) => sum + (row.total?.minorUnits ?? 0)),
        totals,
      );
      final after = await persistence.database
          .select(persistence.database.localRecords)
          .get();
      expect(
        {for (final r in after) '${r.domain}:${r.recordId}': r.payload},
        {for (final r in before) '${r.domain}:${r.recordId}': r.payload},
      );
      await persistence.database.verifyIntegrity();
    },
  );

  test(
    'failed SQLite update preserves last-known-good repository and database',
    () async {
      await seedExpenseUiLabDemoDataIfEmpty(persistence.expenses);
      final record = (await persistence.expenses.query(
        ExpenseQuery(access: access),
      )).first;
      final original = record.toJson();
      await persistence.database.customStatement('''
      CREATE TRIGGER fail_revision BEFORE INSERT ON local_record_revisions
      BEGIN SELECT RAISE(ABORT, 'synthetic write failure'); END
    ''');
      await expectLater(
        persistence.expenses.softDelete(
          expenseId: record.expenseId,
          expectedRevision: record.lifecycle.revision,
          context: ExpenseMutationContext(
            actorEmployeeId: 'alex',
            occurredAtUtc: DateTime.now().toUtc(),
            permissionRevision: 'test',
          ),
        ),
        throwsA(isA<ExpenseStorageException>()),
      );
      expect(
        (await persistence.expenses.findById(
          expenseId: record.expenseId,
          access: access,
        ))!.toJson(),
        original,
      );
      await persistence.database.customStatement('DROP TRIGGER fail_revision');
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      expect(
        (await persistence.expenses.findById(
          expenseId: record.expenseId,
          access: access,
        ))!.toJson(),
        original,
      );
    },
  );

  test(
    'soft removal and restore retain exact record history across restart',
    () async {
      await seedExpenseUiLabDemoDataIfEmpty(persistence.expenses);
      final record = (await persistence.expenses.query(
        ExpenseQuery(access: access),
      )).first;
      final context = ExpenseMutationContext(
        actorEmployeeId: 'alex',
        occurredAtUtc: DateTime.now().toUtc(),
        permissionRevision: 'test',
      );
      final deleted = await persistence.expenses.softDelete(
        expenseId: record.expenseId,
        expectedRevision: record.lifecycle.revision,
        context: context,
      );
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      expect(
        await persistence.expenses.findById(
          expenseId: record.expenseId,
          access: access,
        ),
        isNull,
      );
      final restored = await persistence.expenses.restore(
        expenseId: record.expenseId,
        expectedRevision: deleted.lifecycle.revision,
        context: context,
      );
      expect(restored.total, record.total);
      expect(restored.lifecycle.revision, record.lifecycle.revision + 2);
      final revisions = await persistence.database
          .customSelect(
            "SELECT COUNT(*) AS n FROM local_record_revisions WHERE domain = 'expenses/records' AND record_id = ?",
            variables: [Variable(record.expenseId)],
          )
          .get();
      expect(revisions.single.read<int>('n'), 3);
    },
  );
}
