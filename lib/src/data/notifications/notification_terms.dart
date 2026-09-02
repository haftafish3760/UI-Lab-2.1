import 'package:flutter/foundation.dart';

enum NotificationEventCategory {
  reminder,
  assignment,
  schedule,
  approval,
  payment,
  recordUpdate,
  storage,
  sync,
}

enum NotificationEventKind {
  recurringExpenseDue,
  workAssigned,
  workRescheduled,
  expenseSubmitted,
  estimateSubmitted,
  invoiceSubmitted,
  paymentRecorded,
  materialStockWarning,
  storageRecovered,
  syncFailed,
}

enum NotificationSourceModule {
  dashboard,
  work,
  expenses,
  materials,
  maintenance,
}

enum NotificationSourceType {
  recurringExpense,
  job,
  estimate,
  invoice,
  expense,
  payment,
  material,
  storage,
  sync,
}

enum NotificationDeliveryChannel { inApp, push, sound }

enum NotificationReadState { unread, read, dismissed }

enum NotificationDeliveryState {
  pending,
  scheduled,
  delivered,
  failed,
  cancelled,
}

enum NotificationAuditAction {
  created,
  read,
  dismissed,
  restored,
  deliveryScheduled,
  deliverySucceeded,
  deliveryFailed,
  deliveryCancelled,
}

@immutable
class NotificationSourceRoute {
  NotificationSourceRoute({
    required this.module,
    required this.sourceType,
    required this.sourceRecordId,
    this.sourceChildId,
  }) {
    requireNotificationText(sourceRecordId, 'sourceRecordId');
    if (sourceChildId != null) {
      requireNotificationText(sourceChildId!, 'sourceChildId');
    }
  }

  final NotificationSourceModule module;
  final NotificationSourceType sourceType;
  final String sourceRecordId;
  final String? sourceChildId;

  Map<String, Object?> toJson() => {
    'module': module.name,
    'sourceType': sourceType.name,
    'sourceRecordId': sourceRecordId,
    'sourceChildId': sourceChildId,
  };

  factory NotificationSourceRoute.fromJson(Map<String, Object?> json) =>
      NotificationSourceRoute(
        module: NotificationSourceModule.values.byName(
          requiredNotificationString(json, 'module'),
        ),
        sourceType: NotificationSourceType.values.byName(
          requiredNotificationString(json, 'sourceType'),
        ),
        sourceRecordId: requiredNotificationString(json, 'sourceRecordId'),
        sourceChildId: json['sourceChildId'] as String?,
      );
}

/// Localizable notification copy. Stored records retain message keys and
/// arguments, not an English-only sentence as business truth.
@immutable
class NotificationContent {
  NotificationContent({
    required this.titleKey,
    required this.messageKey,
    Map<String, String> arguments = const {},
  }) : arguments = Map.unmodifiable(arguments) {
    requireNotificationText(titleKey, 'titleKey');
    requireNotificationText(messageKey, 'messageKey');
    for (final entry in arguments.entries) {
      requireNotificationText(entry.key, 'argument key');
      requireNotificationText(entry.value, 'argument value');
    }
  }

  final String titleKey;
  final String messageKey;
  final Map<String, String> arguments;

  Map<String, Object?> toJson() => {
    'titleKey': titleKey,
    'messageKey': messageKey,
    'arguments': arguments,
  };

  factory NotificationContent.fromJson(Map<String, Object?> json) {
    final rawArguments = requiredNotificationMap(json, 'arguments');
    return NotificationContent(
      titleKey: requiredNotificationString(json, 'titleKey'),
      messageKey: requiredNotificationString(json, 'messageKey'),
      arguments: rawArguments.map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
  }
}

@immutable
class NotificationLifecycle {
  NotificationLifecycle({
    required this.revision,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) : createdAtUtc = createdAtUtc.toUtc(),
       updatedAtUtc = updatedAtUtc.toUtc() {
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
  }

  final int revision;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  NotificationLifecycle next(DateTime occurredAtUtc) => NotificationLifecycle(
    revision: revision + 1,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: occurredAtUtc,
  );

  Map<String, Object?> toJson() => {
    'revision': revision,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
  };

  factory NotificationLifecycle.fromJson(Map<String, Object?> json) =>
      NotificationLifecycle(
        revision: requiredNotificationInt(json, 'revision'),
        createdAtUtc: requiredNotificationUtc(json, 'createdAtUtc'),
        updatedAtUtc: requiredNotificationUtc(json, 'updatedAtUtc'),
      );
}

@immutable
class NotificationAuditEvent {
  NotificationAuditEvent({
    required this.action,
    required this.actorId,
    required this.permissionRevision,
    required DateTime occurredAtUtc,
    required this.toRevision,
    this.fromRevision,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc() {
    requireNotificationText(actorId, 'actorId');
    requireNotificationText(permissionRevision, 'permissionRevision');
    if (toRevision < 1) {
      throw ArgumentError.value(toRevision, 'toRevision', 'Must be positive.');
    }
  }

  final NotificationAuditAction action;
  final String actorId;
  final String permissionRevision;
  final DateTime occurredAtUtc;
  final int? fromRevision;
  final int toRevision;
  final String? note;

  Map<String, Object?> toJson() => {
    'action': action.name,
    'actorId': actorId,
    'permissionRevision': permissionRevision,
    'occurredAtUtc': occurredAtUtc.toIso8601String(),
    'fromRevision': fromRevision,
    'toRevision': toRevision,
    'note': note,
  };

  factory NotificationAuditEvent.fromJson(Map<String, Object?> json) =>
      NotificationAuditEvent(
        action: NotificationAuditAction.values.byName(
          requiredNotificationString(json, 'action'),
        ),
        actorId: requiredNotificationString(json, 'actorId'),
        permissionRevision: requiredNotificationString(
          json,
          'permissionRevision',
        ),
        occurredAtUtc: requiredNotificationUtc(json, 'occurredAtUtc'),
        fromRevision: json['fromRevision'] as int?,
        toRevision: requiredNotificationInt(json, 'toRevision'),
        note: json['note'] as String?,
      );
}

String requiredNotificationString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

int requiredNotificationInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}

Map<String, Object?> requiredNotificationMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) throw FormatException('Missing or invalid $key.');
  return value.cast<String, Object?>();
}

List<Object?> requiredNotificationList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing or invalid $key.');
  return value;
}

DateTime requiredNotificationUtc(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Missing or invalid $key.');
  return DateTime.parse(value).toUtc();
}

void requireNotificationText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Cannot be empty.');
  }
}
