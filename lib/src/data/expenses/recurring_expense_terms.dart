import 'package:flutter/foundation.dart';

enum RecurringExpenseScheduleKind { oneTime, monthly }

enum RecurringExpenseAmountMode { fixed, enterWhenPaid }

enum RecurringExpenseState { active, paused, ended }

enum RecurringExpenseOccurrenceState { due, paid, skipped }

enum RecurringExpenseAuditAction {
  templateCreated,
  templateUpdated,
  templatePaused,
  templateResumed,
  templateEnded,
  occurrenceCreated,
  occurrenceUpdated,
  occurrenceSkipped,
  occurrencePaid,
}

@immutable
class RecurringExpenseSchedule {
  const RecurringExpenseSchedule.oneTime()
    : kind = RecurringExpenseScheduleKind.oneTime,
      monthlyDay = null;

  const RecurringExpenseSchedule.monthly(int day)
    : kind = RecurringExpenseScheduleKind.monthly,
      monthlyDay = day,
      assert(day >= 1 && day <= 31);

  const RecurringExpenseSchedule._({required this.kind, this.monthlyDay});

  final RecurringExpenseScheduleKind kind;
  final int? monthlyDay;

  DateTime? nextDueAfter(DateTime occurrenceDueOn) {
    if (kind == RecurringExpenseScheduleKind.oneTime) return null;
    final firstOfNextMonth = DateTime(
      occurrenceDueOn.year,
      occurrenceDueOn.month + 1,
    );
    final lastDay = DateTime(
      firstOfNextMonth.year,
      firstOfNextMonth.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfNextMonth.year,
      firstOfNextMonth.month,
      monthlyDay!.clamp(1, lastDay),
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'monthlyDay': monthlyDay,
  };

  factory RecurringExpenseSchedule.fromJson(Map<String, Object?> json) {
    final kind = RecurringExpenseScheduleKind.values.byName(
      requiredRecurringString(json, 'kind'),
    );
    final monthlyDay = json['monthlyDay'] as int?;
    if (kind == RecurringExpenseScheduleKind.monthly &&
        (monthlyDay == null || monthlyDay < 1 || monthlyDay > 31)) {
      throw const FormatException('Monthly schedule requires a valid day.');
    }
    if (kind == RecurringExpenseScheduleKind.oneTime && monthlyDay != null) {
      throw const FormatException(
        'One-time schedule cannot have a monthly day.',
      );
    }
    return RecurringExpenseSchedule._(kind: kind, monthlyDay: monthlyDay);
  }
}

@immutable
class RecurringExpenseReminderSettings {
  RecurringExpenseReminderSettings({
    List<int> daysBefore = const [1],
    this.inApp = true,
    this.push = true,
    this.sound = true,
  }) : daysBefore = List.unmodifiable(_validatedReminderDays(daysBefore));

  final List<int> daysBefore;
  final bool inApp;
  final bool push;
  final bool sound;

  Map<String, Object?> toJson() => {
    'daysBefore': daysBefore,
    'inApp': inApp,
    'push': push,
    'sound': sound,
  };

  factory RecurringExpenseReminderSettings.fromJson(
    Map<String, Object?> json,
  ) => RecurringExpenseReminderSettings(
    daysBefore: requiredRecurringList(
      json,
      'daysBefore',
    ).map((value) => value as int).toList(),
    inApp: requiredRecurringBool(json, 'inApp'),
    push: requiredRecurringBool(json, 'push'),
    sound: requiredRecurringBool(json, 'sound'),
  );
}

@immutable
class RecurringExpenseLifecycle {
  RecurringExpenseLifecycle({
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

  RecurringExpenseLifecycle nextRevision(DateTime occurredAtUtc) =>
      RecurringExpenseLifecycle(
        revision: revision + 1,
        createdAtUtc: createdAtUtc,
        updatedAtUtc: occurredAtUtc,
      );

  Map<String, Object?> toJson() => {
    'revision': revision,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
  };

  factory RecurringExpenseLifecycle.fromJson(Map<String, Object?> json) =>
      RecurringExpenseLifecycle(
        revision: requiredRecurringInt(json, 'revision'),
        createdAtUtc: requiredRecurringUtc(json, 'createdAtUtc'),
        updatedAtUtc: requiredRecurringUtc(json, 'updatedAtUtc'),
      );
}

@immutable
class RecurringExpenseAuditEvent {
  RecurringExpenseAuditEvent({
    required this.action,
    required this.actorEmployeeId,
    required DateTime occurredAtUtc,
    required this.toRevision,
    required this.permissionRevision,
    this.fromRevision,
    this.note,
  }) : occurredAtUtc = occurredAtUtc.toUtc() {
    requireRecurringNonEmpty(actorEmployeeId, 'actorEmployeeId');
    requireRecurringNonEmpty(permissionRevision, 'permissionRevision');
    if (toRevision < 1) {
      throw ArgumentError.value(toRevision, 'toRevision', 'Must be positive.');
    }
  }

  final RecurringExpenseAuditAction action;
  final String actorEmployeeId;
  final DateTime occurredAtUtc;
  final int? fromRevision;
  final int toRevision;
  final String permissionRevision;
  final String? note;

  Map<String, Object?> toJson() => {
    'action': action.name,
    'actorEmployeeId': actorEmployeeId,
    'occurredAtUtc': occurredAtUtc.toIso8601String(),
    'fromRevision': fromRevision,
    'toRevision': toRevision,
    'permissionRevision': permissionRevision,
    'note': note,
  };

  factory RecurringExpenseAuditEvent.fromJson(Map<String, Object?> json) =>
      RecurringExpenseAuditEvent(
        action: RecurringExpenseAuditAction.values.byName(
          requiredRecurringString(json, 'action'),
        ),
        actorEmployeeId: requiredRecurringString(json, 'actorEmployeeId'),
        occurredAtUtc: requiredRecurringUtc(json, 'occurredAtUtc'),
        fromRevision: json['fromRevision'] as int?,
        toRevision: requiredRecurringInt(json, 'toRevision'),
        permissionRevision: requiredRecurringString(json, 'permissionRevision'),
        note: json['note'] as String?,
      );
}

List<int> _validatedReminderDays(List<int> input) {
  if (input.length > 5) {
    throw ArgumentError.value(input, 'daysBefore', 'At most five reminders.');
  }
  final unique = input.toSet();
  if (unique.length != input.length ||
      unique.any((day) => day < 0 || day > 365)) {
    throw ArgumentError.value(
      input,
      'daysBefore',
      'Use unique values from 0 through 365.',
    );
  }
  return unique.toList()..sort();
}

String requiredRecurringString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

int requiredRecurringInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Missing or invalid $key.');
  return value;
}

bool requiredRecurringBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Missing or invalid $key.');
  return value;
}

Map<String, Object?> requiredRecurringMap(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) throw FormatException('Missing or invalid $key.');
  return value.cast<String, Object?>();
}

List<Object?> requiredRecurringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing or invalid $key.');
  return value;
}

DateTime requiredRecurringUtc(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Missing or invalid $key.');
  return DateTime.parse(value).toUtc();
}

void requireRecurringNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Cannot be empty.');
  }
}
