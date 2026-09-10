part of 'dashboard_day_screen.dart';

extension _DashboardDayRecordActions on _DashboardDayScreenState {
  void _openPlan(PlanItem item) {
    DashboardRecordNavigation.openPlan(
      context,
      item,
      onCreateJob: _createJobFromEstimate,
    );
  }

  Future<void> _openEntry(DayEntry entry, String contextId) async {
    if (entry.sourceRecordId != null) {
      await DashboardRecordNavigation.openEntry(
        context,
        entry,
        date: _day,
        showOdometer: true,
        onCreateJob: _createJobFromEstimate,
      );
      return;
    }
    if (entry.reviewStatus == DayEntryReviewStatus.needsApproval) {
      await _reviewLocalEntry(entry, contextId);
      return;
    }
    await DashboardRecordNavigation.openEntry(
      context,
      entry,
      date: _day,
      showOdometer: true,
      onCreateJob: _createJobFromEstimate,
    );
  }

  Future<void> _reviewEntry(DayEntry entry, String contextId) async {
    if (entry.sourceRecordId != null) {
      await _openEntry(entry, contextId);
      return;
    }
    await _reviewLocalEntry(entry, contextId);
  }

  Future<void> _reviewLocalEntry(DayEntry entry, String contextId) async {
    if (!_DashboardDayScreenState._permissions.canReviewApprovals) return;
    final result = await Navigator.of(context).push<DayEntryReviewStatus>(
      MaterialPageRoute<DayEntryReviewStatus>(
        builder: (_) => CalendarApprovalScreen(entry: entry),
      ),
    );
    if (!mounted || result == null) return;
    _replaceEntryReview(entry.id, result, contextId);
  }

  void _replaceEntryReview(
    String entryId,
    DayEntryReviewStatus status,
    String contextId,
  ) {
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final store = PrototypeOperationsScope.of(context);
    final current = store.dashboardDay(
      day: _day,
      contextId: contextId,
      employeeId: employee?.id,
    );
    store.updateDashboardDay(
      day: _day,
      contextId: contextId,
      data: DashboardDayData(
        plan: current.plan,
        entries: [
          for (final candidate in current.entries)
            candidate.id == entryId
                ? candidate.copyWith(reviewStatus: status)
                : candidate,
        ],
      ),
    );
  }

  Future<void> _createScheduledJob() async {
    final record = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(builder: (_) => WorkJobEditor(initialDay: _day)),
    );
    if (!mounted || record == null) return;
    final store = PrototypeOperationsScope.of(context);
    store.addWorkRecord(record);
    _projectJob(record);
  }

  Future<void> _createJobFromEstimate(WorkRecord estimate) async {
    final record = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(
          sourceEstimate: estimate,
          initialDay: estimate.estimateDates?.proposedServiceOn ?? _day,
        ),
      ),
    );
    if (!mounted || record == null) return;
    final store = PrototypeOperationsScope.of(context);
    store.addWorkRecord(record);
    store.updateWorkRecord(
      estimate.withEstimateStage(EstimateStage.converted, DateTime.now()),
    );
    _projectJob(record);
  }

  void _projectJob(WorkRecord record) {
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final contextId = _contextId(scope);
    final store = PrototypeOperationsScope.of(context);
    final scheduled = record.scheduledStart;
    final day = DateUtils.dateOnly(scheduled ?? _day);
    final current = store.dashboardDay(
      day: day,
      contextId: contextId,
      employeeId: employee?.id,
    );
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
      id: record.id,
      sourceRecordId: record.id,
      status: record.status.label,
    );
    store.updateDashboardDay(
      day: day,
      contextId: contextId,
      data: DashboardDayData(
        plan: [
          ...current.plan.where(
            (candidate) => candidate.sourceRecordId != record.id,
          ),
          item,
        ],
        entries: current.entries,
      ),
    );
  }

  Future<void> _handleDayPlanAction(PlanItem item, PlanAction action) async {
    switch (action) {
      case PlanAction.viewDetails:
        _openPlan(item);
      case PlanAction.markArrived:
        if (item.kind == PlanItemKind.jobStop) {
          await _updateDayPlanStatus(item, 'Arrived');
        }
      case PlanAction.reschedule:
        await _rescheduleDayPlanItem(item);
      case PlanAction.markComplete:
        await _updateDayPlanStatus(item, 'Completed');
    }
  }

  Future<void> _updateDayPlanStatus(PlanItem item, String status) async {
    final actionDay = _day;
    final actionContext = _contextId(OperationalScope.of(context));
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final contextId = _contextId(scope);
    final store = PrototypeOperationsScope.of(context);
    final current = store.dashboardDay(
      day: _day,
      contextId: contextId,
      employeeId: employee?.id,
    );
    final sourceId = item.sourceRecordId ?? item.id;
    final record = store.workRecords
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (item.kind == PlanItemKind.jobStop &&
        record?.kind != WorkRecordKind.job) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is no longer available.')),
      );
      return;
    }
    if (item.kind == PlanItemKind.jobStop &&
        record?.kind == WorkRecordKind.job) {
      final saved = await store.updateWorkRecord(
        record!.copyWith(
          status: status == 'Arrived'
              ? WorkRecordStatus.arrived
              : WorkRecordStatus.completed,
        ),
      );
      if (!mounted) return;
      if (_day != actionDay ||
          _contextId(OperationalScope.of(context)) != actionContext) {
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
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.now());
    store.updateDashboardDay(
      day: _day,
      contextId: contextId,
      data: DashboardDayData(
        plan: [
          for (final candidate in current.plan)
            candidate.id == item.id
                ? candidate.copyWith(status: status)
                : candidate,
        ],
        entries: [
          ...current.entries,
          DayEntry(
            id: 'day-$status-${DateTime.now().microsecondsSinceEpoch}',
            time: time,
            title: status == 'Arrived'
                ? 'Arrived at job'
                : item.kind == PlanItemKind.jobStop
                ? 'Job completed'
                : 'Task completed',
            detail: item.title,
            kind: DayEntryKind.note,
            color: status == 'Arrived'
                ? const Color(0xFF2D6680)
                : const Color(0xFF087A4A),
            sourceRecordId: item.kind == PlanItemKind.jobStop
                ? item.sourceRecordId
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _rescheduleDayPlanItem(PlanItem item) async {
    if (item.kind == PlanItemKind.jobStop &&
        PrototypeOperationsScope.of(context).workSession != null) {
      await DashboardRecordNavigation.rescheduleJob(context, item);
      return;
    }

    final actionDay = _day;
    final actionContext = _contextId(OperationalScope.of(context));
    final date = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: dashboardToday.subtract(const Duration(days: 365)),
      lastDate: dashboardToday.add(const Duration(days: 730)),
      helpText: 'Choose the new work date',
    );
    if (!mounted || date == null) return;
    if (_day != actionDay ||
        _contextId(OperationalScope.of(context)) != actionContext) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: _calendarTimeFromLabel(item.time),
      helpText: 'Choose the new arrival time',
    );
    if (!mounted || time == null) return;
    if (_day != actionDay ||
        _contextId(OperationalScope.of(context)) != actionContext) {
      return;
    }
    final scope = OperationalScope.of(context);
    final employee = _employeeFor(scope.selectedEmployeeId);
    final contextId = _contextId(scope);
    final store = PrototypeOperationsScope.of(context);
    final source = store.dashboardDay(
      day: _day,
      contextId: contextId,
      employeeId: employee?.id,
    );
    final target = store.dashboardDay(
      day: date,
      contextId: contextId,
      employeeId: employee?.id,
    );
    final updated = item.copyWith(
      time: MaterialLocalizations.of(context).formatTimeOfDay(time),
      status: 'Scheduled',
    );
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
      if (_day != actionDay ||
          _contextId(OperationalScope.of(context)) != actionContext) {
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
    store.updateDashboardDay(
      day: _day,
      contextId: contextId,
      data: DashboardDayData(
        plan: source.plan
            .where((candidate) => candidate.id != item.id)
            .toList(),
        entries: source.entries,
      ),
    );
    store.updateDashboardDay(
      day: date,
      contextId: contextId,
      data: DashboardDayData(
        plan: [
          ...target.plan.where((candidate) => candidate.id != item.id),
          updated,
        ],
        entries: target.entries,
      ),
    );
  }
}

TimeOfDay _calendarTimeFromLabel(String label) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  ).firstMatch(label.trim().toUpperCase());
  if (match == null) return TimeOfDay.now();
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!;
  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;
  return TimeOfDay(hour: hour, minute: minute);
}
