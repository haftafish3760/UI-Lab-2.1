import 'package:flutter/material.dart';

import 'dashboard_models.dart';
import '../../data/work/models/work_models.dart';
import '../../data/work/work_status_history.dart';

/// Job plans are projections of the already-authorized Work read model.
/// Dashboard must never retain a second authoritative schedule or status.
DashboardDayData withWorkPlanProjections({
  required DashboardDayData data,
  required Iterable<WorkRecord> records,
  required DateTime day,
  String? employeeId,
}) {
  final employee = demoEmployees
      .where((employee) => employee.id == employeeId)
      .firstOrNull;
  final jobs =
      records.where((record) {
        if (record.kind != WorkRecordKind.job ||
            record.scheduledStart == null ||
            !record.occursOn(day)) {
          return false;
        }
        // Preserve the existing Work day creator/assignee filter. Names are a
        // transitional assignment representation, not an authorization boundary.
        return employeeId == null ||
            record.createdByEmployeeId == employeeId ||
            (employee != null && record.assignee == employee.name);
      }).toList()..sort((a, b) {
        final time = a.scheduledStart!.compareTo(b.scheduledStart!);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
  return DashboardDayData(
    plan: [
      ...data.plan.where((item) => item.kind != PlanItemKind.jobStop),
      for (final record in jobs) projectWorkPlan(record),
    ],
    entries: data.entries,
  );
}

PlanItem projectWorkPlan(WorkRecord record) {
  final start = record.scheduledStart!;
  final hour = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final time =
      '$hour:${start.minute.toString().padLeft(2, '0')} ${start.hour >= 12 ? 'PM' : 'AM'}';
  final location = record.serviceLocation.trim().isEmpty
      ? 'Location not assigned'
      : record.serviceLocation.replaceAll('\n', ', ');
  return PlanItem(
    time,
    record.title,
    '${record.client} · $location',
    Icons.home_repair_service_outlined,
    const Color(0xFF2D6680),
    id: record.id,
    sourceRecordId: record.id,
    status: record.status.label,
  );
}

DashboardDayData withWorkStatusProjections({
  required DashboardDayData data,
  required Iterable<WorkStatusEvent> events,
  required DateTime day,
  String? employeeId,
}) {
  final employee = demoEmployees
      .where((item) => item.id == employeeId)
      .firstOrNull;
  return DashboardDayData(
    plan: data.plan,
    entries: [
      ...data.entries.where((entry) => entry.kind != DayEntryKind.jobActivity),
      for (final event in events)
        if (sameDashboardDay(event.at.toLocal(), day) &&
            (employeeId == null ||
                event.record.createdByEmployeeId == employeeId ||
                (employee != null && event.record.assignee == employee.name)))
          projectWorkStatusEvent(event),
    ],
  );
}

DayEntry projectWorkStatusEvent(WorkStatusEvent event) {
  final local = event.at.toLocal();
  final arrived = event.record.status == WorkRecordStatus.arrived;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return DayEntry(
    id: event.id,
    sourceRecordId: event.record.id,
    time:
        '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}',
    title: arrived ? 'Arrived at job' : 'Job completed',
    detail: '${event.record.title} · ${event.record.client}',
    kind: DayEntryKind.jobActivity,
    color: arrived ? const Color(0xFF2D6680) : const Color(0xFF087A4A),
    submittedBy:
        demoEmployees
            .where((employee) => employee.id == event.actorId)
            .firstOrNull
            ?.name ??
        event.actorId,
  );
}
