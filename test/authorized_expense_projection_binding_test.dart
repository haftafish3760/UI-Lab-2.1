import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test(
    'bound operations projections share one durable Expense and exact cents',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ui-lab-authorized-expense-binding-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      var repository = await FileExpenseRepository.open(directory);
      await repository.create(
        _storedExpense(),
        context: _mutation(DateTime.utc(2026, 9, 1, 12)),
      );
      var controller = _controller(repository);
      final store = PrototypeOperationsStore(
        expenses: [
          ExpenseRecord(
            id: 'prototype-only',
            vendor: 'Prototype Vendor',
            category: ExpenseCategory.other,
            amount: 999,
            date: DateTime(2026, 9, 1),
            owner: 'Alex Morgan',
          ),
        ],
        financialEntries: const [],
        workRecords: const [],
      );
      addTearDown(store.dispose);
      store.bindAuthorizedExpenseController(controller);

      expect(await controller.load(), isTrue);
      expect(store.expenses.map((record) => record.id), ['durable-expense']);
      expect(
        store
            .financialSummary(
              fromInclusive: DateTime(2026, 9, 1),
              toExclusive: DateTime(2026, 9, 2),
            )
            .recordedExpenseCents,
        1001,
      );
      expect(
        store
            .reportSummary(
              fromInclusive: DateTime(2026, 9, 1),
              toExclusive: DateTime(2026, 9, 2),
            )
            .expenses
            .single
            .amountCents,
        1001,
      );

      final updated = await store.updateExpense(
        store.expenses.single.copyWith(vendor: 'Updated Supply'),
      );
      expect(updated?.vendor, 'Updated Supply');

      repository = await FileExpenseRepository.open(directory);
      controller = _controller(repository);
      expect(await controller.load(), isTrue);
      expect(controller.records.single.vendor, 'Updated Supply');
    },
  );
}

ExpenseUiRepositoryController _controller(ExpenseRepository repository) =>
    ExpenseUiRepositoryController(
      ExpenseUiRepositoryBridge(
        service: AuthorizedExpenseService(repository),
        employeeLabelForId: (_) => 'Alex Morgan',
        jobLabelForId: (_) => null,
      ),
      ExpenseCommandPermissions(
        organizationId: 'company-1',
        actorEmployeeId: 'alex',
        permissionRevision: 'permissions-1',
        readScope: ExpenseReadScope.company,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canRestore: true,
        canApprove: true,
        canManageOtherEmployees: true,
      ),
    );

StoredExpenseRecord _storedExpense() => StoredExpenseRecord(
  expenseId: 'durable-expense',
  organizationId: 'company-1',
  createdByEmployeeId: 'alex',
  paidByEmployeeId: 'alex',
  expenseDate: DateTime(2026, 9, 1),
  vendorName: 'Exact Supply',
  categoryId: ExpenseCategory.materials.name,
  categoryLabelSnapshot: ExpenseCategory.materials.label,
  total: const ExpenseMoney(minorUnits: 1001),
  approval: const ExpenseApproval.notRequired(),
  lifecycle: ExpenseLifecycle(
    revision: 1,
    createdAtUtc: DateTime.utc(2026, 9, 1, 12),
    updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
  ),
);

ExpenseMutationContext _mutation(DateTime occurredAtUtc) =>
    ExpenseMutationContext(
      actorEmployeeId: 'alex',
      occurredAtUtc: occurredAtUtc,
      permissionRevision: 'permissions-1',
    );
