import '../expenses/expense_workflow_models.dart';
import 'authorized_notification_service.dart';
import 'notification_demo_policy.dart';
import 'notification_records.dart';
import 'notification_terms.dart';

typedef ScheduledExpenseProvider = List<ScheduledExpenseRecord> Function();
typedef ScheduledExpenseOccurrenceProvider =
    List<ScheduledExpenseOccurrence> Function();

/// Publishes the latest due reminder for every open recurring occurrence.
///
/// Providers are authorized projections in a platform session and explicit
/// in-memory fixtures in isolated tests. Publication happens only after a
/// source load or mutation commits, never while the notification list is read.
class RecurringExpenseNotificationPublisher {
  RecurringExpenseNotificationPublisher(
    this._service,
    this._scheduledExpenses,
    this._occurrences,
  );

  final AuthorizedNotificationService _service;
  final ScheduledExpenseProvider _scheduledExpenses;
  final ScheduledExpenseOccurrenceProvider _occurrences;

  Future<void> synchronize({required DateTime asOf}) async {
    final nowUtc = asOf.toUtc();
    final localNow = asOf.toLocal();
    final permissions = demoNotificationPublisherPermissions();
    final templates = {
      for (final template in _scheduledExpenses()) template.id: template,
    };
    final activeNotificationIds = <String>{};

    for (final occurrence in _occurrences()) {
      final template = templates[occurrence.templateId];
      if (template == null || !template.isActive || !occurrence.isOpen) {
        continue;
      }
      final channels = _channelsFor(template);
      if (channels.isEmpty) continue;
      for (final reminder in _activeReminders(template, occurrence, localNow)) {
        final notificationId =
            '${occurrence.id}:reminder:${reminder.daysBefore}';
        activeNotificationIds.add(notificationId);
        final scheduledAtUtc = reminder.scheduledFor.toUtc();
        final event = StoredNotificationEvent(
          notificationId: notificationId,
          deduplicationKey:
              'recurring-expense:${occurrence.id}:${reminder.daysBefore}:${template.ownerEmployeeId}',
          organizationId: demoNotificationOrganizationId,
          recipientEmployeeId: template.ownerEmployeeId,
          category: NotificationEventCategory.reminder,
          kind: NotificationEventKind.recurringExpenseDue,
          route: NotificationSourceRoute(
            module: NotificationSourceModule.expenses,
            sourceType: NotificationSourceType.recurringExpense,
            sourceRecordId: template.id,
            sourceChildId: occurrence.id,
          ),
          content: NotificationContent(
            titleKey: 'notification.recurringExpense.title',
            messageKey: 'notification.recurringExpense.due',
            arguments: {
              'title': template.title,
              'dueOn': _dateKey(occurrence.dueOn),
            },
          ),
          scheduledAtUtc: scheduledAtUtc,
          channels: channels,
          readState: NotificationReadState.unread,
          lifecycle: NotificationLifecycle(
            revision: 1,
            createdAtUtc: scheduledAtUtc,
            updatedAtUtc: scheduledAtUtc,
          ),
        );
        await _service.publish(
          event: event,
          deliveries: _deliveriesFor(event),
          permissions: permissions,
          occurredAtUtc: nowUtc,
          note: 'Recurring Expense reminder was scheduled.',
        );
      }
    }

    final existing = await _service.queryEvents(
      permissions: permissions,
      sourceType: NotificationSourceType.recurringExpense,
      includeExpired: true,
    );
    for (final event in existing) {
      if (activeNotificationIds.contains(event.notificationId) ||
          event.readState == NotificationReadState.dismissed) {
        continue;
      }
      await _service.changeReadState(
        notificationId: event.notificationId,
        state: NotificationReadState.dismissed,
        expectedRevision: event.lifecycle.revision,
        permissions: permissions,
        occurredAtUtc: nowUtc,
        note: 'Superseded or source occurrence is no longer open.',
      );
    }
  }
}

List<({int daysBefore, DateTime scheduledFor})> _activeReminders(
  ScheduledExpenseRecord template,
  ScheduledExpenseOccurrence occurrence,
  DateTime asOf,
) {
  final candidates =
      template.reminderDaysBefore
          .toSet()
          .map(
            (daysBefore) => (
              daysBefore: daysBefore,
              scheduledFor: _reminderTime(
                occurrence.dueOn.subtract(Duration(days: daysBefore)),
              ),
            ),
          )
          .toList()
        ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  final due = candidates
      .where((candidate) => !candidate.scheduledFor.isAfter(asOf))
      .toList();
  final future = candidates
      .where((candidate) => candidate.scheduledFor.isAfter(asOf))
      .toList();
  return [if (due.isNotEmpty) due.last, ...future];
}

Set<NotificationDeliveryChannel> _channelsFor(
  ScheduledExpenseRecord template,
) => {
  if (template.inAppReminder) NotificationDeliveryChannel.inApp,
  if (template.pushReminder) NotificationDeliveryChannel.push,
  if (template.soundReminder) NotificationDeliveryChannel.sound,
};

List<StoredNotificationDelivery> _deliveriesFor(
  StoredNotificationEvent event,
) => event.channels
    .where((channel) => channel != NotificationDeliveryChannel.inApp)
    .map(
      (channel) => StoredNotificationDelivery(
        deliveryId: '${event.notificationId}:${channel.name}',
        notificationId: event.notificationId,
        organizationId: event.organizationId,
        recipientEmployeeId: event.recipientEmployeeId,
        channel: channel,
        scheduledAtUtc: event.scheduledAtUtc,
        state: NotificationDeliveryState.pending,
        attemptCount: 0,
        lifecycle: NotificationLifecycle(
          revision: 1,
          createdAtUtc: event.scheduledAtUtc,
          updatedAtUtc: event.scheduledAtUtc,
        ),
      ),
    )
    .toList();

DateTime _reminderTime(DateTime value) =>
    DateTime(value.year, value.month, value.day, 9);

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
