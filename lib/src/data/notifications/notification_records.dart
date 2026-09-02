import 'package:flutter/foundation.dart';

import 'notification_terms.dart';

const _unchangedNotificationValue = Object();

@immutable
class StoredNotificationEvent {
  StoredNotificationEvent({
    required this.notificationId,
    required this.deduplicationKey,
    required this.organizationId,
    required this.recipientEmployeeId,
    required this.category,
    required this.kind,
    required this.route,
    required this.content,
    required DateTime scheduledAtUtc,
    required Set<NotificationDeliveryChannel> channels,
    required this.readState,
    required this.lifecycle,
    List<NotificationAuditEvent> auditTrail = const [],
    DateTime? expiresAtUtc,
  }) : scheduledAtUtc = scheduledAtUtc.toUtc(),
       expiresAtUtc = expiresAtUtc?.toUtc(),
       channels = Set.unmodifiable(channels),
       auditTrail = List.unmodifiable(auditTrail) {
    requireNotificationText(notificationId, 'notificationId');
    requireNotificationText(deduplicationKey, 'deduplicationKey');
    requireNotificationText(organizationId, 'organizationId');
    requireNotificationText(recipientEmployeeId, 'recipientEmployeeId');
    if (channels.isEmpty) {
      throw ArgumentError.value(channels, 'channels', 'Cannot be empty.');
    }
    if (this.expiresAtUtc != null &&
        !this.expiresAtUtc!.isAfter(this.scheduledAtUtc)) {
      throw ArgumentError.value(
        expiresAtUtc,
        'expiresAtUtc',
        'Must be later than scheduledAtUtc.',
      );
    }
  }

  final String notificationId;
  final String deduplicationKey;
  final String organizationId;
  final String recipientEmployeeId;
  final NotificationEventCategory category;
  final NotificationEventKind kind;
  final NotificationSourceRoute route;
  final NotificationContent content;
  final DateTime scheduledAtUtc;
  final DateTime? expiresAtUtc;
  final Set<NotificationDeliveryChannel> channels;
  final NotificationReadState readState;
  final NotificationLifecycle lifecycle;
  final List<NotificationAuditEvent> auditTrail;

  bool isAvailableAt(DateTime asOfUtc) {
    final asOf = asOfUtc.toUtc();
    return !scheduledAtUtc.isAfter(asOf) &&
        (expiresAtUtc == null || expiresAtUtc!.isAfter(asOf));
  }

  bool get isUnread => readState == NotificationReadState.unread;

  StoredNotificationEvent copyWith({
    NotificationReadState? readState,
    NotificationLifecycle? lifecycle,
    List<NotificationAuditEvent>? auditTrail,
  }) => StoredNotificationEvent(
    notificationId: notificationId,
    deduplicationKey: deduplicationKey,
    organizationId: organizationId,
    recipientEmployeeId: recipientEmployeeId,
    category: category,
    kind: kind,
    route: route,
    content: content,
    scheduledAtUtc: scheduledAtUtc,
    expiresAtUtc: expiresAtUtc,
    channels: channels,
    readState: readState ?? this.readState,
    lifecycle: lifecycle ?? this.lifecycle,
    auditTrail: auditTrail ?? this.auditTrail,
  );

  Map<String, Object?> toJson() => {
    'notificationId': notificationId,
    'deduplicationKey': deduplicationKey,
    'organizationId': organizationId,
    'recipientEmployeeId': recipientEmployeeId,
    'category': category.name,
    'kind': kind.name,
    'route': route.toJson(),
    'content': content.toJson(),
    'scheduledAtUtc': scheduledAtUtc.toIso8601String(),
    'expiresAtUtc': expiresAtUtc?.toIso8601String(),
    'channels': channels.map((channel) => channel.name).toList()..sort(),
    'readState': readState.name,
    'lifecycle': lifecycle.toJson(),
    'auditTrail': auditTrail.map((event) => event.toJson()).toList(),
  };

  factory StoredNotificationEvent.fromJson(Map<String, Object?> json) =>
      StoredNotificationEvent(
        notificationId: requiredNotificationString(json, 'notificationId'),
        deduplicationKey: requiredNotificationString(json, 'deduplicationKey'),
        organizationId: requiredNotificationString(json, 'organizationId'),
        recipientEmployeeId: requiredNotificationString(
          json,
          'recipientEmployeeId',
        ),
        category: NotificationEventCategory.values.byName(
          requiredNotificationString(json, 'category'),
        ),
        kind: NotificationEventKind.values.byName(
          requiredNotificationString(json, 'kind'),
        ),
        route: NotificationSourceRoute.fromJson(
          requiredNotificationMap(json, 'route'),
        ),
        content: NotificationContent.fromJson(
          requiredNotificationMap(json, 'content'),
        ),
        scheduledAtUtc: requiredNotificationUtc(json, 'scheduledAtUtc'),
        expiresAtUtc: json['expiresAtUtc'] is String
            ? DateTime.parse(json['expiresAtUtc']! as String).toUtc()
            : null,
        channels: requiredNotificationList(json, 'channels')
            .map(
              (value) =>
                  NotificationDeliveryChannel.values.byName(value as String),
            )
            .toSet(),
        readState: NotificationReadState.values.byName(
          requiredNotificationString(json, 'readState'),
        ),
        lifecycle: NotificationLifecycle.fromJson(
          requiredNotificationMap(json, 'lifecycle'),
        ),
        auditTrail: requiredNotificationList(json, 'auditTrail')
            .map(
              (value) => NotificationAuditEvent.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      );
}

@immutable
class StoredNotificationDelivery {
  StoredNotificationDelivery({
    required this.deliveryId,
    required this.notificationId,
    required this.organizationId,
    required this.recipientEmployeeId,
    required this.channel,
    required DateTime scheduledAtUtc,
    required this.state,
    required this.attemptCount,
    required this.lifecycle,
    List<NotificationAuditEvent> auditTrail = const [],
    this.adapterReference,
    this.failureCode,
    DateTime? lastAttemptAtUtc,
  }) : scheduledAtUtc = scheduledAtUtc.toUtc(),
       lastAttemptAtUtc = lastAttemptAtUtc?.toUtc(),
       auditTrail = List.unmodifiable(auditTrail) {
    requireNotificationText(deliveryId, 'deliveryId');
    requireNotificationText(notificationId, 'notificationId');
    requireNotificationText(organizationId, 'organizationId');
    requireNotificationText(recipientEmployeeId, 'recipientEmployeeId');
    if (channel == NotificationDeliveryChannel.inApp) {
      throw const FormatException(
        'In-app visibility is notification state, not platform delivery.',
      );
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(
        attemptCount,
        'attemptCount',
        'Cannot be negative.',
      );
    }
    if (adapterReference != null) {
      requireNotificationText(adapterReference!, 'adapterReference');
    }
    if (failureCode != null) {
      requireNotificationText(failureCode!, 'failureCode');
    }
    if (state == NotificationDeliveryState.failed && failureCode == null) {
      throw const FormatException('Failed delivery requires a failure code.');
    }
    if (state != NotificationDeliveryState.failed && failureCode != null) {
      throw const FormatException(
        'Only a failed delivery can retain a failure code.',
      );
    }
  }

  final String deliveryId;
  final String notificationId;
  final String organizationId;
  final String recipientEmployeeId;
  final NotificationDeliveryChannel channel;
  final DateTime scheduledAtUtc;
  final NotificationDeliveryState state;
  final int attemptCount;
  final DateTime? lastAttemptAtUtc;
  final String? adapterReference;
  final String? failureCode;
  final NotificationLifecycle lifecycle;
  final List<NotificationAuditEvent> auditTrail;

  StoredNotificationDelivery copyWith({
    NotificationDeliveryState? state,
    int? attemptCount,
    Object? lastAttemptAtUtc = _unchangedNotificationValue,
    Object? adapterReference = _unchangedNotificationValue,
    Object? failureCode = _unchangedNotificationValue,
    NotificationLifecycle? lifecycle,
    List<NotificationAuditEvent>? auditTrail,
  }) => StoredNotificationDelivery(
    deliveryId: deliveryId,
    notificationId: notificationId,
    organizationId: organizationId,
    recipientEmployeeId: recipientEmployeeId,
    channel: channel,
    scheduledAtUtc: scheduledAtUtc,
    state: state ?? this.state,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAtUtc: identical(lastAttemptAtUtc, _unchangedNotificationValue)
        ? this.lastAttemptAtUtc
        : lastAttemptAtUtc as DateTime?,
    adapterReference: identical(adapterReference, _unchangedNotificationValue)
        ? this.adapterReference
        : adapterReference as String?,
    failureCode: identical(failureCode, _unchangedNotificationValue)
        ? this.failureCode
        : failureCode as String?,
    lifecycle: lifecycle ?? this.lifecycle,
    auditTrail: auditTrail ?? this.auditTrail,
  );

  Map<String, Object?> toJson() => {
    'deliveryId': deliveryId,
    'notificationId': notificationId,
    'organizationId': organizationId,
    'recipientEmployeeId': recipientEmployeeId,
    'channel': channel.name,
    'scheduledAtUtc': scheduledAtUtc.toIso8601String(),
    'state': state.name,
    'attemptCount': attemptCount,
    'lastAttemptAtUtc': lastAttemptAtUtc?.toIso8601String(),
    'adapterReference': adapterReference,
    'failureCode': failureCode,
    'lifecycle': lifecycle.toJson(),
    'auditTrail': auditTrail.map((event) => event.toJson()).toList(),
  };

  factory StoredNotificationDelivery.fromJson(Map<String, Object?> json) =>
      StoredNotificationDelivery(
        deliveryId: requiredNotificationString(json, 'deliveryId'),
        notificationId: requiredNotificationString(json, 'notificationId'),
        organizationId: requiredNotificationString(json, 'organizationId'),
        recipientEmployeeId: requiredNotificationString(
          json,
          'recipientEmployeeId',
        ),
        channel: NotificationDeliveryChannel.values.byName(
          requiredNotificationString(json, 'channel'),
        ),
        scheduledAtUtc: requiredNotificationUtc(json, 'scheduledAtUtc'),
        state: NotificationDeliveryState.values.byName(
          requiredNotificationString(json, 'state'),
        ),
        attemptCount: requiredNotificationInt(json, 'attemptCount'),
        lastAttemptAtUtc: json['lastAttemptAtUtc'] is String
            ? DateTime.parse(json['lastAttemptAtUtc']! as String).toUtc()
            : null,
        adapterReference: json['adapterReference'] as String?,
        failureCode: json['failureCode'] as String?,
        lifecycle: NotificationLifecycle.fromJson(
          requiredNotificationMap(json, 'lifecycle'),
        ),
        auditTrail: requiredNotificationList(json, 'auditTrail')
            .map(
              (value) => NotificationAuditEvent.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      );
}
