import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_seed.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';

void main() {
  test(
    'UI Lab bootstrap is durable idempotent and excludes draft intake',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ui-lab-expense-seed-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      var repository = await FileExpenseRepository.open(directory);

      await seedExpenseUiLabDemoDataIfEmpty(repository);
      await seedExpenseUiLabDemoDataIfEmpty(repository);
      final access = ExpenseAccess.company(
        organizationId: expenseUiLabOrganizationId,
        employeeId: expenseUiLabOwnerEmployeeId,
      );
      var records = await repository.query(ExpenseQuery(access: access));

      expect(records, isNotEmpty);
      expect(
        records.where((record) => record.expenseId == 'EXP-1049'),
        isEmpty,
      );
      expect(
        records
            .singleWhere((record) => record.expenseId == 'EXP-1048')
            .total
            ?.minorUnits,
        23150,
      );
      final count = records.length;

      repository = await FileExpenseRepository.open(directory);
      await seedExpenseUiLabDemoDataIfEmpty(repository);
      records = await repository.query(ExpenseQuery(access: access));
      expect(records, hasLength(count));
    },
  );
}
