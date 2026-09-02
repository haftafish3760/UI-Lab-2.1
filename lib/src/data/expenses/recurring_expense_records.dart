import 'package:flutter/foundation.dart';

import 'expense_record.dart';
import 'recurring_expense_terms.dart';

const _unchangedRecurringValue = Object();

@immutable
class StoredRecurringExpenseTemplate {
  StoredRecurringExpenseTemplate({
    required this.templateId,
    required this.organizationId,
    required this.createdByEmployeeId,
    required this.assignedEmployeeId,
    required this.title,
    required this.categoryId,
    required this.categoryLabelSnapshot,
    required this.expectedAmount,
    required this.amountMode,
    required this.schedule,
    required DateTime nextDueOn,
    required this.reminders,
    required this.receiptRequired,
    required this.state,
    required this.lifecycle,
    List<RecurringExpenseAuditEvent> auditTrail = const [],
    this.jobId,
    this.vehicleId,
  }) : nextDueOn = DateTime(nextDueOn.year, nextDueOn.month, nextDueOn.day),
       auditTrail = List.unmodifiable(auditTrail) {
    requireRecurringNonEmpty(templateId, 'templateId');
    requireRecurringNonEmpty(organizationId, 'organizationId');
    requireRecurringNonEmpty(createdByEmployeeId, 'createdByEmployeeId');
    requireRecurringNonEmpty(assignedEmployeeId, 'assignedEmployeeId');
    requireRecurringNonEmpty(title, 'title');
    requireRecurringNonEmpty(categoryId, 'categoryId');
    requireRecurringNonEmpty(categoryLabelSnapshot, 'categoryLabelSnapshot');
    if (expectedAmount.minorUnits <= 0) {
      throw ArgumentError.value(
        expectedAmount.minorUnits,
        'expectedAmount',
        'Must be above zero.',
      );
    }
  }

  final String templateId;
  final String organizationId;
  final String createdByEmployeeId;
  final String assignedEmployeeId;
  final String title;
  final String categoryId;
  final String categoryLabelSnapshot;
  final ExpenseMoney expectedAmount;
  final RecurringExpenseAmountMode amountMode;
  final RecurringExpenseSchedule schedule;
  final DateTime nextDueOn;
  final String? jobId;
  final String? vehicleId;
  final RecurringExpenseReminderSettings reminders;
  final bool receiptRequired;
  final RecurringExpenseState state;
  final RecurringExpenseLifecycle lifecycle;
  final List<RecurringExpenseAuditEvent> auditTrail;

  bool get isActive => state == RecurringExpenseState.active;

  StoredRecurringExpenseOccurrence initialOccurrence({
    required String occurrenceId,
    required DateTime occurredAtUtc,
    required String actorEmployeeId,
    required String permissionRevision,
  }) => StoredRecurringExpenseOccurrence(
    occurrenceId: occurrenceId,
    templateId: templateId,
    organizationId: organizationId,
    assignedEmployeeId: assignedEmployeeId,
    dueOn: nextDueOn,
    expectedAmount: expectedAmount,
    state: RecurringExpenseOccurrenceState.due,
    lifecycle: RecurringExpenseLifecycle(
      revision: 1,
      createdAtUtc: occurredAtUtc,
      updatedAtUtc: occurredAtUtc,
    ),
    auditTrail: [
      RecurringExpenseAuditEvent(
        action: RecurringExpenseAuditAction.occurrenceCreated,
        actorEmployeeId: actorEmployeeId,
        occurredAtUtc: occurredAtUtc,
        fromRevision: null,
        toRevision: 1,
        permissionRevision: permissionRevision,
      ),
    ],
  );

  StoredRecurringExpenseTemplate copyWith({
    String? assignedEmployeeId,
    String? title,
    String? categoryId,
    String? categoryLabelSnapshot,
    ExpenseMoney? expectedAmount,
    RecurringExpenseAmountMode? amountMode,
    RecurringExpenseSchedule? schedule,
    DateTime? nextDueOn,
    Object? jobId = _unchangedRecurringValue,
    Object? vehicleId = _unchangedRecurringValue,
    RecurringExpenseReminderSettings? reminders,
    bool? receiptRequired,
    RecurringExpenseState? state,
    RecurringExpenseLifecycle? lifecycle,
    List<RecurringExpenseAuditEvent>? auditTrail,
  }) => StoredRecurringExpenseTemplate(
    templateId: templateId,
    organizationId: organizationId,
    createdByEmployeeId: createdByEmployeeId,
    assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
    title: title ?? this.title,
    categoryId: categoryId ?? this.categoryId,
    categoryLabelSnapshot: categoryLabelSnapshot ?? this.categoryLabelSnapshot,
    expectedAmount: expectedAmount ?? this.expectedAmount,
    amountMode: amountMode ?? this.amountMode,
    schedule: schedule ?? this.schedule,
    nextDueOn: nextDueOn ?? this.nextDueOn,
    jobId: identical(jobId, _unchangedRecurringValue)
        ? this.jobId
        : jobId as String?,
    vehicleId: identical(vehicleId, _unchangedRecurringValue)
        ? this.vehicleId
        : vehicleId as String?,
    reminders: reminders ?? this.reminders,
    receiptRequired: receiptRequired ?? this.receiptRequired,
    state: state ?? this.state,
    lifecycle: lifecycle ?? this.lifecycle,
    auditTrail: auditTrail ?? this.auditTrail,
  );

  Map<String, Object?> toJson() => {
    'templateId': templateId,
    'organizationId': organizationId,
    'createdByEmployeeId': createdByEmployeeId,
    'assignedEmployeeId': assignedEmployeeId,
    'title': title,
    'categoryId': categoryId,
    'categoryLabelSnapshot': categoryLabelSnapshot,
    'expectedAmount': expectedAmount.toJson(),
    'amountMode': amountMode.name,
    'schedule': schedule.toJson(),
    'nextDueOn': expenseDateKey(nextDueOn),
    'jobId': jobId,
    'vehicleId': vehicleId,
    'reminders': reminders.toJson(),
    'receiptRequired': receiptRequired,
    'state': state.name,
    'lifecycle': lifecycle.toJson(),
    'auditTrail': auditTrail.map((event) => event.toJson()).toList(),
  };

  factory StoredRecurringExpenseTemplate.fromJson(
    Map<String, Object?> json,
  ) => StoredRecurringExpenseTemplate(
    templateId: requiredRecurringString(json, 'templateId'),
    organizationId: requiredRecurringString(json, 'organizationId'),
    createdByEmployeeId: requiredRecurringString(json, 'createdByEmployeeId'),
    assignedEmployeeId: requiredRecurringString(json, 'assignedEmployeeId'),
    title: requiredRecurringString(json, 'title'),
    categoryId: requiredRecurringString(json, 'categoryId'),
    categoryLabelSnapshot: requiredRecurringString(
      json,
      'categoryLabelSnapshot',
    ),
    expectedAmount: ExpenseMoney.fromJson(
      requiredRecurringMap(json, 'expectedAmount'),
    ),
    amountMode: RecurringExpenseAmountMode.values.byName(
      requiredRecurringString(json, 'amountMode'),
    ),
    schedule: RecurringExpenseSchedule.fromJson(
      requiredRecurringMap(json, 'schedule'),
    ),
    nextDueOn: parseExpenseDateKey(requiredRecurringString(json, 'nextDueOn')),
    jobId: json['jobId'] as String?,
    vehicleId: json['vehicleId'] as String?,
    reminders: RecurringExpenseReminderSettings.fromJson(
      requiredRecurringMap(json, 'reminders'),
    ),
    receiptRequired: requiredRecurringBool(json, 'receiptRequired'),
    state: RecurringExpenseState.values.byName(
      requiredRecurringString(json, 'state'),
    ),
    lifecycle: RecurringExpenseLifecycle.fromJson(
      requiredRecurringMap(json, 'lifecycle'),
    ),
    auditTrail: requiredRecurringList(json, 'auditTrail')
        .map(
          (value) => RecurringExpenseAuditEvent.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(),
  );
}

@immutable
class StoredRecurringExpenseOccurrence {
  StoredRecurringExpenseOccurrence({
    required this.occurrenceId,
    required this.templateId,
    required this.organizationId,
    required this.assignedEmployeeId,
    required DateTime dueOn,
    required this.expectedAmount,
    required this.state,
    required this.lifecycle,
    List<RecurringExpenseAuditEvent> auditTrail = const [],
    DateTime? paidOn,
    this.actualAmount,
    this.expenseId,
  }) : dueOn = DateTime(dueOn.year, dueOn.month, dueOn.day),
       paidOn = paidOn == null
           ? null
           : DateTime(paidOn.year, paidOn.month, paidOn.day),
       auditTrail = List.unmodifiable(auditTrail) {
    requireRecurringNonEmpty(occurrenceId, 'occurrenceId');
    requireRecurringNonEmpty(templateId, 'templateId');
    requireRecurringNonEmpty(organizationId, 'organizationId');
    requireRecurringNonEmpty(assignedEmployeeId, 'assignedEmployeeId');
    if (expectedAmount.minorUnits <= 0) {
      throw ArgumentError.value(
        expectedAmount.minorUnits,
        'expectedAmount',
        'Must be above zero.',
      );
    }
    if (state == RecurringExpenseOccurrenceState.paid) {
      if (this.paidOn == null || actualAmount == null || expenseId == null) {
        throw const FormatException(
          'Paid occurrence requires date, amount, and Expense identity.',
        );
      }
      if (actualAmount!.minorUnits <= 0) {
        throw const FormatException('Paid amount must be above zero.');
      }
    } else if (this.paidOn != null ||
        actualAmount != null ||
        expenseId != null) {
      throw const FormatException(
        'Only a paid occurrence can reference a paid Expense.',
      );
    }
  }

  final String occurrenceId;
  final String templateId;
  final String organizationId;
  final String assignedEmployeeId;
  final DateTime dueOn;
  final ExpenseMoney expectedAmount;
  final RecurringExpenseOccurrenceState state;
  final DateTime? paidOn;
  final ExpenseMoney? actualAmount;
  final String? expenseId;
  final RecurringExpenseLifecycle lifecycle;
  final List<RecurringExpenseAuditEvent> auditTrail;

  bool get isOpen => state == RecurringExpenseOccurrenceState.due;

  bool isOverdueOn(DateTime day) =>
      isOpen && dueOn.isBefore(DateTime(day.year, day.month, day.day));

  StoredRecurringExpenseOccurrence copyWith({
    String? assignedEmployeeId,
    DateTime? dueOn,
    ExpenseMoney? expectedAmount,
    RecurringExpenseOccurrenceState? state,
    Object? paidOn = _unchangedRecurringValue,
    Object? actualAmount = _unchangedRecurringValue,
    Object? expenseId = _unchangedRecurringValue,
    RecurringExpenseLifecycle? lifecycle,
    List<RecurringExpenseAuditEvent>? auditTrail,
  }) => StoredRecurringExpenseOccurrence(
    occurrenceId: occurrenceId,
    templateId: templateId,
    organizationId: organizationId,
    assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
    dueOn: dueOn ?? this.dueOn,
    expectedAmount: expectedAmount ?? this.expectedAmount,
    state: state ?? this.state,
    paidOn: identical(paidOn, _unchangedRecurringValue)
        ? this.paidOn
        : paidOn as DateTime?,
    actualAmount: identical(actualAmount, _unchangedRecurringValue)
        ? this.actualAmount
        : actualAmount as ExpenseMoney?,
    expenseId: identical(expenseId, _unchangedRecurringValue)
        ? this.expenseId
        : expenseId as String?,
    lifecycle: lifecycle ?? this.lifecycle,
    auditTrail: auditTrail ?? this.auditTrail,
  );

  Map<String, Object?> toJson() => {
    'occurrenceId': occurrenceId,
    'templateId': templateId,
    'organizationId': organizationId,
    'assignedEmployeeId': assignedEmployeeId,
    'dueOn': expenseDateKey(dueOn),
    'expectedAmount': expectedAmount.toJson(),
    'state': state.name,
    'paidOn': paidOn == null ? null : expenseDateKey(paidOn!),
    'actualAmount': actualAmount?.toJson(),
    'expenseId': expenseId,
    'lifecycle': lifecycle.toJson(),
    'auditTrail': auditTrail.map((event) => event.toJson()).toList(),
  };

  factory StoredRecurringExpenseOccurrence.fromJson(
    Map<String, Object?> json,
  ) => StoredRecurringExpenseOccurrence(
    occurrenceId: requiredRecurringString(json, 'occurrenceId'),
    templateId: requiredRecurringString(json, 'templateId'),
    organizationId: requiredRecurringString(json, 'organizationId'),
    assignedEmployeeId: requiredRecurringString(json, 'assignedEmployeeId'),
    dueOn: parseExpenseDateKey(requiredRecurringString(json, 'dueOn')),
    expectedAmount: ExpenseMoney.fromJson(
      requiredRecurringMap(json, 'expectedAmount'),
    ),
    state: RecurringExpenseOccurrenceState.values.byName(
      requiredRecurringString(json, 'state'),
    ),
    paidOn: json['paidOn'] is String
        ? parseExpenseDateKey(json['paidOn']! as String)
        : null,
    actualAmount: json['actualAmount'] is Map
        ? ExpenseMoney.fromJson(
            (json['actualAmount'] as Map).cast<String, Object?>(),
          )
        : null,
    expenseId: json['expenseId'] as String?,
    lifecycle: RecurringExpenseLifecycle.fromJson(
      requiredRecurringMap(json, 'lifecycle'),
    ),
    auditTrail: requiredRecurringList(json, 'auditTrail')
        .map(
          (value) => RecurringExpenseAuditEvent.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(),
  );
}
