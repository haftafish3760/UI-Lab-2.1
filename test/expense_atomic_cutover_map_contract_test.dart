import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Expense prototype dependency inventory stays complete', () {
    final discovered = <String>{};
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (_directlyDependsOnPrototypeExpenses(entity.path, source)) {
        discovered.add(entity.path);
      }
    }

    expect(discovered, _directPrototypeExpenseConsumers);
  });

  test('cutover blueprint names direct and projected consumers', () {
    final blueprint = File(
      'docs/expense_atomic_cutover_blueprint.md',
    ).readAsStringSync();

    for (final path in {
      ..._directPrototypeExpenseConsumers,
      ..._projectedExpenseConsumers,
    }) {
      expect(
        blueprint,
        contains('`$path`'),
        reason: '$path must remain visible in the atomic cutover map.',
      );
    }
  });

  test('screens never import a concrete Expense repository', () {
    for (final entity in Directory(
      'lib/src/screens',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      expect(
        source,
        isNot(contains('file_expense_repository.dart')),
        reason: '${entity.path} must use the authorized UI controller.',
      );
      expect(
        source,
        isNot(contains('private_expense_repository.dart')),
        reason: '${entity.path} must not choose a storage location.',
      );
      expect(
        source,
        isNot(contains('file_recurring_expense_repository.dart')),
        reason: '${entity.path} must use the authorized recurring service.',
      );
      expect(
        source,
        isNot(contains('private_recurring_expense_repository.dart')),
        reason: '${entity.path} must not choose recurring storage.',
      );
    }
  });

  test('platform launch injects the private authorized Expense session', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final appSource = File('lib/src/app.dart').readAsStringSync();

    expect(mainSource, contains('openPrivateExpenseRepository()'));
    expect(mainSource, contains('expenseRepository: expenses'));
    expect(appSource, contains('ExpenseUiRepositoryController('));
    expect(appSource, contains('ExpenseUiScope('));
    expect(appSource, contains('expenseUiLabOwnerPermissions()'));
  });
}

bool _directlyDependsOnPrototypeExpenses(String path, String source) {
  if (path == 'lib/src/data/expense_prototype_store.dart' ||
      path == 'lib/src/data/prototype_operations_store.dart') {
    return true;
  }
  if (!source.contains('PrototypeOperationsScope') &&
      !source.contains('ExpensePrototypeStore')) {
    return false;
  }
  return const [
    'store.expenses',
    ').expenses',
    '.addExpense(',
    '.updateExpense(',
    '.expenseStore',
    'financialSummary(',
    'reportSummary(',
  ].any(source.contains);
}

const _directPrototypeExpenseConsumers = <String>{
  'lib/src/app.dart',
  'lib/src/data/expense_prototype_store.dart',
  'lib/src/data/prototype_operations_store.dart',
  'lib/src/screens/dashboard/dashboard_day_screen.dart',
  'lib/src/screens/dashboard/dashboard_record_navigation.dart',
  'lib/src/screens/dashboard/dashboard_screen_actions.dart',
  'lib/src/screens/expenses/expense_category_screen.dart',
  'lib/src/screens/expenses/expense_detail_screen.dart',
  'lib/src/screens/expenses/expense_receipt_drafts_screen.dart',
  'lib/src/screens/expenses/expense_receipt_evidence_screen.dart',
  'lib/src/screens/expenses/expenses_day_screen.dart',
  'lib/src/screens/expenses/expenses_screen.dart',
  'lib/src/screens/expenses/receipt_intake_screen.dart',
  'lib/src/screens/expenses/reports_screen.dart',
  'lib/src/screens/expenses/scheduled_expense_detail_screen.dart',
  'lib/src/screens/expenses/scheduled_expenses_screen.dart',
  'lib/src/screens/inventory/material_cost_editor_screen.dart',
  'lib/src/screens/inventory/material_detail_screen.dart',
  'lib/src/screens/work/estimate_items_screen.dart',
  'lib/src/screens/work/job_workspace_interactions.dart',
  'lib/src/screens/work/job_workspace_screen.dart',
  'lib/src/screens/work/work_items_editor.dart',
};

const _projectedExpenseConsumers = <String>{
  'lib/src/data/operational_attention.dart',
  'lib/src/data/prototype_report_projection.dart',
  'lib/src/screens/dashboard/dashboard_attention_actions.dart',
  'lib/src/screens/dashboard/dashboard_attention_screen.dart',
  'lib/src/screens/dashboard/dashboard_screen.dart',
  'lib/src/screens/expenses/report_sources_screen.dart',
};
