import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession;

ExpenseDraftInput initialExpense() => ExpenseDraftInput(
  expenseId: 'preview-id',
  receiptSourceId: null,
  receiptSourceRevision: null,
  receiptImageCount: 0,
  baseRecord: null,
  baseRevision: null,
  pendingLine: null,
  ownerId: 'alex',
  ownerLabel: 'Alex Morgan',
  jobId: null,
  date: DateTime(2030, 1, 2),
  category: ExpenseCategory.office,
  receiptType: ExpenseReceiptType.basic,
  prepareMaterialsReview: false,
  correctionReason: '',
  vendor: 'Supplier',
  amount: '12.',
  subtotal: '',
  salesTax: '',
  job: '',
  lines: const [],
);
ExpenseDraftInput change(
  ExpenseDraftInput input,
  Map<String, Object?> fields,
) => ExpenseDraftInput.fromPayload({...input.toPayload(), ...fields});

void main() {
  test(
    'workflow validation rejects malformed optional amounts and preserves raw input',
    () {
      final initial = initialExpense();
      for (final fields in [
        <String, Object?>{'amount': '12.'},
        <String, Object?>{'amount': '12.50', 'subtotal': 'wrong'},
        <String, Object?>{'amount': '12.50', 'salesTax': '0.001'},
        <String, Object?>{'amount': '9' * 400},
      ]) {
        final input = change(initial, fields);
        expect(input.confirmedRecord, throwsStateError);
        for (final field in fields.entries) {
          expect(input.toPayload()[field.key], field.value);
        }
      }
    },
  );
  test(
    'manual workflow reopens exact raw input and confirms atomically once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'expense-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openSession(persistence);
      var workflow = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
      );
      workflow.updateInput(change(workflow.input, {'amount': '-'}));
      final identity = workflow.input.expenseId;
      final draftId = workflow.session.draftId;
      expect(identity, isNot('preview-id'));
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openSession(persistence);
      expect(
        (await session.expenses.manualDraftRecovery.list()).single.label,
        'Supplier',
      );
      workflow = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
        recoveryDraftId: draftId,
      );
      expect(workflow.input.amount, '-');
      expect(workflow.input.expenseId, identity);
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateInput(change(workflow.input, {'amount': '12.50'}));
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_expense_confirm BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(session.expenses.records, isEmpty);
      expect(workflow.session.input['amount'], '12.50');
      await persistence.database.customStatement(
        'DROP TRIGGER fail_expense_confirm',
      );
      final saved = await workflow.confirm();
      expect(saved!.id, identity);
      expect(saved.amount, 12.5);
      expect(session.expenses.records, hasLength(1));
      expect(await session.expenses.manualDraftRecovery.list(), isEmpty);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );

  test(
    'recovered correction retains its base and refuses a newer record',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'expense-edit-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openSession(persistence);
      final create = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
      );
      create.updateInput(change(create.input, {'amount': '12.50'}));
      final record = (await create.confirm())!;
      await create.session.close();
      var edit = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
        existingRecordId: record.id,
      );
      edit.updateInput(
        change(edit.input, {
          'vendor': 'Draft correction',
          'correctionReason': 'Correct supplier',
        }),
      );
      await edit.session.close();
      expect(
        await session.expenses.update(
          record: record.copyWith(vendor: 'Newer record'),
          occurredAtUtc: DateTime.now().toUtc(),
          expectedRevision: 1,
          auditNote: 'Another correction',
        ),
        isNotNull,
      );
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openSession(persistence);
      edit = await session.expenses.openExpenseDraft(
        initial: initialExpense(),
        existingRecordId: record.id,
      );
      expect(edit.input.baseRevision, 1);
      expect(edit.input.baseRecord!.vendor, 'Supplier');
      expect(edit.input.vendor, 'Draft correction');
      expect(await edit.confirm(), isNull);
      expect(session.expenses.records.single.vendor, 'Newer record');
      expect(edit.session.input['correctionReason'], 'Correct supplier');
      await edit.session.close();
    },
  );
}
