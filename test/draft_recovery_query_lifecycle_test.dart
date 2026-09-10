import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_query.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';

void main() {
  test(
    'disposed domain sessions revoke existing queries without deleting drafts',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'recovery-query-lifecycle-',
      );
      final persistence = await LocalPersistence.open(directory: root);
      final work = await openUiLabWorkSession(persistence.database);
      final directory = await openUiLabDirectory(persistence.database);
      final expenses = ExpenseUiRepositoryController(
        ExpenseUiRepositoryBridge(
          service: AuthorizedExpenseService(persistence.expenses),
          employeeLabelForId: (_) => 'Fixture owner',
          jobLabelForId: (_) => null,
        ),
        expenseUiLabOwnerPermissions(),
        drafts: persistence.drafts,
      );
      final recurring = RecurringExpenseUiController(
        AuthorizedRecurringExpenseService(persistence.recurringExpenses),
        recurringExpenseUiLabOwnerPermissions(),
        (_) => 'Fixture owner',
        drafts: persistence.drafts,
      );
      final owners = <(DraftRecoveryQuery Function(), void Function())>[
        (() => work.recoveryFor(WorkRecordKind.estimate), work.dispose),
        (() => directory.customerDraftRecovery, directory.dispose),
        (() => expenses.manualDraftRecovery, expenses.dispose),
        (() => recurring.plannedDraftRecovery, recurring.dispose),
      ];
      final disposed = <int>{};
      try {
        for (var index = 0; index < owners.length; index++) {
          final query = owners[index].$1();
          await persistence.drafts.save(
            organizationId: query.organizationId,
            ownerId: query.ownerId,
            domain: query.domain,
            draftId: 'retained-$index',
            expectedRevision: 0,
            payload: {
              query.parentField: null,
              query.labelField: 'Retained input',
            },
            occurredAt: DateTime.now().toUtc(),
          );
          expect((await query.list()).single.label, 'Retained input');
          owners[index].$2();
          disposed.add(index);
          expect(await query.list(), isEmpty);
          expect(owners[index].$1, throwsStateError);
          expect(
            await persistence.drafts.find(
              organizationId: query.organizationId,
              ownerId: query.ownerId,
              domain: query.domain,
              draftId: 'retained-$index',
            ),
            isNotNull,
          );
        }
      } finally {
        for (var index = 0; index < owners.length; index++) {
          if (!disposed.contains(index)) owners[index].$2();
        }
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
}
