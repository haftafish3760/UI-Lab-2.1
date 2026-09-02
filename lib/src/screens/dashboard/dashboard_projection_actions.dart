part of 'dashboard_screen.dart';

extension _DashboardProjectionActions on _DashboardScreenState {
  void _projectJobToDashboard(WorkRecord record) {
    final scheduled = record.scheduledStart;
    final day = DateUtils.dateOnly(scheduled ?? _selectedDate);
    final employee = _employeeFor(
      OperationalScope.of(context).selectedEmployeeId,
    );
    final current = _dayDataFor(day, employee);
    final sourceId = record.id;
    final location = record.serviceLocation.trim().isEmpty
        ? 'Location not assigned'
        : record.serviceLocation.replaceAll('\n', ', ');
    final item = PlanItem(
      scheduled == null
          ? 'Time not set'
          : MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(scheduled)),
      record.title,
      '${record.client} · $location',
      Icons.home_repair_service_outlined,
      const Color(0xFF2D6680),
      id: sourceId,
      sourceRecordId: sourceId,
      status: record.status.label,
    );
    _saveDay(
      day,
      DashboardDayData(
        plan: [
          ...current.plan.where(
            (candidate) => candidate.sourceRecordId != sourceId,
          ),
          item,
        ],
        entries: current.entries,
      ),
    );
  }

  void _projectWorkDocumentToDashboard(WorkRecord record) {
    final day = DateUtils.dateOnly(record.createdOn ?? _selectedDate);
    final employee = _employeeFor(
      OperationalScope.of(context).selectedEmployeeId,
    );
    final current = _dayDataFor(day, employee);
    final sourceId = record.id;
    final kind = record.kind == WorkRecordKind.estimate
        ? DayEntryKind.estimate
        : DayEntryKind.invoice;
    final entry = DayEntry(
      id: 'dashboard-$sourceId',
      time: MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.now()),
      title: record.kind == WorkRecordKind.estimate
          ? 'Estimate created'
          : 'Invoice created',
      detail: '${record.number} · ${record.title}',
      kind: kind,
      color: record.kind == WorkRecordKind.estimate
          ? const Color(0xFF79527A)
          : const Color(0xFF2D6680),
      customer: record.client,
      amount: expenseMoney(record.total),
      sourceRecordId: sourceId,
    );
    _saveDay(
      day,
      DashboardDayData(
        plan: current.plan,
        entries: [
          ...current.entries.where(
            (candidate) => candidate.sourceRecordId != sourceId,
          ),
          entry,
        ],
      ),
    );
  }
}
