import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/notifications/notification_records.dart';

class DashboardNotificationCopy {
  const DashboardNotificationCopy({required this.title, required this.message});

  final String title;
  final String message;
}

DashboardNotificationCopy dashboardNotificationCopy(
  BuildContext context,
  StoredNotificationEvent event, {
  required DateTime asOf,
}) {
  final arguments = event.content.arguments;
  final title = switch (event.content.titleKey) {
    'notification.recurringExpense.title' =>
      arguments['title'] ?? context.l10n.notificationsTitle,
    _ => context.l10n.notificationsTitle,
  };
  final message = switch (event.content.messageKey) {
    'notification.recurringExpense.due' => _dueMessage(
      context,
      arguments['dueOn'],
      asOf,
    ),
    _ => context.l10n.notificationsDescription,
  };
  return DashboardNotificationCopy(title: title, message: message);
}

String _dueMessage(BuildContext context, String? dueOn, DateTime asOf) {
  final due = dueOn == null ? null : DateTime.tryParse(dueOn);
  if (due == null) return context.l10n.notificationsDescription;
  final difference = _dateOnly(due).difference(_dateOnly(asOf)).inDays;
  if (difference < 0) {
    return context.l10n.notificationDaysOverdue(-difference);
  }
  if (difference == 0) return context.l10n.notificationDueToday;
  if (difference == 1) return context.l10n.notificationDueTomorrow;
  return context.l10n.notificationDueInDays(difference);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
