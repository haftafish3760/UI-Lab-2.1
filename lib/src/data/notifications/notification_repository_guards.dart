import 'dart:convert';

import 'notification_records.dart';
import 'notification_repository.dart';
import 'notification_terms.dart';

bool sameNotificationDefinition(
  StoredNotificationEvent left,
  StoredNotificationEvent right,
) {
  Map<String, Object?> definition(StoredNotificationEvent event) {
    final json = Map<String, Object?>.from(event.toJson());
    json.remove('readState');
    json.remove('lifecycle');
    json.remove('auditTrail');
    return json;
  }

  return jsonEncode(definition(left)) == jsonEncode(definition(right));
}

bool sameDeliveryDefinition(
  StoredNotificationDelivery left,
  StoredNotificationDelivery right,
) =>
    left.deliveryId == right.deliveryId &&
    left.notificationId == right.notificationId &&
    left.organizationId == right.organizationId &&
    left.recipientEmployeeId == right.recipientEmployeeId &&
    left.channel == right.channel &&
    left.scheduledAtUtc == right.scheduledAtUtc;

NotificationAuditAction auditActionForReadState(
  NotificationReadState current,
  NotificationReadState next,
) {
  if (next == NotificationReadState.read) return NotificationAuditAction.read;
  if (next == NotificationReadState.dismissed) {
    return NotificationAuditAction.dismissed;
  }
  if (next == NotificationReadState.unread && current != next) {
    return NotificationAuditAction.restored;
  }
  throw const NotificationInvalidTransitionException(
    'That notification read-state transition is not allowed.',
  );
}

void validateDeliveryTransition(
  NotificationDeliveryState current,
  NotificationDeliveryState next,
) {
  final allowed = switch (current) {
    NotificationDeliveryState.pending => {
      NotificationDeliveryState.scheduled,
      NotificationDeliveryState.failed,
      NotificationDeliveryState.cancelled,
    },
    NotificationDeliveryState.scheduled => {
      NotificationDeliveryState.delivered,
      NotificationDeliveryState.failed,
      NotificationDeliveryState.cancelled,
    },
    NotificationDeliveryState.failed => {
      NotificationDeliveryState.scheduled,
      NotificationDeliveryState.cancelled,
    },
    NotificationDeliveryState.delivered ||
    NotificationDeliveryState.cancelled => const <NotificationDeliveryState>{},
  };
  if (!allowed.contains(next)) {
    throw NotificationInvalidTransitionException(
      'Delivery cannot change from ${current.name} to ${next.name}.',
    );
  }
}

NotificationAuditAction auditActionForDelivery(
  NotificationDeliveryState state,
) => switch (state) {
  NotificationDeliveryState.scheduled =>
    NotificationAuditAction.deliveryScheduled,
  NotificationDeliveryState.delivered =>
    NotificationAuditAction.deliverySucceeded,
  NotificationDeliveryState.failed => NotificationAuditAction.deliveryFailed,
  NotificationDeliveryState.cancelled =>
    NotificationAuditAction.deliveryCancelled,
  NotificationDeliveryState.pending =>
    throw const NotificationInvalidTransitionException(
      'A delivery cannot transition back to pending.',
    ),
};

int compareNotificationEvents(
  StoredNotificationEvent left,
  StoredNotificationEvent right,
) {
  final scheduled = right.scheduledAtUtc.compareTo(left.scheduledAtUtc);
  return scheduled != 0
      ? scheduled
      : left.notificationId.compareTo(right.notificationId);
}

int compareNotificationDeliveries(
  StoredNotificationDelivery left,
  StoredNotificationDelivery right,
) {
  final scheduled = left.scheduledAtUtc.compareTo(right.scheduledAtUtc);
  return scheduled != 0
      ? scheduled
      : left.deliveryId.compareTo(right.deliveryId);
}
