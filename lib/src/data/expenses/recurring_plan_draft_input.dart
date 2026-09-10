import '../storage/local_record_identity.dart';
import 'expense_workflow_models.dart';

class RecurringPlanDraftInput {
  RecurringPlanDraftInput({
    required this.recordId,
    required this.baseRevision,
    required this.ownerId,
    required this.ownerLabel,
    required this.state,
    required this.title,
    required this.amount,
    required this.category,
    required this.kind,
    required this.amountKind,
    required this.dueDate,
    required this.dueDay,
    required this.inApp,
    required this.push,
    required this.sound,
    required this.receiptRequired,
    required Iterable<int> reminders,
  }) : reminders = Set.unmodifiable(reminders);
  final String recordId;
  final int? baseRevision;
  final String ownerId;
  final String ownerLabel;
  final ScheduledExpenseState state;
  final String title;
  final String amount;
  final ExpenseCategory category;
  final ExpenseScheduleKind kind;
  final ScheduledExpenseAmountKind amountKind;
  final DateTime dueDate;
  final int dueDay;
  final bool inApp;
  final bool push;
  final bool sound;
  final bool receiptRequired;
  final Set<int> reminders;
  factory RecurringPlanDraftInput.initial({
    ScheduledExpenseRecord? record,
    int? baseRevision,
    required String ownerId,
    required String ownerLabel,
  }) {
    final now = DateTime.now().add(const Duration(days: 7));
    final due = record?.nextDueOn ?? DateTime(now.year, now.month, now.day);
    return RecurringPlanDraftInput(
      recordId: record?.id ?? newLocalRecordIdentity('scheduled'),
      baseRevision: baseRevision,
      ownerId: record?.ownerEmployeeId ?? ownerId,
      ownerLabel: record?.owner ?? ownerLabel,
      state: record?.state ?? ScheduledExpenseState.active,
      title: record?.title ?? '',
      amount: record?.amount.toStringAsFixed(2) ?? '',
      category: record?.category ?? ExpenseCategory.office,
      kind: record?.kind ?? ExpenseScheduleKind.monthly,
      amountKind: record?.amountKind ?? ScheduledExpenseAmountKind.fixed,
      dueDate: due,
      dueDay: record?.dueDay ?? due.day,
      reminders: record?.reminderDaysBefore ?? const [],
      inApp: record?.inAppReminder ?? true,
      push: record?.pushReminder ?? true,
      sound: record?.soundReminder ?? true,
      receiptRequired: record?.receiptRequired ?? false,
    );
  }
  static String? amountError(String value) {
    final valueParsed = double.tryParse(value);
    return valueParsed == null || !valueParsed.isFinite || valueParsed <= 0
        ? 'Enter an amount above zero.'
        : null;
  }

  ScheduledExpenseRecord confirmedRecord() {
    if (title.trim().isEmpty) throw StateError('Enter a title.');
    final error = amountError(amount);
    if (error != null) throw StateError(error);
    return ScheduledExpenseRecord(
      id: recordId,
      title: title.trim(),
      category: category,
      amount: double.parse(amount.trim()),
      nextDueOn: dueDate,
      kind: kind,
      ownerEmployeeId: ownerId,
      owner: ownerLabel,
      reminderDaysBefore: reminders.toList()..sort(),
      inAppReminder: inApp,
      pushReminder: push,
      soundReminder: sound,
      amountKind: amountKind,
      state: state,
      receiptRequired: receiptRequired,
      dueDay: kind == ExpenseScheduleKind.monthly ? dueDay : null,
    );
  }

  Map<String, Object?> toPayload() => {
    'recordId': recordId,
    'baseRevision': baseRevision,
    'ownerId': ownerId,
    'ownerLabel': ownerLabel,
    'state': state.name,
    'title': title,
    'amount': amount,
    'category': category.name,
    'kind': kind.name,
    'amountKind': amountKind.name,
    'dueDate': dueDate.toIso8601String(),
    'dueDay': dueDay,
    'inApp': inApp,
    'push': push,
    'sound': sound,
    'receiptRequired': receiptRequired,
    'reminders': reminders.toList()..sort(),
  };
  factory RecurringPlanDraftInput.fromPayload(Map<String, Object?> input) =>
      RecurringPlanDraftInput(
        recordId: input['recordId'] as String,
        baseRevision: input['baseRevision'] as int?,
        ownerId: input['ownerId'] as String,
        ownerLabel: input['ownerLabel'] as String,
        state: ScheduledExpenseState.values.byName(input['state'] as String),
        title: input['title'] as String,
        amount: input['amount'] as String,
        category: ExpenseCategory.values.byName(input['category'] as String),
        kind: ExpenseScheduleKind.values.byName(input['kind'] as String),
        amountKind: ScheduledExpenseAmountKind.values.byName(
          input['amountKind'] as String,
        ),
        dueDate: DateTime.parse(input['dueDate'] as String),
        dueDay: input['dueDay'] as int,
        inApp: input['inApp'] as bool,
        push: input['push'] as bool,
        sound: input['sound'] as bool,
        receiptRequired: input['receiptRequired'] as bool,
        reminders: (input['reminders'] as List).cast<int>(),
      );
}

DateTime recurringPlanDueDateAfterChange({
  required ExpenseScheduleKind previousKind,
  required int previousDay,
  required ExpenseScheduleKind kind,
  required int dueDay,
  required DateTime dueDate,
  required DateTime now,
}) {
  if (kind != ExpenseScheduleKind.monthly ||
      (previousDay == dueDay && previousKind == kind)) {
    return dueDate;
  }
  final month = DateTime(now.year, now.month + (dueDay < now.day ? 1 : 0));
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(month.year, month.month, dueDay > lastDay ? lastDay : dueDay);
}
