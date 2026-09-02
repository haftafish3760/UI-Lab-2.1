import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/shared/localized_date.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scroll = find.byKey(const ValueKey('expense-editor-scroll'));
  for (var attempt = 0; attempt < 8; attempt++) {
    if (target.hitTestable().evaluate().isNotEmpty) break;
    await tester.drag(scroll, const Offset(0, -420));
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Expenses uses shared lanes and Technician Admin views', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1440, 900));
    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    await tester.pumpAndSettle();

    expect(find.text('My expenses'), findsOneWidget);
    expect(find.text('Daily total'), findsOneWidget);
    expect(find.text(r'$336.41'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('daily-expense-total'))).height,
      lessThanOrEqualTo(64),
    );
    expect(find.text('View day'), findsNothing);
    expect(
      find.byKey(const ValueKey('expenses-context-selector')),
      findsOneWidget,
    );
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text("Today's entries"), findsOneWidget);
    expect(find.text('Expense categories'), findsNothing);
    expect(find.text('Choose date'), findsNothing);
    expect(find.text('Reports and recap'), findsNothing);
    expect(find.text('Record expense'), findsOneWidget);
    expect(find.text('Add fuel'), findsOneWidget);
    expect(find.text('Add receipt'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Company expenses'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.textContaining('Central Supply'), findsWidgets);
    expect(find.text('CleanPro Wholesale'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Expenses uses one labeled add menu on compact layouts', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-add-actions-screen')),
      findsOneWidget,
    );
    expect(find.text('Record expense'), findsOneWidget);
    expect(find.text('Add fuel'), findsOneWidget);
    expect(find.text('Add receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expense settings visibly update only the Expense screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    expect(find.textContaining('JOB-1038'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('expenses-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show related jobs'));
    await tester.tap(
      find.byKey(const ValueKey('expense-category-mode-topTen')),
    );
    await tester.tap(
      find.byKey(const ValueKey('save-expense-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('JOB-1038'), findsNothing);
    expect(find.text('Expense categories'), findsOneWidget);
    expect(find.text('Daily total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense entry validates and writes through the shared store', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record expense'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-editor-screen')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('expense-vendor-field')),
      'Neighborhood Hardware',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-amount-field')),
      '10.00',
    );
    final totalOnly = find.byKey(const ValueKey('receipt-total-only-choice'));
    await _scrollTo(tester, totalOnly);
    await tester.tap(totalOnly);
    final save = find.byKey(const ValueKey('save-expense-button'));
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-editor-screen')), findsNothing);
    expect(find.textContaining('Neighborhood Hardware'), findsOneWidget);
    expect(find.text(r'$346.41'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense rows open inline receipt evidence and detailed lines', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();

    final record = find.byKey(const ValueKey('expense-record-EXP-1048'));
    expect(record, findsOneWidget);
    expect(tester.getSize(record).height, lessThanOrEqualTo(65));
    expect(tester.takeException(), isNull);
    await tester.tap(record);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-detail-screen')), findsOneWidget);
    expect(find.textContaining('Central Supply'), findsWidgets);
    expect(find.text('Items on this receipt'), findsOneWidget);
    expect(find.text('Tap any item to review or change it.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-detail-line-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('receipt-evidence-preview-EXP-1048')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expense-line-EXP-1048-L1')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Single-handle pull-down kitchen faucet'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('edit-expense-button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('receipt-evidence-preview-EXP-1048')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-receipt-evidence-screen')),
      findsOneWidget,
    );
    expect(find.text('No retained receipt is linked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removed expenses leave totals and can be restored', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    final removableExpense = find.byKey(
      const ValueKey('expense-record-EXP-1048'),
    );
    for (var attempt = 0; attempt < 4; attempt++) {
      if (removableExpense.hitTestable().evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.tap(removableExpense.hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'opening Expense detail');
    await tester.tap(
      find.byKey(const ValueKey('expense-detail-actions-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to removed expenses'));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'opening remove confirmation',
    );
    expect(find.text('Remove this expense?'), findsOneWidget);
    expect(find.textContaining('not be permanently erased'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirm-remove-expense-button')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'removing Expense');

    expect(find.byKey(const ValueKey('expense-detail-screen')), findsNothing);
    expect(find.byKey(const ValueKey('expense-record-EXP-1048')), findsNothing);
    final removedLink = find.byKey(
      const ValueKey('open-removed-expenses-button'),
    );
    expect(removedLink, findsOneWidget);
    for (var attempt = 0; attempt < 3; attempt++) {
      if (removedLink.hitTestable().evaluate().isNotEmpty) break;
      await tester.drag(find.byType(ListView).first, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    await tester.tap(removedLink.hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'opening removed Expenses');

    expect(
      find.byKey(const ValueKey('removed-expenses-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('removed-expense-EXP-1048')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('restore-expense-EXP-1048')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'restoring Expense');
    expect(
      find.text('There are no removed expenses in this view.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back to Expenses'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-record-EXP-1048')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-removed-expenses-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin attention opens the exact policy exception', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    final date = find.byKey(const ValueKey('expenses-date-heading'));
    final attention = find.byKey(const ValueKey('expenses-needs-attention'));
    expect(
      tester.getTopLeft(date).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    await tester.tap(
      find.descendant(of: attention, matching: find.text('Show all 1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-attention-screen')),
      findsOneWidget,
    );
    expect(find.textContaining('QuickFuel'), findsOneWidget);
    expect(find.textContaining('Needs receipt review'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('expense-record-EXP-1047')));
    await tester.pumpAndSettle();
    expect(find.textContaining(r'$50 field-expense limit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category display is one exclusive mode and opens its records', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    expect(find.text('Expense categories'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('expenses-settings-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('expense-category-mode-custom')),
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-category-mode-custom')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('choose-expense-categories-button')),
    );
    await tester.pumpAndSettle();
    final materials = find.widgetWithText(FilterChip, 'Materials');
    await tester.ensureVisible(materials);
    await tester.tap(materials);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use categories'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-expense-settings-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('save-expense-settings-button')),
    );
    await tester.pumpAndSettle();

    final categories = find.byKey(const ValueKey('expense-categories-section'));
    expect(categories, findsOneWidget);
    expect(
      find.descendant(of: categories, matching: find.text('Materials')),
      findsOneWidget,
    );
    final categoryLink = find.byKey(
      const ValueKey('expense-category-materials'),
    );
    await tester.ensureVisible(categoryLink);
    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(categoryLink);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expense-category-screen')),
      findsOneWidget,
    );
    expect(find.textContaining('Central Supply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add receipt opens a labeled review-first intake screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('receipt-intake-screen')), findsOneWidget);
    expect(find.text('Capture receipt photos'), findsOneWidget);
    expect(find.text('Choose existing photos'), findsOneWidget);
    expect(find.text('Choose a receipt file'), findsOneWidget);
    expect(find.text('Before anything is saved'), findsOneWidget);
    expect(
      find.textContaining('Receipt Assistant suggestions'),
      findsOneWidget,
    );
    expect(find.textContaining('OCR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Receipt settings visibly update only the intake screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add receipt'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show review checklist'));
    await tester.tap(find.text('Show evidence reminders'));
    await tester.tap(
      find.byKey(const ValueKey('save-receipt-intake-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Before anything is saved'), findsNothing);
    expect(
      find.text('Long receipts may use several photos in top-to-bottom order.'),
      findsNothing,
    );
    expect(find.text('Choose receipt source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expenses calendar opens its own scoped day screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();

    final calendar = find.byKey(const ValueKey('work-5-7-calendar'));
    await tester.ensureVisible(calendar);
    await tester.pumpAndSettle();
    final suffix =
        '${dashboardToday.year}-${dashboardToday.month}-${dashboardToday.day}';
    final count = find.byKey(ValueKey('module-calendar-entry-count-$suffix'));
    expect(count, findsOneWidget);
    expect(tester.getSize(count).height, lessThanOrEqualTo(12));
    await tester.tap(find.byKey(ValueKey('work-calendar-day-$suffix')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expenses-day-screen')), findsOneWidget);
    final dayContext = tester.element(
      find.byKey(const ValueKey('expenses-day-screen')),
    );
    expect(
      find.text(operationalDateLabel(dayContext, dashboardToday)),
      findsOneWidget,
    );
    expect(find.text('Total expenses for this day'), findsOneWidget);
    expect(find.textContaining('Central Supply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
