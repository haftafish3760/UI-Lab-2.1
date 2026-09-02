import 'package:flutter/material.dart';

part 'expense_demo_data.dart';

const _expenseValueUnchanged = Object();

enum ExpenseCategory {
  materials('Materials', Icons.inventory_2_outlined),
  consumables('Consumables', Icons.cleaning_services_outlined),
  fuel('Fuel', Icons.local_gas_station_outlined),
  vehiclePayment('Vehicle payments', Icons.directions_car_filled_outlined),
  vehicleInsurance('Vehicle insurance', Icons.verified_user_outlined),
  vehicleRepair('Vehicle repairs', Icons.car_repair_outlined),
  vehicleMaintenance('Vehicle maintenance', Icons.build_circle_outlined),
  vehicle('Other vehicle costs', Icons.local_shipping_outlined),
  tools('Tools and equipment', Icons.handyman_outlined),
  subcontractor('Subcontractors', Icons.groups_outlined),
  office('Office and business', Icons.business_center_outlined),
  rent('Rent and storage', Icons.warehouse_outlined),
  utilities('Utilities', Icons.bolt_outlined),
  phoneInternet('Phone and internet', Icons.cell_tower_outlined),
  licensesTaxes('Licenses and taxes', Icons.account_balance_outlined),
  advertising('Advertising', Icons.campaign_outlined),
  training('Training', Icons.school_outlined),
  banking('Banking and fees', Icons.credit_card_outlined),
  travel('Meals and travel', Icons.route_outlined),
  other('Other', Icons.receipt_long_outlined);

  const ExpenseCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ExpenseApprovalStatus {
  notRequired('No approval needed'),
  pending('Needs approval'),
  approved('Approved'),
  declined('Not approved');

  const ExpenseApprovalStatus(this.label);
  final String label;
}

enum ExpenseReceiptType {
  basic('Basic', 'Keep the category, total, and receipt evidence.'),
  detailed('Detailed', 'Keep every reviewed receipt line item.');

  const ExpenseReceiptType(this.label, this.description);
  final String label;
  final String description;
}

@immutable
class ExpenseLineItem {
  const ExpenseLineItem({
    required this.id,
    required this.description,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.confirmedLineTotal,
    this.unitsPerPackage = 1,
    this.partNumber,
    this.jobId,
    this.jobLabel,
  });

  final String id;
  final String description;
  final ExpenseCategory category;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double? confirmedLineTotal;
  final double unitsPerPackage;
  final String? partNumber;
  final String? jobId;
  final String? jobLabel;

  double get total => confirmedLineTotal ?? quantity * unitPrice;

  ExpenseLineItem copyWith({
    String? description,
    ExpenseCategory? category,
    double? quantity,
    String? unit,
    double? unitPrice,
    Object? confirmedLineTotal = _expenseValueUnchanged,
    double? unitsPerPackage,
    Object? partNumber = _expenseValueUnchanged,
    String? jobId,
    String? jobLabel,
  }) => ExpenseLineItem(
    id: id,
    description: description ?? this.description,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    confirmedLineTotal: identical(confirmedLineTotal, _expenseValueUnchanged)
        ? this.confirmedLineTotal
        : confirmedLineTotal as double?,
    unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
    partNumber: identical(partNumber, _expenseValueUnchanged)
        ? this.partNumber
        : partNumber as String?,
    jobId: jobId ?? this.jobId,
    jobLabel: jobLabel ?? this.jobLabel,
  );
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.vendor,
    required this.category,
    required this.amount,
    required this.date,
    required this.owner,
    this.paidByEmployeeId,
    this.job,
    this.jobId,
    this.receiptStatus,
    this.receiptType = ExpenseReceiptType.basic,
    this.receiptImageCount = 0,
    this.lineItems = const [],
    this.receiptSubtotal,
    this.salesTax = 0,
    this.prepareMaterialsReview = false,
    this.approvalStatus = ExpenseApprovalStatus.notRequired,
    this.approvalReason,
    this.requiresSubmitterAttention = false,
    this.submitterAttentionReason,
  });

  final String id;
  final String vendor;
  final ExpenseCategory category;
  final double amount;

  /// Accepts a typed date and legacy serialized dates at this UI boundary.
  /// Production repositories should decode into a typed domain record before
  /// constructing the screen model.
  final Object date;
  DateTime? get resolvedDate => parseExpenseDate(date);
  final String owner;
  final String? paidByEmployeeId;
  final String? job;
  final String? jobId;
  final String? receiptStatus;
  final ExpenseReceiptType receiptType;
  final int receiptImageCount;
  final List<ExpenseLineItem> lineItems;
  final double? receiptSubtotal;
  final double salesTax;
  final bool prepareMaterialsReview;
  final ExpenseApprovalStatus approvalStatus;
  final String? approvalReason;
  final bool requiresSubmitterAttention;
  final String? submitterAttentionReason;

  bool get countsAsRecordedBusinessCost =>
      !requiresSubmitterAttention &&
      (approvalStatus == ExpenseApprovalStatus.notRequired ||
          approvalStatus == ExpenseApprovalStatus.approved);

  double get reviewedLineSubtotal =>
      lineItems.fold(0, (sum, item) => sum + item.total);

  double get resolvedReceiptSubtotal => receiptSubtotal ?? reviewedLineSubtotal;

  ExpenseRecord copyWith({
    String? vendor,
    ExpenseCategory? category,
    double? amount,
    Object? date,
    String? owner,
    Object? paidByEmployeeId = _expenseValueUnchanged,
    Object? job = _expenseValueUnchanged,
    Object? jobId = _expenseValueUnchanged,
    Object? receiptStatus = _expenseValueUnchanged,
    ExpenseReceiptType? receiptType,
    int? receiptImageCount,
    List<ExpenseLineItem>? lineItems,
    Object? receiptSubtotal = _expenseValueUnchanged,
    double? salesTax,
    bool? prepareMaterialsReview,
    ExpenseApprovalStatus? approvalStatus,
    Object? approvalReason = _expenseValueUnchanged,
    bool? requiresSubmitterAttention,
    Object? submitterAttentionReason = _expenseValueUnchanged,
  }) => ExpenseRecord(
    id: id,
    vendor: vendor ?? this.vendor,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    owner: owner ?? this.owner,
    paidByEmployeeId: identical(paidByEmployeeId, _expenseValueUnchanged)
        ? this.paidByEmployeeId
        : paidByEmployeeId as String?,
    job: identical(job, _expenseValueUnchanged) ? this.job : job as String?,
    jobId: identical(jobId, _expenseValueUnchanged)
        ? this.jobId
        : jobId as String?,
    receiptStatus: identical(receiptStatus, _expenseValueUnchanged)
        ? this.receiptStatus
        : receiptStatus as String?,
    receiptType: receiptType ?? this.receiptType,
    receiptImageCount: receiptImageCount ?? this.receiptImageCount,
    lineItems: lineItems ?? this.lineItems,
    receiptSubtotal: identical(receiptSubtotal, _expenseValueUnchanged)
        ? this.receiptSubtotal
        : receiptSubtotal as double?,
    salesTax: salesTax ?? this.salesTax,
    prepareMaterialsReview:
        prepareMaterialsReview ?? this.prepareMaterialsReview,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    approvalReason: identical(approvalReason, _expenseValueUnchanged)
        ? this.approvalReason
        : approvalReason as String?,
    requiresSubmitterAttention:
        requiresSubmitterAttention ?? this.requiresSubmitterAttention,
    submitterAttentionReason:
        identical(submitterAttentionReason, _expenseValueUnchanged)
        ? this.submitterAttentionReason
        : submitterAttentionReason as String?,
  );
}

@immutable
class ExpenseReceiptDraft {
  const ExpenseReceiptDraft({
    required this.id,
    required this.title,
    required this.expenseDate,
    required this.updatedOn,
    required this.ownerEmployeeId,
    required this.owner,
    required this.imageCount,
  });

  final String id;
  final String title;
  final DateTime expenseDate;
  final DateTime updatedOn;
  final String ownerEmployeeId;
  final String owner;
  final int imageCount;
}

enum ExpenseScheduleKind {
  oneTime('Upcoming'),
  monthly('Monthly');

  const ExpenseScheduleKind(this.label);
  final String label;
}

enum ScheduledExpenseState {
  active('Active'),
  paused('Paused'),
  ended('Ended');

  const ScheduledExpenseState(this.label);
  final String label;
}

enum ScheduledExpenseAmountKind {
  fixed('Same amount each time'),
  enterWhenPaid('Enter the actual amount when paid');

  const ScheduledExpenseAmountKind(this.label);
  final String label;
}

enum ScheduledExpenseOccurrenceStatus {
  due('Due'),
  paid('Paid'),
  skipped('Skipped');

  const ScheduledExpenseOccurrenceStatus(this.label);
  final String label;
}

@immutable
class ScheduledExpenseOccurrence {
  const ScheduledExpenseOccurrence({
    required this.id,
    required this.templateId,
    required this.dueOn,
    required this.expectedAmount,
    this.status = ScheduledExpenseOccurrenceStatus.due,
    this.paidOn,
    this.actualAmount,
    this.expenseId,
  });

  final String id;
  final String templateId;
  final DateTime dueOn;
  final double expectedAmount;
  final ScheduledExpenseOccurrenceStatus status;
  final DateTime? paidOn;
  final double? actualAmount;
  final String? expenseId;

  bool get isOpen => status == ScheduledExpenseOccurrenceStatus.due;

  bool isOverdueOn(DateTime day) =>
      isOpen && DateUtils.dateOnly(dueOn).isBefore(DateUtils.dateOnly(day));

  ScheduledExpenseOccurrence copyWith({
    DateTime? dueOn,
    double? expectedAmount,
    ScheduledExpenseOccurrenceStatus? status,
    DateTime? paidOn,
    double? actualAmount,
    String? expenseId,
  }) => ScheduledExpenseOccurrence(
    id: id,
    templateId: templateId,
    dueOn: dueOn ?? this.dueOn,
    expectedAmount: expectedAmount ?? this.expectedAmount,
    status: status ?? this.status,
    paidOn: paidOn ?? this.paidOn,
    actualAmount: actualAmount ?? this.actualAmount,
    expenseId: expenseId ?? this.expenseId,
  );
}

@immutable
class ScheduledExpenseRecord {
  const ScheduledExpenseRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.nextDueOn,
    required this.kind,
    required this.ownerEmployeeId,
    required this.owner,
    this.reminderDaysBefore = const [1],
    this.inAppReminder = true,
    this.pushReminder = true,
    this.soundReminder = true,
    this.amountKind = ScheduledExpenseAmountKind.fixed,
    this.state = ScheduledExpenseState.active,
    this.receiptRequired = false,
    this.dueDay,
  }) : assert(reminderDaysBefore.length <= 5);

  final String id;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime nextDueOn;
  final ExpenseScheduleKind kind;
  final String ownerEmployeeId;
  final String owner;
  final List<int> reminderDaysBefore;
  final bool inAppReminder;
  final bool pushReminder;
  final bool soundReminder;
  final ScheduledExpenseAmountKind amountKind;
  final ScheduledExpenseState state;
  final bool receiptRequired;
  final int? dueDay;

  bool get isActive => state == ScheduledExpenseState.active;

  DateTime? nextDueAfter(DateTime occurrenceDueOn) {
    if (kind == ExpenseScheduleKind.oneTime) return null;
    final preferredDay = dueDay ?? occurrenceDueOn.day;
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
      preferredDay.clamp(1, lastDay).toInt(),
    );
  }

  ScheduledExpenseRecord copyWith({
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? nextDueOn,
    ExpenseScheduleKind? kind,
    List<int>? reminderDaysBefore,
    bool? inAppReminder,
    bool? pushReminder,
    bool? soundReminder,
    ScheduledExpenseAmountKind? amountKind,
    ScheduledExpenseState? state,
    bool? receiptRequired,
    int? dueDay,
  }) => ScheduledExpenseRecord(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    nextDueOn: nextDueOn ?? this.nextDueOn,
    kind: kind ?? this.kind,
    ownerEmployeeId: ownerEmployeeId,
    owner: owner,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    inAppReminder: inAppReminder ?? this.inAppReminder,
    pushReminder: pushReminder ?? this.pushReminder,
    soundReminder: soundReminder ?? this.soundReminder,
    amountKind: amountKind ?? this.amountKind,
    state: state ?? this.state,
    receiptRequired: receiptRequired ?? this.receiptRequired,
    dueDay: dueDay ?? this.dueDay,
  );
}

String expenseMoney(double value) => '\$${value.toStringAsFixed(2)}';

DateTime? parseExpenseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
