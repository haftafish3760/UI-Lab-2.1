import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

void main() {
  testWidgets('confirmed receipt correction requires a plain-language reason', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    final expense = find.byKey(const ValueKey('expense-record-EXP-1048'));
    await tester.ensureVisible(expense);
    await tester.tap(expense);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-expense-button')));
    await tester.pumpAndSettle();
    expect(find.text('Correct receipt'), findsWidgets);
    expect(find.text('Review every item on the receipt'), findsOneWidget);
    expect(
      find.textContaining('Single-handle pull-down kitchen faucet'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('expense-vendor-field')),
      'Central Supply Warehouse',
    );
    final save = find.byKey(const ValueKey('save-expense-button'));
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-correction-reason-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-expense-correction-button')),
    );
    await tester.pump();
    expect(find.text('Enter a reason for this correction.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('expense-correction-reason-field')),
      'Corrected the vendor name from the retained receipt.',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-expense-correction-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-detail-screen')), findsOneWidget);
    expect(find.text('Central Supply Warehouse'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('policy-controlled receipt correction explains approval impact', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    final attention = find.byKey(const ValueKey('expenses-needs-attention'));
    await tester.tap(
      find.descendant(of: attention, matching: find.text('Show all 1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-record-EXP-1047')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('expense-vendor-field')),
      'QuickFuel Station 14',
    );
    final save = find.byKey(const ValueKey('save-expense-button'));
    await _scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This correction requires company approval before it counts in '
        'company books.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

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
