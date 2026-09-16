import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_recap_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'support/expense_setup_fixture.dart';

void main() {
  testWidgets(
    'home opens separate recap and selected period drills into records',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const UiLabApp());
      await tester.pumpAndSettle();
      await useCompletedExpenseSetup(tester);
      await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
      await tester.pumpAndSettle();
      final recap = find.byKey(const ValueKey('expenses-open-recap'));
      await tester.ensureVisible(recap);
      await tester.tap(recap);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseRecapScreen), findsOneWidget);
      expect(find.text('My expenses'), findsOneWidget);
      expect(find.text('Spending by category'), findsOneWidget);
      await tester.tap(find.text('Quarter'));
      await tester.pumpAndSettle();
      final entries = find.byKey(const ValueKey('recap-view-entries'));
      await tester.ensureVisible(entries);
      await tester.tap(entries);
      await tester.pumpAndSettle();
      expect(find.text('Quarter expenses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied recap does not read ledger or show totals', (
    tester,
  ) async {
    const access = ExpensePermissions(
      canView: false,
      canViewAmounts: false,
      canCreate: false,
      canAttachReceipt: false,
      canEditOwn: false,
      canEditTeam: false,
      canReviewCompanyExpenses: false,
      canManageScheduledExpenses: false,
      canConfigureDisplay: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseRecapScreen(
          anchor: DateTime(2026, 9, 15),
          firstWeekday: 1,
          permissions: access,
        ),
      ),
    );
    expect(
      find.text('You do not have permission to view spending.'),
      findsOneWidget,
    );
    expect(find.text('Recorded expenses'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
