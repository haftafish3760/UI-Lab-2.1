import 'package:flutter/widgets.dart';

import '../../screens/dashboard/dashboard_models.dart';
import 'workday_persistence_session.dart';
import 'stored_workday_record.dart';

/// Projects confirmed events; no dashboard-owned copy or write is created.
DashboardDayData withWorkdayProjections({
  required DashboardDayData data,
  required WorkdayPersistenceSession session,
  required DateTime day,
  String? employeeId,
}) {
  final events = <(DateTime, DayEntry)>[];
  for (final snapshot in session.records) {
    final record = snapshot.record;
    if (employeeId != null && record.employeeId != employeeId) continue;
    for (final ended in [false, true]) {
      final event = projectWorkdayEvent(record, ended: ended);
      if (event != null && sameDashboardDay(event.$1, day)) events.add(event);
    }
  }
  events.sort((a, b) => a.$1.compareTo(b.$1));
  return DashboardDayData(
    plan: data.plan,
    entries: [
      // Live workday entries always come from their owner, including an empty or
      // unavailable scoped query. Do not leak fixture/cached entries on reload.
      ...data.entries.where((entry) => entry.kind != DayEntryKind.workday),
      ...events.map((event) => event.$2),
    ],
  );
}

/// A closed event exists only when the confirmed workday contains its instant.
(DateTime, DayEntry)? projectWorkdayEvent(
  StoredWorkdayRecord record, {
  required bool ended,
}) {
  final instant = ended ? record.endedAt : record.startedAt;
  if (instant == null) return null;
  final local = instant.toLocal();
  final vehicle = demoVehicles
      .where((vehicle) => vehicle.id == record.vehicleId)
      .firstOrNull;
  final employee = demoEmployees
      .where((employee) => employee.id == record.employeeId)
      .firstOrNull;
  final reading = ended
      ? record.currentOdometerTenths
      : record.startOdometerTenths;
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return (
    local,
    DayEntry(
      id: 'workday-${record.id}-${ended ? 'ended' : 'started'}',
      sourceRecordId: record.id,
      time: '$hour:${local.minute.toString().padLeft(2, '0')} $period',
      title: ended ? 'Workday ended' : 'Workday started',
      detail: vehicle?.name ?? record.vehicleId,
      submittedBy: employee?.name ?? record.employeeId,
      kind: DayEntryKind.workday,
      color: ended ? const Color(0xFF65727A) : const Color(0xFF087A4A),
      odometer: '${formatOdometerTenths(reading)} mi',
    ),
  );
}
