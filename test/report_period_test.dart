import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/report_period.dart';

void main() {
  test('calendar quarter and rolling ranges remain distinct', () {
    final today = DateTime(2026, 8, 30);
    final quarter = ReportPeriod.thisCalendarQuarter.rangeFor(today);
    final priorQuarter = ReportPeriod.previousCalendarQuarter.rangeFor(today);
    final rolling = ReportPeriod.previous90Days.rangeFor(today);

    expect(quarter.fromInclusive, DateTime(2026, 7));
    expect(quarter.toExclusive, DateTime(2026, 10));
    expect(priorQuarter.fromInclusive, DateTime(2026, 4));
    expect(priorQuarter.toExclusive, DateTime(2026, 7));
    expect(rolling.fromInclusive, today.subtract(const Duration(days: 89)));
    expect(rolling.toExclusive, DateTime(2026, 8, 31));
  });

  test('previous 12 months uses the same calendar day when possible', () {
    final range = ReportPeriod.previous12Months.rangeFor(DateTime(2026, 8, 30));
    expect(range.fromInclusive, DateTime(2025, 8, 30));
    expect(range.toExclusive, DateTime(2026, 8, 31));

    final leapRange = ReportPeriod.previous12Months.rangeFor(
      DateTime(2024, 2, 29),
    );
    expect(leapRange.fromInclusive, DateTime(2023, 2, 28));
  });
}
