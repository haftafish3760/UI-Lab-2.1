import 'support/expense_setup_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';

void main() {
  testWidgets('Expenses keeps records and calendar in bounded desktop lanes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();
    await useCompletedExpenseSetup(tester);
    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expenses-2-column-layout')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    final date = find.byKey(const ValueKey('expenses-date-heading'));
    final total = find.byKey(const ValueKey('expense-spending-day'));
    final planned = find.byKey(const ValueKey('planned-expenses-section'));
    final entries = find.byKey(const ValueKey('expense-entries-section'));
    expect(
      tester.getTopLeft(total).dy,
      lessThan(tester.getTopLeft(planned).dy),
    );
    expect(tester.getTopLeft(date).dy, lessThan(tester.getTopLeft(total).dy));
    expect(
      tester.getTopLeft(total).dy,
      lessThan(tester.getTopLeft(entries).dy),
    );

    final calendar = find.byKey(const ValueKey('work-5-7-calendar'));
    await tester.ensureVisible(calendar);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(calendar).width,
      lessThanOrEqualTo(AppLayoutEngine.laneMaximum),
    );
    expect(
      tester.getSize(calendar).width,
      lessThanOrEqualTo(AppLayoutEngine.calendarMaximum),
    );
    final monthHeight = tester.getSize(calendar).height;
    expect(monthHeight, lessThanOrEqualTo(510));
    final monthGridHeight = tester
        .getSize(find.byKey(const ValueKey('work-5-7-calendar-grid')))
        .height;
    final monthGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('work-5-7-calendar-grid')),
    );
    final days = monthGrid.childrenDelegate.estimatedChildCount!;
    expect(days, anyOf(28, 35, 42));

    await tester.tap(find.byKey(const ValueKey('calendar-view-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsOneWidget);
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('work-5-7-calendar-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 7);
    // Week removes five rows; its longer period label may reflow separately.
    expect(
      monthGridHeight -
          tester
              .getSize(find.byKey(const ValueKey('work-5-7-calendar-grid')))
              .height,
      closeTo(monthGridHeight * (days - 7) / days, 0.01),
    );
    expect(tester.getSize(calendar).height, lessThan(monthHeight));
    expect(tester.takeException(), isNull);
  });
}
