// ignore_for_file: invalid_use_of_protected_member

part of 'dashboard_screen.dart';

extension _DashboardPlanActions on _DashboardScreenState {
  Future<void> _handlePlanAction(PlanItem item, PlanAction action) async {
    if (!_DashboardScreenState._permissions.canAddSchedule) return;
    switch (action) {
      case PlanAction.viewDetails:
        _openPlan(item);
      case PlanAction.markArrived:
        if (item.kind != PlanItemKind.jobStop) return;
        await _updatePlanStatus(item, 'Arrived');
      case PlanAction.reschedule:
        await _reschedulePlanItem(item);
      case PlanAction.markComplete:
        await _updatePlanStatus(item, 'Completed');
    }
  }

  Future<void> _updatePlanStatus(PlanItem item, String status) async {
    final actionDay = _selectedDate;
    final actionContext = _dashboardContextId(OperationalScope.of(context));
    final store = PrototypeOperationsScope.of(context);
    final sourceId = item.sourceRecordId ?? item.id;
    final sourceRecord = store.workRecords
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (item.kind == PlanItemKind.jobStop &&
        sourceRecord?.kind != WorkRecordKind.job) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    if (item.kind == PlanItemKind.jobStop &&
        sourceRecord?.kind == WorkRecordKind.job) {
      final saved = await store.updateWorkRecord(
        sourceRecord!.copyWith(
          status: status == 'Arrived'
              ? WorkRecordStatus.arrived
              : WorkRecordStatus.completed,
        ),
      );
      if (!mounted) return;
      if (_selectedDate != actionDay ||
          _dashboardContextId(OperationalScope.of(context)) != actionContext) {
        return;
      }
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The job could not be saved. Its existing schedule and status are unchanged.',
            ),
          ),
        );
        return;
      }
      if (store.workSession != null) return;
    }
    final employee = _employeeFor(
      OperationalScope.of(context).selectedEmployeeId,
    );
    final current = _dayData(employee);
    final updatedPlan = [
      for (final candidate in current.plan)
        if (candidate.id == item.id)
          candidate.copyWith(status: status)
        else
          candidate,
    ];
    final entry = DayEntry(
      id: '${status.toLowerCase()}-${item.id}-${DateTime.now().microsecondsSinceEpoch}',
      time: MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.now()),
      title: status == 'Arrived'
          ? 'Arrived at job'
          : item.kind == PlanItemKind.jobStop
          ? 'Job completed'
          : 'Task completed',
      detail: '${item.title} · ${item.detail}',
      kind: DayEntryKind.note,
      color: status == 'Arrived'
          ? const Color(0xFF2D6680)
          : const Color(0xFF087A4A),
    );
    _saveDay(
      _selectedDate,
      DashboardDayData(plan: updatedPlan, entries: [...current.entries, entry]),
    );
  }

  Future<void> _reschedulePlanItem(PlanItem item) async {
    if (item.kind == PlanItemKind.jobStop &&
        PrototypeOperationsScope.of(context).workSession != null) {
      await DashboardRecordNavigation.rescheduleJob(context, item);
      return;
    }

    final actionDay = _selectedDate;
    final actionContext = _dashboardContextId(OperationalScope.of(context));
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: dashboardToday.subtract(const Duration(days: 365)),
      lastDate: dashboardToday.add(const Duration(days: 730)),
      helpText: 'Choose the new work date',
    );
    if (!mounted || date == null) return;
    if (_selectedDate != actionDay ||
        _dashboardContextId(OperationalScope.of(context)) != actionContext) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: _timeFromLabel(item.time),
      helpText: 'Choose the new arrival time',
    );
    if (!mounted || time == null) return;
    if (_selectedDate != actionDay ||
        _dashboardContextId(OperationalScope.of(context)) != actionContext) {
      return;
    }
    final employee = _employeeFor(
      OperationalScope.of(context).selectedEmployeeId,
    );
    final source = _dayData(employee);
    final target = _dayDataFor(date, employee);
    final updated = item.copyWith(
      time: MaterialLocalizations.of(context).formatTimeOfDay(time),
      status: 'Scheduled',
    );
    final store = PrototypeOperationsScope.of(context);
    final sourceId = item.sourceRecordId ?? item.id;
    final sourceRecord = store.workRecords
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (item.kind == PlanItemKind.jobStop &&
        sourceRecord?.kind != WorkRecordKind.job) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    if (item.kind == PlanItemKind.jobStop &&
        sourceRecord?.kind == WorkRecordKind.job) {
      final oldStart = sourceRecord!.scheduledStart;
      final oldEnd = sourceRecord.scheduledEnd;
      final duration = oldStart != null && oldEnd != null
          ? oldEnd.difference(oldStart)
          : const Duration(hours: 2);
      final scheduledStart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      final saved = await store.updateWorkRecord(
        sourceRecord.copyWith(
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledStart.add(duration),
          status: WorkRecordStatus.scheduled,
        ),
      );
      if (!mounted) return;
      if (_selectedDate != actionDay ||
          _dashboardContextId(OperationalScope.of(context)) != actionContext) {
        return;
      }
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The job could not be saved. Its existing schedule and status are unchanged.',
            ),
          ),
        );
        return;
      }
      if (store.workSession != null) return;
    }
    if (sameDashboardDay(date, _selectedDate)) {
      _saveDay(
        _selectedDate,
        DashboardDayData(
          plan: [
            for (final candidate in source.plan)
              if (candidate.id == item.id) updated else candidate,
          ],
          entries: source.entries,
        ),
      );
    } else {
      _saveDay(
        _selectedDate,
        DashboardDayData(
          plan: source.plan
              .where((candidate) => candidate.id != item.id)
              .toList(),
          entries: source.entries,
        ),
      );
      _saveDay(
        date,
        DashboardDayData(
          plan: [
            ...target.plan.where((candidate) => candidate.id != item.id),
            updated,
          ],
          entries: target.entries,
        ),
      );
    }
  }
}
