import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every current module calendar delegates to the shared grid', () {
    const calendarOwners = <String, String>{
      'Dashboard': 'lib/src/screens/dashboard/dashboard_calendar.dart',
      'Work': 'lib/src/screens/work/work_home_widgets.dart',
      'Jobs': 'lib/src/screens/work/job_list_workspace_screen.dart',
      'Estimates': 'lib/src/screens/work/estimate_workspace_screen.dart',
      'Invoices': 'lib/src/screens/work/invoice_workspace_screen.dart',
      'Payments': 'lib/src/screens/work/payments_screen.dart',
      'Expenses': 'lib/src/screens/expenses/expenses_collection_widgets.dart',
      'Materials': 'lib/src/screens/inventory/inventory_widgets.dart',
    };

    for (final entry in calendarOwners.entries) {
      final source = File(entry.value).readAsStringSync();
      expect(
        source,
        contains('WorkMonthCalendar('),
        reason: '${entry.key} must use the shared calendar component.',
      );
      expect(
        source,
        contains('maximumWidth:'),
        reason: '${entry.key} must pass the shared operations lane width.',
      );
    }
  });
}
