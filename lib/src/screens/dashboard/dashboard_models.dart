import 'package:flutter/material.dart';

final dashboardToday = DateUtils.dateOnly(DateTime.now());

class DashboardPermissions {
  const DashboardPermissions({
    required this.canViewSchedule,
    required this.canAddSchedule,
    required this.canAddHistoricalEntry,
    required this.canViewEntryDetails,
    required this.canCreateEstimate,
    required this.canCreateInvoice,
    required this.canCreateJob,
    required this.canRecordExpense,
    required this.canAddReceipt,
    required this.canReviewApprovals,
    required this.canViewCompanyFinancials,
  });

  const DashboardPermissions.development()
    : canViewSchedule = true,
      canAddSchedule = true,
      canAddHistoricalEntry = true,
      canViewEntryDetails = true,
      canCreateEstimate = true,
      canCreateInvoice = true,
      canCreateJob = true,
      canRecordExpense = true,
      canAddReceipt = true,
      canReviewApprovals = true,
      canViewCompanyFinancials = true;

  final bool canViewSchedule;
  final bool canAddSchedule;
  final bool canAddHistoricalEntry;
  final bool canViewEntryDetails;
  final bool canCreateEstimate;
  final bool canCreateInvoice;
  final bool canCreateJob;
  final bool canRecordExpense;
  final bool canAddReceipt;
  final bool canReviewApprovals;
  final bool canViewCompanyFinancials;
}

class EmployeeStatus {
  const EmployeeStatus(this.id, this.name, this.status, this.icon, this.color);

  final String id;
  final String name;
  final String status;
  final IconData icon;
  final Color color;
}

class DashboardVehicle {
  const DashboardVehicle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}

class PlanItem {
  const PlanItem(
    this.time,
    this.title,
    this.detail,
    this.icon,
    this.color, {
    this.id = '',
    this.sourceRecordId,
    this.kind = PlanItemKind.jobStop,
    this.status = 'Scheduled',
  });

  final String id;
  final String? sourceRecordId;
  final PlanItemKind kind;
  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String status;

  PlanItem copyWith({String? time, String? status}) => PlanItem(
    time ?? this.time,
    title,
    detail,
    icon,
    color,
    id: id,
    sourceRecordId: sourceRecordId,
    kind: kind,
    status: status ?? this.status,
  );
}

enum PlanItemKind { jobStop, operationalTask }

enum DayEntryKind {
  jobActivity('Job activity', Icons.home_repair_service_outlined),
  workday('Workday', Icons.badge_outlined),
  trip('Trip', Icons.route_outlined),
  expense('Expense', Icons.receipt_long_outlined),
  estimate('Estimate', Icons.request_quote_outlined),
  invoice('Invoice', Icons.description_outlined),
  payment('Payment', Icons.payments_outlined),
  note('Work note', Icons.note_alt_outlined);

  const DayEntryKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum DayEntryReviewStatus {
  none('Recorded'),
  needsApproval('Needs approval'),
  approved('Approved'),
  denied('Not approved');

  const DayEntryReviewStatus(this.label);
  final String label;
}

class DayEntry {
  const DayEntry({
    required this.id,
    required this.time,
    required this.title,
    required this.detail,
    required this.kind,
    required this.color,
    this.customer,
    this.amount,
    this.odometer,
    this.reviewStatus = DayEntryReviewStatus.none,
    this.approvalReason,
    this.approvalExpectedAmount,
    this.approvalDifference,
    this.linkedRecord,
    this.sourceRecordId,
    this.submittedBy,
  });

  final String id;
  final String time;
  final String title;
  final String detail;
  final DayEntryKind kind;
  final Color color;
  final String? customer;
  final String? amount;
  final String? odometer;
  final DayEntryReviewStatus reviewStatus;
  final String? approvalReason;
  final String? approvalExpectedAmount;
  final String? approvalDifference;
  final String? linkedRecord;
  final String? sourceRecordId;
  final String? submittedBy;

  DayEntry copyWith({DayEntryReviewStatus? reviewStatus}) => DayEntry(
    id: id,
    time: time,
    title: title,
    detail: detail,
    kind: kind,
    color: color,
    customer: customer,
    amount: amount,
    odometer: odometer,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    approvalReason: approvalReason,
    approvalExpectedAmount: approvalExpectedAmount,
    approvalDifference: approvalDifference,
    linkedRecord: linkedRecord,
    sourceRecordId: sourceRecordId,
    submittedBy: submittedBy,
  );
}

class DashboardDayData {
  const DashboardDayData({this.plan = const [], this.entries = const []});

  final List<PlanItem> plan;
  final List<DayEntry> entries;
}

const demoEmployees = <EmployeeStatus>[
  EmployeeStatus(
    'alex',
    'Alex Morgan',
    'On a job',
    Icons.home_repair_service_outlined,
    Color(0xFF2D6680),
  ),
  EmployeeStatus(
    'jordan',
    'Jordan Lee',
    'Driving',
    Icons.directions_car_outlined,
    Color(0xFFA55B00),
  ),
  EmployeeStatus(
    'sam',
    'Sam Rivera',
    'Available',
    Icons.check_circle_outline,
    Color(0xFF087A4A),
  ),
  EmployeeStatus(
    'casey',
    'Casey Brooks',
    'On break',
    Icons.coffee_outlined,
    Color(0xFF79527A),
  ),
  EmployeeStatus(
    'taylor',
    'Taylor Kim',
    'Off duty',
    Icons.do_not_disturb_on_outlined,
    Color(0xFF65727A),
  ),
];

EmployeeStatus dashboardEmployeeById(String id) => demoEmployees.firstWhere(
  (employee) => employee.id == id,
  orElse: () => demoEmployees.first,
);

const demoVehicles = <DashboardVehicle>[
  DashboardVehicle(
    id: 'transit-12',
    name: 'Transit 12',
    description: '2021 Ford Transit',
    icon: Icons.airport_shuttle_outlined,
  ),
  DashboardVehicle(
    id: 'service-van-4',
    name: 'Service Van 4',
    description: '2019 Chevrolet Express',
    icon: Icons.airport_shuttle_outlined,
  ),
  DashboardVehicle(
    id: 'pickup-2',
    name: 'Pickup 2',
    description: '2020 Ford F-150',
    icon: Icons.local_shipping_outlined,
  ),
];

DashboardVehicle dashboardVehicleById(String id) => demoVehicles.firstWhere(
  (vehicle) => vehicle.id == id,
  orElse: () => demoVehicles.first,
);

String formatOdometerTenths(int readingTenths) {
  final whole = readingTenths ~/ 10;
  final fraction = readingTenths.remainder(10);
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '$buffer.$fraction';
}

const demoPlan = <PlanItem>[
  PlanItem(
    '8:00 AM',
    'Pick up faucet and job materials',
    'Central Supply · JOB-1038',
    Icons.inventory_2_outlined,
    Color(0xFFA55B00),
    id: 'pickup-job-1038',
    sourceRecordId: 'job-1038',
    kind: PlanItemKind.operationalTask,
  ),
  PlanItem(
    '10:30 AM',
    'Replace kitchen faucet',
    'Maya Thompson · 212 Oak Street',
    Icons.plumbing,
    Color(0xFF2D6680),
    id: 'job-1038',
    sourceRecordId: 'job-1038',
  ),
  PlanItem(
    '1:15 PM',
    'Follow up on water heater estimate',
    'Jordan Miller · EST-1041',
    Icons.request_quote_outlined,
    Color(0xFF087A4A),
    id: 'follow-up-est-1041',
    sourceRecordId: 'est-1041',
    kind: PlanItemKind.operationalTask,
  ),
  PlanItem(
    '3:00 PM',
    'Finish office lighting estimate',
    'Elena Garcia · EST-1040',
    Icons.electrical_services_outlined,
    Color(0xFF79527A),
    id: 'finish-est-1040',
    sourceRecordId: 'est-1040',
    kind: PlanItemKind.operationalTask,
  ),
  PlanItem(
    '4:30 PM',
    'Return unused job materials',
    'Central Supply · JOB-1038',
    Icons.assignment_return_outlined,
    Color(0xFF65727A),
    id: 'return-job-1038',
    sourceRecordId: 'job-1038',
    kind: PlanItemKind.operationalTask,
  ),
];

const demoEntries = <DayEntry>[
  DayEntry(
    id: 'expense-1047',
    time: '9:59 AM',
    title: 'QuickFuel',
    detail: 'Fuel purchase · Transit 12',
    kind: DayEntryKind.expense,
    color: Color(0xFFA55B00),
    amount: r'$64.72',
    reviewStatus: DayEntryReviewStatus.needsApproval,
    approvalReason:
        "This purchase is above Alex Morgan's \$50 field-expense limit.",
    approvalExpectedAmount: r'$50.00',
    approvalDifference: r'+$14.72',
    linkedRecord: 'Transit 12 · Field expense',
    sourceRecordId: 'EXP-1047',
    submittedBy: 'Alex Morgan',
  ),
  DayEntry(
    id: 'expense-1048',
    time: '10:44 AM',
    title: 'Central Supply',
    detail: 'Job materials · JOB-1038',
    kind: DayEntryKind.expense,
    color: Color(0xFF2D6680),
    amount: r'$231.50',
    linkedRecord: 'JOB-1038 · Replace kitchen faucet',
    sourceRecordId: 'EXP-1048',
    submittedBy: 'Alex Morgan',
  ),
  DayEntry(
    id: 'estimate-1041',
    time: '3:38 PM',
    title: 'Estimate sent',
    detail: 'Water heater safety inspection',
    kind: DayEntryKind.estimate,
    color: Color(0xFF79527A),
    customer: 'Jordan Miller',
    amount: r'$165.00',
    sourceRecordId: 'est-1041',
  ),
  DayEntry(
    id: 'invoice-2088',
    time: '4:12 PM',
    title: 'Invoice issued',
    detail: 'INV-2088 · Replace kitchen faucet',
    kind: DayEntryKind.invoice,
    color: Color(0xFF2D6680),
    customer: 'Maya Thompson',
    amount: r'$685.00',
    sourceRecordId: 'inv-2088',
  ),
  DayEntry(
    id: 'payment-319',
    time: '4:52 PM',
    title: 'Payment recorded',
    detail: 'Invoice INV-10319',
    kind: DayEntryKind.payment,
    color: Color(0xFF087A4A),
    customer: 'Miller property',
    amount: r'$385.00',
  ),
];

DashboardDayData demoDataFor(DateTime day, {String? employeeId}) {
  if (sameDashboardDay(day, dashboardToday)) {
    return const DashboardDayData(plan: demoPlan, entries: demoEntries);
  }
  final count = day.day % 3 + 1;
  if (day.isAfter(dashboardToday)) {
    return DashboardDayData(plan: demoPlan.take(count).toList());
  }
  final pastEntries = demoEntries.take(count + 1).map((entry) {
    if (entry.reviewStatus != DayEntryReviewStatus.needsApproval) return entry;
    return day.day % 7 == 0
        ? entry
        : entry.copyWith(reviewStatus: DayEntryReviewStatus.none);
  }).toList();
  return DashboardDayData(
    plan: demoPlan.take(count).toList(),
    entries: pastEntries,
  );
}

bool sameDashboardDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int dashboardTimeMinutes(String value) {
  final parts = value.trim().split(RegExp(r'[: ]'));
  if (parts.length < 3) return 1440;
  final parsedHour = int.tryParse(parts[0]);
  final parsedMinute = int.tryParse(parts[1]);
  if (parsedHour == null || parsedMinute == null) return 1440;
  var hour = parsedHour;
  final minute = parsedMinute;
  final period = parts[2].toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}
