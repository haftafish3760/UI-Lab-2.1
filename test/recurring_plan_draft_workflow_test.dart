import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession, seed;

void main() {
  test(
    'new planned expense recovers raw input and reminders then confirms once after rollback',
    () async {
      final directory = await Directory.systemTemp.createTemp('plan-workflow-');
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openSession(persistence);
      var workflow = await session.recurringExpenses.openPlannedDraft();
      final id = workflow.input.recordId;
      final draftId = workflow.session.draftId;
      final raw = workflow.input.toPayload()
        ..['title'] = '  Insurance  '
        ..['amount'] = '-'
        ..['reminders'] = [1, 7]
        ..['push'] = false
        ..['sound'] = false;
      workflow.updateInput(RecurringPlanDraftInput.fromPayload(raw));
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openSession(persistence);
      final choices = await session.recurringExpenses.plannedDraftRecovery
          .list();
      expect(choices.single.draftId, draftId);
      expect(choices.single.label, '  Insurance  ');
      workflow = await session.recurringExpenses.openPlannedDraft(
        recoveryDraftId: draftId,
      );
      expect(workflow.input.recordId, id);
      expect(workflow.input.amount, '-');
      expect(workflow.input.reminders, {1, 7});
      expect(workflow.input.push, isFalse);
      expect(() => workflow.input.reminders.clear(), throwsUnsupportedError);
      workflow.updateInput(
        RecurringPlanDraftInput.fromPayload(
          workflow.input.toPayload()..['amount'] = '125.50',
        ),
      );
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_plan BEFORE INSERT ON local_records WHEN NEW.domain = 'recurring-expenses/templates' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(session.recurringExpenses.recordById(id), isNull);
      await persistence.database.customStatement('DROP TRIGGER fail_plan');
      final saved = (await workflow.confirm())!;
      expect(saved.id, id);
      expect(saved.title, 'Insurance');
      expect(saved.amount, 125.5);
      expect(saved.reminderDaysBefore, [1, 7]);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'stale plan edit retains input and monthly date transition is independent of widgets',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'plan-stale-workflow-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openSession(persistence);
      await seed(session);
      final workflow = await session.recurringExpenses.openPlannedDraft(
        existingRecordId: 'plan',
      );
      workflow.updateInput(
        RecurringPlanDraftInput.fromPayload(
          workflow.input.toPayload()..['title'] = 'Unfinished change',
        ),
      );
      final current = session.recurringExpenses.currentOccurrenceFor('plan')!;
      expect(
        await session.recurringExpenses.updateOccurrence(
          current.copyWith(expectedAmount: 150),
        ),
        isNotNull,
      );
      expect(workflow.isStale, isTrue);
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.title, 'Unfinished change');
      await workflow.session.close();
      expect(
        recurringPlanDueDateAfterChange(
          previousKind: ExpenseScheduleKind.monthly,
          previousDay: 20,
          kind: ExpenseScheduleKind.monthly,
          dueDay: 31,
          dueDate: DateTime(2030, 2, 20),
          now: DateTime(2030, 2, 10),
        ),
        DateTime(2030, 2, 28),
      );
    },
  );
}
