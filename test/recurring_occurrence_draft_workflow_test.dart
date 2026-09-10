import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_occurrence_draft_workflow.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession, seed;

void main() {
  test(
    'occurrence raw input reopens and retries with plan schedule unchanged',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'occurrence-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openSession(persistence);
      final occurrenceId = await seed(session);
      final template = session.recurringExpenses.recordById('plan')!;
      var workflow = await session.recurringExpenses.openOccurrenceDraft(
        templateId: 'plan',
        occurrenceId: occurrenceId,
      );
      final revisedDate = DateTime(2030, 1, 23);
      workflow.updateValues(amount: '-', dueOn: revisedDate);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openSession(persistence);
      workflow = await session.recurringExpenses.openOccurrenceDraft(
        templateId: 'plan',
        occurrenceId: occurrenceId,
      );
      expect(workflow.input.amount, '-');
      expect(workflow.input.dueOn, revisedDate);
      expect(workflow.isStale, isFalse);
      workflow.updateValues(amount: ' 125.50 ', dueOn: revisedDate);
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_occurrence BEFORE DELETE ON local_drafts WHEN OLD.domain = 'expenses/planned-occurrence' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(
        session.recurringExpenses.currentOccurrenceFor('plan')!.expectedAmount,
        100,
      );
      expect(workflow.input.amount, ' 125.50 ');
      await persistence.database.customStatement(
        'DROP TRIGGER fail_occurrence',
      );
      final saved = (await workflow.confirm())!;
      expect(saved.expectedAmount, 125.5);
      expect(saved.dueOn, revisedDate);
      expect(
        session.recurringExpenses.recordById('plan')!.nextDueOn,
        revisedDate,
      );
      expect(
        session.recurringExpenses.recordById('plan')!.dueDay,
        template.dueDay,
      );
      expect(session.recurringExpenses.recordById('plan')!.kind, template.kind);
      expect(
        session.recurringExpenses.recordById('plan')!.amount,
        template.amount,
      );
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'stale occurrence preserves raw input and refuses another revision',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'occurrence-stale-workflow-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openSession(persistence);
      final occurrenceId = await seed(session);
      final workflow = await session.recurringExpenses.openOccurrenceDraft(
        templateId: 'plan',
        occurrenceId: occurrenceId,
      );
      workflow.updateValues(amount: '80.', dueOn: DateTime(2030, 1, 25));
      final current = session.recurringExpenses.currentOccurrenceFor('plan')!;
      expect(
        await session.recurringExpenses.updateOccurrence(
          current.copyWith(expectedAmount: 150),
        ),
        isNotNull,
      );
      expect(workflow.isStale, isTrue);
      expect(await workflow.confirm(), isNull);
      expect(workflow.input.amount, '80.');
      expect(
        session.recurringExpenses.currentOccurrenceFor('plan')!.expectedAmount,
        150,
      );
      await workflow.session.close();
    },
  );
}
