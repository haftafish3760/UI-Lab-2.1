import 'notification_records.dart';
import 'notification_terms.dart';

class NotificationSnapshotData {
  const NotificationSnapshotData({
    required this.events,
    required this.deliveries,
  });

  const NotificationSnapshotData.empty()
    : events = const [],
      deliveries = const [];

  final List<StoredNotificationEvent> events;
  final List<StoredNotificationDelivery> deliveries;

  Map<String, Object?> toJson() => {
    'events': events.map((event) => event.toJson()).toList(),
    'deliveries': deliveries.map((delivery) => delivery.toJson()).toList(),
  };

  factory NotificationSnapshotData.fromJson(Map<String, Object?> json) {
    final events = requiredNotificationList(json, 'events')
        .map(
          (value) => StoredNotificationEvent.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList();
    final deliveries = requiredNotificationList(json, 'deliveries')
        .map(
          (value) => StoredNotificationDelivery.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList();
    _validateSnapshot(events, deliveries);
    return NotificationSnapshotData(
      events: List.unmodifiable(events),
      deliveries: List.unmodifiable(deliveries),
    );
  }
}

void _validateSnapshot(
  List<StoredNotificationEvent> events,
  List<StoredNotificationDelivery> deliveries,
) {
  final eventIds = <String>{};
  final deduplicationKeys = <String>{};
  for (final event in events) {
    if (!eventIds.add(event.notificationId)) {
      throw const FormatException('Duplicate notification identity.');
    }
    final scopedKey = '${event.organizationId}:${event.deduplicationKey}';
    if (!deduplicationKeys.add(scopedKey)) {
      throw const FormatException('Duplicate notification deduplication key.');
    }
  }
  final eventsById = {for (final event in events) event.notificationId: event};
  final deliveryIds = <String>{};
  for (final delivery in deliveries) {
    if (!deliveryIds.add(delivery.deliveryId)) {
      throw const FormatException('Duplicate notification delivery identity.');
    }
    final event = eventsById[delivery.notificationId];
    if (event == null ||
        event.organizationId != delivery.organizationId ||
        event.recipientEmployeeId != delivery.recipientEmployeeId ||
        !event.channels.contains(delivery.channel)) {
      throw const FormatException('Notification delivery link is invalid.');
    }
  }
}
