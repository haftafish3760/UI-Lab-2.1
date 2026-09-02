import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';

void main() {
  testWidgets('Expenses aligns three lanes and bounds its month calendar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expenses-3-column-layout')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('expenses-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    final date = find.byKey(const ValueKey('expenses-date-heading'));
    final total = find.byKey(const ValueKey('daily-expense-total'));
    final planned = find.byKey(const ValueKey('planned-expenses-section'));
    final entries = find.byKey(const ValueKey('expense-entries-section'));
    expect(
      tester.getTopLeft(total).dy,
      lessThan(tester.getTopLeft(planned).dy),
    );
    expect(
      (tester.getCenter(date).dy - tester.getCenter(total).dy).abs(),
      lessThan(18),
    );
    expect(tester.getTopLeft(planned).dy, tester.getTopLeft(entries).dy);

    final calendar = find.byKey(const ValueKey('work-5-7-calendar'));
    await tester.ensureVisible(calendar);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(calendar).width,
      lessThanOrEqualTo(AppLayoutEngine.laneMaximum),
    );
    expect(tester.getSize(calendar).width, lessThan(500));
    expect(tester.getSize(calendar).height, lessThan(510));

    await tester.tap(find.byKey(const ValueKey('calendar-view-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsOneWidget);
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('work-5-7-calendar-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 7);
    expect(tester.takeException(), isNull);
  });
}
