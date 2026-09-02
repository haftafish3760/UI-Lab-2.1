import 'package:flutter/material.dart';

import '../../data/notifications/notification_records.dart';
import '../../data/notifications/notification_terms.dart';
import '../expenses/expense_permissions.dart';
import '../expenses/scheduled_expense_detail_screen.dart';

Route<void>? notificationSourceRoute(
  StoredNotificationEvent event, {
  required ExpensePermissions expensePermissions,
}) {
  final route = event.route;
  if (route.module == NotificationSourceModule.expenses &&
      route.sourceType == NotificationSourceType.recurringExpense) {
    return MaterialPageRoute<void>(
      builder: (_) => ScheduledExpenseDetailScreen(
        recordId: route.sourceRecordId,
        permissions: expensePermissions,
      ),
    );
  }
  return null;
}
