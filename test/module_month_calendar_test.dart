import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/module_month_calendar.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('shared calendar honors compact and desktop lane bounds', (
    tester,
  ) async {
    Future<double> pumpCalendar(double maximumWidth) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 1440,
              child: WorkMonthCalendar(
                maximumWidth: maximumWidth,
                selectedDay: DateTime(2026, 8, 29),
                onDaySelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .getSize(find.byKey(const ValueKey('work-5-7-calendar')))
          .width;
    }

    expect(await pumpCalendar(400), 400);
    expect(await pumpCalendar(600), 600);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared calendar defaults to Month and switches inline to Week', (
    tester,
  ) async {
    var selected = DateTime(2026, 8, 29);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: WorkMonthCalendar(
              selectedDay: selected,
              onDaySelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var grid = tester.widget<GridView>(
      find.byKey(const ValueKey('work-5-7-calendar-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 42);
    expect(find.text('August 2026'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-period-grid-transition')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('calendar-view-toggle')));
    await tester.pumpAndSettle();
    grid = tester.widget<GridView>(
      find.byKey(const ValueKey('work-5-7-calendar-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 7);
    expect(find.text('Aug 24 – Aug 30, 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('Aug 31 – Sep 6, 2026'), findsOneWidget);
    expect(selected, DateTime(2026, 8, 29));
    expect(tester.takeException(), isNull);
  });

  testWidgets('date click is the only operation that selects a day', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: WorkMonthCalendar(
            selectedDay: DateTime(2026, 8, 29),
            onDaySelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('work-calendar-day-2026-8-18')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 8, 18));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Month navigation keeps Week focused in the visible month', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: WorkMonthCalendar(
              selectedDay: DateTime(2026, 8, 29),
              onDaySelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-view-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Sep 28 – Oct 4, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unboxed date grows without clipping accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: WorkMonthCalendar(
                  selectedDay: DateTime(2026, 8, 29),
                  onDaySelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final date = tester.getSize(
      find.byKey(const ValueKey('module-calendar-day-number-2026-8-29')),
    );
    expect(date.width, greaterThan(24));
    // Plain centered date text, not a bordered square.
    expect(date.height, greaterThan(24));
    expect(tester.takeException(), isNull);
  });
}
