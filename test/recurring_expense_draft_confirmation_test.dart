import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  late RecurringExpenseUiController controller;
  final permissions = recurringExpenseUiLabOwnerPermissions();
  const checkpoint = LocalDraftCheckpoint(
    domain: 'expenses/planned',
    draftId: 'input',
    revision: 1,
  );
  final record = ScheduledExpenseRecord(
    id: 'planned-test',
    title: 'Insurance',
    category: ExpenseCategory.vehicleInsurance,
    amount: 100,
    nextDueOn: DateTime(2030, 1, 20),
    kind: ExpenseScheduleKind.monthly,
    ownerEmployeeId: 'alex',
    owner: 'Alex Morgan',
    dueDay: 20,
  );
  Future<void> openController() async {
    controller = RecurringExpenseUiController(
      AuthorizedRecurringExpenseService(persistence.recurringExpenses),
      permissions,
      (_) => 'Alex Morgan',
    );
    expect(await controller.load(), isTrue);
  }

  Future<void> saveDraft() => persistence.drafts
      .save(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        draftId: checkpoint.draftId,
        ownerId: 'alex',
        expectedRevision: 0,
        payload: {'title': 'Insurance', 'amount': '100.'},
        occurredAt: DateTime.utc(2030),
      )
      .then((_) {});
  Future<int> draftCount() async => (await persistence.drafts.list(
    organizationId: permissions.organizationId,
    domain: checkpoint.domain,
    ownerId: 'alex',
  )).length;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'recurring-draft-confirmation-',
    );
    persistence = await LocalPersistence.open(directory: directory);
    await openController();
    await saveDraft();
  });
  tearDown(() async {
    controller.dispose();
    await persistence.close();
    await directory.delete(recursive: true);
  });

  test(
    'draft deletion failure rolls back template and initial occurrence; retry survives reopen',
    () async {
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_draft BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected draft failure'); END",
      );
      expect(
        await controller.create(record, draftCheckpoint: checkpoint),
        isNull,
      );
      expect(controller.records, isEmpty);
      expect(
        await persistence.database
            .select(persistence.database.localRecords)
            .get(),
        isEmpty,
      );
      expect(
        await persistence.database
            .select(persistence.database.localCommands)
            .get(),
        isEmpty,
      );
      expect(await draftCount(), 1);
      await persistence.database.customStatement('DROP TRIGGER fail_draft');
      expect(
        await controller.create(record, draftCheckpoint: checkpoint),
        isNotNull,
      );
      expect(await draftCount(), 0);
      controller.dispose();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      await openController();
      expect(controller.records.single.title, 'Insurance');
      expect(controller.currentOccurrenceFor(record.id)!.expectedAmount, 100);
      expect(controller.revisionForId(record.id), 1);
    },
  );

  test(
    'a newer raw draft prevents confirmation without deleting that input',
    () async {
      await persistence.drafts.save(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        draftId: checkpoint.draftId,
        ownerId: 'alex',
        expectedRevision: 1,
        payload: {'amount': '125.'},
        occurredAt: DateTime.utc(2030),
      );
      expect(
        await controller.create(record, draftCheckpoint: checkpoint),
        isNull,
      );
      expect(controller.records, isEmpty);
      expect(
        await persistence.database
            .select(persistence.database.localRecords)
            .get(),
        isEmpty,
      );
      final retained = (await persistence.drafts.list(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        ownerId: 'alex',
      )).single;
      expect(retained.revision, 2);
      expect(persistence.drafts.decode(retained)['amount'], '125.');
    },
  );

  test(
    'stale recovered edit preserves draft and current planned expense',
    () async {
      expect(await controller.create(record), isNotNull);
      final changed = record.copyWith(amount: 125);
      expect(await controller.update(changed), isNotNull);
      expect(
        await controller.update(
          record,
          draftCheckpoint: checkpoint,
          expectedRevision: 1,
        ),
        isNull,
      );
      expect(
        await controller.update(record, draftCheckpoint: checkpoint),
        isNull,
      );
      expect(controller.records.single.amount, 125);
      expect(await draftCount(), 1);
      expect(
        await controller.update(
          record,
          draftCheckpoint: checkpoint,
          expectedRevision: 2,
        ),
        isNotNull,
      );
      expect(controller.records.single.amount, 100);
      expect(await draftCount(), 0);
      expect(controller.revisionForId(record.id), 3);
    },
  );
  test(
    'payment edit and parent roll back together when draft consumption fails',
    () async {
      expect(await controller.create(record), isNotNull);
      final original = controller.currentOccurrenceFor(record.id)!;
      final edited = original.copyWith(
        expectedAmount: 125,
        dueOn: DateTime(2030, 1, 25),
      );
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_occurrence_draft BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(
        await controller.updateOccurrence(
          edited,
          draftCheckpoint: checkpoint,
          expectedTemplateRevision: 1,
          expectedRevision: 1,
        ),
        isNull,
      );
      expect(controller.currentOccurrenceFor(record.id)!.expectedAmount, 100);
      expect(controller.records.single.nextDueOn, DateTime(2030, 1, 20));
      expect(controller.revisionForId(record.id), 1);
      expect(controller.occurrenceRevisionForId(original.id), 1);
      expect(await draftCount(), 1);
      await persistence.database.customStatement(
        'DROP TRIGGER fail_occurrence_draft',
      );
      expect(
        await controller.updateOccurrence(
          edited,
          draftCheckpoint: checkpoint,
          expectedTemplateRevision: 1,
          expectedRevision: 1,
        ),
        isNotNull,
      );
      controller.dispose();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      await openController();
      expect(controller.currentOccurrenceFor(record.id)!.expectedAmount, 125);
      expect(controller.records.single.nextDueOn, DateTime(2030, 1, 25));
      expect(controller.records.single.amount, 100);
      expect(controller.revisionForId(record.id), 2);
      expect(controller.occurrenceRevisionForId(original.id), 2);
      expect(await draftCount(), 0);
    },
  );

  test(
    'payment draft requires both original revisions and rejects a changed parent',
    () async {
      expect(await controller.create(record), isNotNull);
      final original = controller.currentOccurrenceFor(record.id)!;
      await controller.setState(record.id, ScheduledExpenseState.paused);
      expect(controller.revisionForId(record.id), 2);
      expect(controller.occurrenceRevisionForId(original.id), 1);
      expect(
        await controller.updateOccurrence(
          original.copyWith(expectedAmount: 125),
          draftCheckpoint: checkpoint,
          expectedTemplateRevision: 1,
          expectedRevision: 1,
        ),
        isNull,
      );
      expect(
        await controller.updateOccurrence(
          original,
          draftCheckpoint: checkpoint,
          expectedRevision: 1,
        ),
        isNull,
      );
      expect(
        await controller.updateOccurrence(
          original,
          draftCheckpoint: checkpoint,
          expectedTemplateRevision: 2,
        ),
        isNull,
      );
      expect(controller.currentOccurrenceFor(record.id)!.expectedAmount, 100);
      expect(await draftCount(), 1);
    },
  );
}
