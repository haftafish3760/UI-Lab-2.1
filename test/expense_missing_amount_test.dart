import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_projection.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_amount_summary.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_submission_coordinator.dart';
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'recurring_payment_draft_workflow_test.dart' show openSession;

void main() {
  test(
    'blank amount survives workflow confirmation, restart, correction and clearing',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'missing-expense-amount-',
      );
      var persistence = await LocalPersistence.open(directory: folder);
      addTearDown(() async {
        await persistence.close();
        await folder.delete(recursive: true);
      });
      var session = await openSession(persistence);
      final workflow = await session.expenses.openExpenseDraft(
        initial: change(initialExpense(), {
          'vendor': '',
          'category': 'uncategorized',
          'amount': '',
        }),
      );
      final record = (await workflow.confirm())!;
      await workflow.session.close();
      expect(record.amount, isNull);
      final access = ExpenseAccess.company(
        organizationId: session.expenses.organizationId,
        employeeId: 'alex',
      );
      final stored = (await persistence.expenses.findById(
        expenseId: record.id,
        access: access,
      ))!;
      expect(stored.toJson().containsKey('total'), isTrue);
      expect(stored.toJson()['total'], isNull);
      expect(
        () =>
            StoredExpenseRecord.fromJson({...stored.toJson()}..remove('total')),
        throwsFormatException,
      );
      await persistence.close();
      persistence = await LocalPersistence.open(directory: folder);
      session = await openSession(persistence);
      expect(session.expenses.records.single.amount, isNull);
      expect(
        session.expenses.projection.active.single.entersRecordedTotals,
        isFalse,
      );
      expect(
        session.expenses.projection
            .recordedTotal(const ExpenseUiProjectionQuery())
            .minorUnits,
        0,
      );
      final edit = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
        existingRecordId: record.id,
      );
      expect(edit.input.amount, '');
      edit.updateInput(
        change(edit.input, {
          'amount': '42.17',
          'correctionReason': 'Read total from receipt',
        }),
      );
      expect((await edit.confirm())!.amount, 42.17);
      await edit.session.close();
      final clear = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
        existingRecordId: record.id,
      );
      clear.updateInput(
        change(clear.input, {
          'amount': '',
          'correctionReason': 'Amount belongs to another receipt',
        }),
      );
      expect((await clear.confirm())!.amount, isNull);
      await clear.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: folder);
      final restored = (await persistence.expenses.findById(
        expenseId: record.id,
        access: access,
      ))!;
      expect(restored.total, isNull);
      expect(
        restored.priorVersions.map((version) => version.total?.minorUnits),
        [null, 4217],
      );
      expect(
        await persistence.expenses.approvedTotalMinorUnits(
          ExpenseQuery(access: access),
        ),
        0,
      );
    },
  );

  test(
    'failed confirmation keeps blank input and rolls back the record',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'missing-amount-rollback-',
      );
      final persistence = await LocalPersistence.open(directory: folder);
      addTearDown(() async {
        await persistence.close();
        await folder.delete(recursive: true);
      });
      final session = await openSession(persistence);
      final draft = await session.expenses.openExpenseDraft(
        initial: change(initialExpense(), {'amount': ''}),
      );
      await draft.session.flush();
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_blank_confirm BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      expect(await draft.confirm(), isNull);
      expect(session.expenses.records, isEmpty);
      expect(draft.input.amount, '');
      await persistence.database.customStatement(
        'DROP TRIGGER fail_blank_confirm',
      );
      expect((await draft.confirm())!.amount, isNull);
      expect(session.expenses.records, hasLength(1));
      await draft.session.close();
    },
  );

  test(
    'zero and missing amounts remain different in summaries and receipt retries',
    () {
      final missing = change(initialExpense(), {
        'amount': '',
      }).confirmedRecord();
      final zero = change(initialExpense(), {
        'amount': '0.00',
      }).confirmedRecord();
      final known = change(initialExpense(), {
        'amount': '12.34',
      }).confirmedRecord();
      expect(zero.amount, 0);
      expect(missing.amount, isNull);
      expect(receiptSubmissionMatches(missing, missing), isTrue);
      expect(receiptSubmissionMatches(missing, zero), isFalse);
      final summary = ExpenseAmountSummary([missing, zero, known]);
      expect(summary.knownMinorUnits, 1234);
      expect(summary.missingCount, 1);
      expect(summary.enteredCount, 2);
      expect(summary.displayAmount, 12.34);
      expect(ExpenseAmountSummary([missing]).displayAmount, isNull);
      expect(ExpenseAmountSummary([zero]).displayAmount, 0);
      expect(expenseMoney(missing.amount), 'Amount not entered');
      expect(expenseMoney(zero.amount), r'$0.00');
    },
  );
}
