import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/module_month_calendar.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('calendar header keeps readable ink in ${theme.brightness}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: WorkMonthCalendar(
              selectedDay: DateTime(2026, 9, 12),
              onDaySelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
        'September 2026',
      ]) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style!.color, const Color(0xFFF7FAF4));
      }
      final toggle = tester.widget<TextButton>(
        find.byKey(const ValueKey('calendar-view-toggle')),
      );
      expect(
        toggle.style!.foregroundColor!.resolve({}),
        const Color(0xFFF7FAF4),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
