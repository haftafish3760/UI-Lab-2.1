import 'package:flutter/material.dart';

/// End is exclusive, including when a week crosses a month or year.
DateTimeRange expensePeriodRange(
  String period,
  DateTime anchor,
  int firstWeekday,
) {
  if (firstWeekday < 1 || firstWeekday > 7) {
    throw ArgumentError.value(firstWeekday, 'firstWeekday');
  }
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  final week = DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - firstWeekday + 7) % 7,
  );
  return switch (period) {
    'Day' => DateTimeRange(
      start: day,
      end: DateTime(day.year, day.month, day.day + 1),
    ),
    'Week' => DateTimeRange(
      start: week,
      end: DateTime(week.year, week.month, week.day + 7),
    ),
    'Month' => DateTimeRange(
      start: DateTime(day.year, day.month),
      end: DateTime(day.year, day.month + 1),
    ),
    'Year' => DateTimeRange(
      start: DateTime(day.year),
      end: DateTime(day.year + 1),
    ),
    'Quarter' => DateTimeRange(
      start: DateTime(day.year, ((day.month - 1) ~/ 3) * 3 + 1),
      end: DateTime(day.year, ((day.month - 1) ~/ 3) * 3 + 4),
    ),
    'Year to date' => DateTimeRange(
      start: DateTime(day.year),
      end: DateTime(day.year, day.month, day.day + 1),
    ),
    _ => throw ArgumentError.value(period, 'period'),
  };
}
