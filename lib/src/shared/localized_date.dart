import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats an operational date in the active display locale.
///
/// The flags preserve the four date densities used by operating screens while
/// leaving date order, punctuation, and language to the locale.
String operationalDateLabel(
  BuildContext context,
  DateTime day, {
  bool weekday = true,
  bool year = true,
}) {
  final locale = Localizations.localeOf(context).toString();
  return switch ((weekday, year)) {
    (true, true) => DateFormat.yMMMMEEEEd(locale).format(day),
    (true, false) => DateFormat.MMMMEEEEd(locale).format(day),
    (false, true) => DateFormat.yMMMMd(locale).format(day),
    (false, false) => DateFormat.MMMMd(locale).format(day),
  };
}

/// Formats a compact numeric date with the active Material locale rules.
String operationalShortDateLabel(BuildContext context, DateTime day) =>
    MaterialLocalizations.of(context).formatShortDate(day);

/// Formats an inclusive compact date range without imposing U.S. ordering.
String operationalDateRangeLabel(
  BuildContext context,
  DateTime fromInclusive,
  DateTime toInclusive,
) =>
    '${operationalShortDateLabel(context, fromInclusive)}'
    '–${operationalShortDateLabel(context, toInclusive)}';
