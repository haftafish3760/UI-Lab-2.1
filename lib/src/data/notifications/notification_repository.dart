import 'notification_records.dart';
import 'notification_terms.dart';

enum NotificationReadScope { own, team, company }

class NotificationAccess {
  NotificationAccess.own({
    required this.organizationId,
    required this.employeeId,
  }) : scope = NotificationReadScope.own,
       visibleEmployeeIds = {employeeId};

  NotificationAccess.team({
    required this.organizationId,
    required this.employeeId,
    required Set<String> teamEmployeeIds,
  }) : scope = NotificationReadScope.team,
       visibleEmployeeIds = {...teamEmployeeIds, employeeId};

  NotificationAccess.company({
    required this.organizationId,
    required this.employeeId,
  }) : scope = NotificationReadScope.company,
       visibleEmployeeIds = const {};

  final String organizationId;
  final String employeeId;
  final NotificationReadScope scope;
  final Set<String> visibleEmployeeIds;

  bool allowsEvent(StoredNotificationEvent event) =>
      event.organizationId == organizationId &&
      (scope == NotificationReadScope.company ||
          visibleEmployeeIds.contains(event.recipientEmployeeId));

  bool allowsDelivery(StoredNotificationDelivery delivery) =>
      delivery.organizationId == organizationId &&
      (scope == NotificationReadScope.company ||
          visibleEmployeeIds.contains(delivery.recipientEmployeeId));
}

class NotificationEventQuery {
  const NotificationEventQuery({
    required this.access,
    this.availableAtUtc,
    this.category,
    this.kind,
    this.module,
    this.sourceType,
    this.sourceRecordId,
    this.channel,
    this.readState,
    this.includeExpired = false,
  });

  final NotificationAccess access;
  final DateTime? availableAtUtc;
  final NotificationEventCategory? category;
  final NotificationEventKind? kind;
  final NotificationSourceModule? module;
  final NotificationSourceType? sourceType;
  final String? sourceRecordId;
  final NotificationDeliveryChannel? channel;
  final NotificationReadState? readState;
  final bool includeExpired;

  bool matches(StoredNotificationEvent event) {
    if (!access.allowsEvent(event)) return false;
    if (availableAtUtc != null) {
      if (event.scheduledAtUtc.isAfter(availableAtUtc!.toUtc())) return false;
      if (!includeExpired &&
          event.expiresAtUtc != null &&
          !event.expiresAtUtc!.isAfter(availableAtUtc!.toUtc())) {
        return false;
      }
    }
    if (category != null && event.category != category) return false;
    if (kind != null && event.kind != kind) return false;
    if (module != null && event.route.module != module) return false;
    if (sourceType != null && event.route.sourceType != sourceType) {
      return false;
    }
    if (sourceRecordId != null &&
        event.route.sourceRecordId != sourceRecordId) {
      return false;
    }
    if (channel != null && !event.channels.contains(channel)) return false;
    if (readState != null && event.readState != readState) return false;
    return true;
  }
}

class NotificationDeliveryQuery {
  const NotificationDeliveryQuery({
    required this.access,
    this.fromInclusiveUtc,
    this.toExclusiveUtc,
    this.channel,
    this.state,
    this.notificationId,
  });

  final NotificationAccess access;
  final DateTime? fromInclusiveUtc;
  final DateTime? toExclusiveUtc;
  final NotificationDeliveryChannel? channel;
  final NotificationDeliveryState? state;
  final String? notificationId;

  bool matches(StoredNotificationDelivery delivery) {
    if (!access.allowsDelivery(delivery)) return false;
    if (fromInclusiveUtc != null &&
        delivery.scheduledAtUtc.isBefore(fromInclusiveUtc!.toUtc())) {
      return false;
    }
    if (toExclusiveUtc != null &&
        !delivery.scheduledAtUtc.isBefore(toExclusiveUtc!.toUtc())) {
      return false;
    }
    if (channel != null && delivery.channel != channel) return false;
    if (state != null && delivery.state != state) return false;
    if (notificationId != null && delivery.notificationId != notificationId) {
      return false;
    }
    return true;
  }
}

class NotificationMutationContext {
  NotificationMutationContext({
    required this.actorId,
    required this.permissionRevision,
    required DateTime occurredAtUtc,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc();

  final String actorId;
  final String permissionRevision;
  final DateTime occurredAtUtc;
  final String? note;

  NotificationAuditEvent audit({
    required NotificationAuditAction action,
    required int? fromRevision,
    required int toRevision,
  }) => NotificationAuditEvent(
    action: action,
    actorId: actorId,
    permissionRevision: permissionRevision,
    occurredAtUtc: occurredAtUtc,
    fromRevision: fromRevision,
    toRevision: toRevision,
    note: note,
  );
}

class NotificationPublishResult {
  const NotificationPublishResult({
    required this.event,
    required this.deliveries,
    required this.wasAlreadyPublished,
  });

  final StoredNotificationEvent event;
  final List<StoredNotificationDelivery> deliveries;
  final bool wasAlreadyPublished;
}

abstract interface class NotificationRepository {
  Future<List<StoredNotificationEvent>> queryEvents(
    NotificationEventQuery query,
  );

  Future<StoredNotificationEvent?> findEvent({
    required String notificationId,
    required NotificationAccess access,
  });

  Future<List<StoredNotificationDelivery>> queryDeliveries(
    NotificationDeliveryQuery query,
  );

  Future<StoredNotificationDelivery?> findDelivery({
    required String deliveryId,
    required NotificationAccess access,
  });

  Future<NotificationPublishResult> publish({
    required StoredNotificationEvent event,
    required List<StoredNotificationDelivery> deliveries,
    required NotificationMutationContext context,
  });

  Future<StoredNotificationEvent> changeReadState({
    required String notificationId,
    required NotificationReadState state,
    required int expectedRevision,
    required NotificationMutationContext context,
  });

  Future<StoredNotificationDelivery> updateDelivery({
    required String deliveryId,
    required NotificationDeliveryState state,
    required int expectedRevision,
    required NotificationMutationContext context,
    String? adapterReference,
    String? failureCode,
  });
}

sealed class NotificationRepositoryException implements Exception {
  const NotificationRepositoryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NotificationConflictException extends NotificationRepositoryException {
  const NotificationConflictException(super.message);
}

class NotificationNotFoundException extends NotificationRepositoryException {
  const NotificationNotFoundException(super.message);
}

class NotificationInvalidTransitionException
    extends NotificationRepositoryException {
  const NotificationInvalidTransitionException(super.message);
}

class NotificationStorageException extends NotificationRepositoryException {
  const NotificationStorageException(super.message);
}

class NotificationStorageCorruptionException
    extends NotificationRepositoryException {
  const NotificationStorageCorruptionException(super.message);
}

class NotificationPermissionDeniedException
    extends NotificationRepositoryException {
  const NotificationPermissionDeniedException(super.message);
}
