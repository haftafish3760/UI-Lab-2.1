import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/atomic_recurring_expense_payment.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  late Directory directory;
  late LocalPersistence persistence;
  late String occurrenceId;
  final permissions = recurringExpenseUiLabOwnerPermissions();
  const checkpoint = LocalDraftCheckpoint(
    domain: 'expenses/planned-payment',
    draftId: 'payment',
    revision: 1,
  );
  RecurringExpenseUiController controller() => RecurringExpenseUiController(
    AuthorizedRecurringExpenseService(persistence.recurringExpenses),
    permissions,
    (_) => 'Alex Morgan',
  );
  Future<bool> pay({int parentRevision = 1, double amount = 125.50}) async =>
      (await AtomicRecurringExpensePayment(
            expenses: persistence.expenses,
            recurringExpenses: persistence.recurringExpenses,
            employeeLabelForId: (_) => 'Alex Morgan',
          ).markPaid(
            templateId: 'plan',
            occurrenceId: occurrenceId,
            expectedTemplateRevision: parentRevision,
            expectedOccurrenceRevision: 1,
            actualAmount: amount,
            paidOn: DateTime(2030, 1, 20),
            expensePermissions: expenseUiLabOwnerPermissions(),
            recurringPermissions: permissions,
            draftCheckpoint: checkpoint,
          ))
          .succeeded;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'atomic-recurring-payment-',
    );
    persistence = await LocalPersistence.open(directory: directory);
    final seed = controller();
    await seed.load();
    await seed.create(
      ScheduledExpenseRecord(
        id: 'plan',
        title: 'Insurance',
        category: ExpenseCategory.vehicleInsurance,
        amount: 100,
        nextDueOn: DateTime(2030, 1, 20),
        kind: ExpenseScheduleKind.monthly,
        ownerEmployeeId: 'alex',
        owner: 'Alex Morgan',
        dueDay: 20,
      ),
    );
    occurrenceId = seed.currentOccurrenceFor('plan')!.id;
    seed.dispose();
    await persistence.drafts.save(
      organizationId: permissions.organizationId,
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
      ownerId: 'alex',
      expectedRevision: 0,
      payload: {
        'templateId': 'plan',
        'occurrenceId': occurrenceId,
        'baseTemplateRevision': 1,
        'baseRevision': 1,
        'amount': '125.50',
      },
      occurredAt: DateTime.utc(2030),
    );
  });
  tearDown(() async {
    await persistence.close();
    await directory.delete(recursive: true);
  });
  Future<void> unchanged() async {
    expect(
      await persistence.expenses.query(
        ExpenseQuery(access: expenseUiLabOwnerPermissions().readAccess!),
      ),
      isEmpty,
    );
    final current = controller();
    await current.load();
    expect(current.currentOccurrenceFor('plan')!.id, occurrenceId);
    expect(current.revisionForId('plan'), 1);
    expect(current.occurrencesFor('plan'), hasLength(1));
    current.dispose();
    expect(
      await persistence.drafts.list(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        ownerId: 'alex',
      ),
      hasLength(1),
    );
  }

  test(
    'second aggregate failure rolls back expense, advancement and draft; retry survives reopen',
    () async {
      final commands =
          (await persistence.database
                  .select(persistence.database.localCommands)
                  .get())
              .length;
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_payment BEFORE UPDATE ON local_records WHEN NEW.domain = 'recurring-expenses/templates' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await pay(), isFalse);
      await unchanged();
      expect(
        (await persistence.database
                .select(persistence.database.localCommands)
                .get())
            .length,
        commands,
      );
      await persistence.database.customStatement('DROP TRIGGER fail_payment');
      expect(await pay(), isTrue);
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final expenses = await persistence.expenses.query(
        ExpenseQuery(access: expenseUiLabOwnerPermissions().readAccess!),
      );
      expect(expenses.single.expenseId, 'EXP-RECURRING-$occurrenceId');
      expect(expenses.single.total.minorUnits, 12550);
      final current = controller();
      await current.load();
      expect(current.occurrencesFor('plan'), hasLength(2));
      expect(
        current
            .occurrencesFor('plan')
            .where(
              (item) => item.status == ScheduledExpenseOccurrenceStatus.paid,
            )
            .single
            .expenseId,
        expenses.single.expenseId,
      );
      expect(
        current.currentOccurrenceFor('plan')!.dueOn,
        DateTime(2030, 2, 20),
      );
      current.dispose();
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
    'stale base and draft consumption failure preserve every aggregate',
    () async {
      expect(await pay(parentRevision: 2), isFalse);
      await unchanged();
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_input BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await pay(), isFalse);
      await unchanged();
    },
  );
  test(
    'retry after committed payment and reopen adds no expense or advancement',
    () async {
      expect(await pay(), isTrue);
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      final commands =
          (await persistence.database
                  .select(persistence.database.localCommands)
                  .get())
              .length;
      expect(await pay(), isTrue);
      expect(await pay(amount: 126), isFalse);
      expect(
        (await persistence.database
                .select(persistence.database.localCommands)
                .get())
            .length,
        commands,
      );
      final current = controller();
      await current.load();
      expect(current.occurrencesFor('plan'), hasLength(2));
      current.dispose();
      await persistence.drafts.save(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        draftId: checkpoint.draftId,
        ownerId: 'alex',
        expectedRevision: 0,
        payload: {'amount': 'new input'},
        occurredAt: DateTime.utc(2030),
      );
      expect(await pay(), isFalse);
      final retained = (await persistence.drafts.list(
        organizationId: permissions.organizationId,
        domain: checkpoint.domain,
        ownerId: 'alex',
      )).single;
      expect(persistence.drafts.decode(retained)['amount'], 'new input');
      expect(
        (await persistence.database
                .select(persistence.database.localCommands)
                .get())
            .length,
        commands,
      );
    },
  );
}
