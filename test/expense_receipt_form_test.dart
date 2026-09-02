import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_line_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

Future<void> _openExpenses(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
  await tester.pumpAndSettle();
}

Future<void> _pumpManualEditor(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  final store = PrototypeOperationsStore();
  addTearDown(scope.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ExpenseEditorScreen(
            expenseDate: dashboardToday,
            initialReceiptType: ExpenseReceiptType.detailed,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final editor = find.byKey(const ValueKey('expense-editor-screen'));
  final scroll = editor.evaluate().isNotEmpty
      ? find.byKey(const ValueKey('expense-editor-scroll'))
      : find.byKey(const ValueKey('expense-detail-scroll'));
  for (var attempt = 0; attempt < 8; attempt++) {
    if (target.hitTestable().evaluate().isNotEmpty) break;
    await tester.drag(scroll, const Offset(0, -420));
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('manual receipt path explains detail and saves editable items', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    await _openExpenses(tester);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual-receipt-entry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-editor-screen')), findsOneWidget);
    expect(find.text('Review every item on the receipt'), findsOneWidget);
    expect(find.textContaining('Basic receipt'), findsNothing);
    expect(find.textContaining('Detailed receipt'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('expense-vendor-field')),
      'Ferguson Plumbing Supply',
    );
    final addItem = find.byKey(const ValueKey('add-expense-line-item'));
    await _scrollTo(tester, addItem);
    await tester.tap(addItem);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-line-item-editor-screen')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-line-description')),
      '1/2-in PEX-A coupling',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-line-part-number')),
      'UC008LFZ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-line-unit-price')),
      '7.49',
    );
    await tester.tap(find.byKey(const ValueKey('save-expense-line-item')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/2-in PEX-A coupling'), findsOneWidget);
    final materialsChoice = find.byKey(
      const ValueKey('prepare-materials-review-choice'),
    );
    await _scrollTo(tester, materialsChoice);
    await tester.tap(materialsChoice);
    await tester.pumpAndSettle();
    final saveExpense = find.byKey(const ValueKey('save-expense-button'));
    await _scrollTo(tester, saveExpense);
    await tester.tap(saveExpense);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ferguson Plumbing Supply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a receipt line opens the full edit form', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    await _openExpenses(tester);
    await tester.tap(find.byKey(const ValueKey('expense-record-EXP-1048')));
    await tester.pumpAndSettle();

    final line = find.byKey(const ValueKey('expense-line-EXP-1048-L1'));
    await _scrollTo(tester, line);
    await tester.tap(line);
    await tester.pumpAndSettle();
    expect(find.text('Edit receipt item'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('expense-line-description')),
      'Single-handle pull-down faucet, brushed nickel',
    );
    await tester.tap(find.byKey(const ValueKey('save-expense-line-item')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-correction-reason-dialog')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-correction-reason-field')),
      'Corrected the faucet description from the retained receipt.',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-expense-correction-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Single-handle pull-down faucet, brushed nickel'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('receipt item search handles a very long receipt', (
    tester,
  ) async {
    final items = List.generate(
      240,
      (index) => ExpenseLineItem(
        id: 'line-$index',
        description: 'Material item $index',
        partNumber: 'PART-$index',
        category: index.isEven
            ? ExpenseCategory.materials
            : ExpenseCategory.tools,
        quantity: 1,
        unit: 'each',
        unitPrice: index + 1,
      ),
    );
    ExpenseLineItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseLineItemsEditor(
              items: items,
              onAdd: () {},
              onEdit: (item) => selected = item,
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-line-search')),
      'PART-239',
    );
    await tester.pumpAndSettle();

    expect(find.text('Showing 1 of 1'), findsOneWidget);
    final match = find.byKey(const ValueKey('edit-expense-line-line-239'));
    expect(match, findsOneWidget);
    await tester.tap(match);
    expect(selected?.id, 'line-239');
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual receipt form uses tablet width without stretching', (
    tester,
  ) async {
    await _pumpManualEditor(tester, const Size(900, 700));

    final vendor = find.byKey(const ValueKey('expense-vendor-field'));
    final date = find.byKey(const ValueKey('expense-receipt-date-field'));
    final category = find.byKey(const ValueKey('expense-category-field'));
    final job = find.byKey(const ValueKey('expense-job-field'));
    expect(
      (tester.getTopLeft(vendor).dy - tester.getTopLeft(date).dy).abs(),
      lessThan(2),
    );
    expect(
      (tester.getTopLeft(category).dy - tester.getTopLeft(job).dy).abs(),
      lessThan(2),
    );
    expect(tester.getSize(find.byType(Form)).width, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });
}
