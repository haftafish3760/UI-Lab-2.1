// ignore_for_file: invalid_use_of_protected_member

part of 'dashboard_screen.dart';

extension _DashboardScreenActions on _DashboardScreenState {
  Future<void> _handlePlanAction(PlanItem item, PlanAction action) async {
    if (!_DashboardScreenState._permissions.canAddSchedule) return;
    switch (action) {
      case PlanAction.viewDetails:
        _openPlan(item);
      case PlanAction.markArrived:
        if (item.kind != PlanItemKind.jobStop) return;
        _updatePlanStatus(item, 'Arrived');
      case PlanAction.reschedule:
        await _reschedulePlanItem(item);
      case PlanAction.markComplete:
        _updatePlanStatus(item, 'Completed');
    }
  }

  void _updatePlanStatus(PlanItem item, String status) {
    final store = PrototypeOperationsScope.of(context);
    final sourceId = item.sourceRecordId ?? item.id;
    final sourceRecord = store.workRecords
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (item.kind == PlanItemKind.jobStop &&
        sourceRecord?.kind == WorkRecordKind.job) {
      store.updateWorkRecord(
        sourceRecord!.copyWith(
          status: status == 'Arrived'
              ? WorkRecordStatus.arrived
              : WorkRecordStatus.completed,
        ),
      );
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: dashboardToday.subtract(const Duration(days: 365)),
      lastDate: dashboardToday.add(const Duration(days: 730)),
      helpText: 'Choose the new work date',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _timeFromLabel(item.time),
      helpText: 'Choose the new arrival time',
    );
    if (!mounted || time == null) return;
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
      store.updateWorkRecord(
        sourceRecord.copyWith(
          scheduledStart: scheduledStart,
          scheduledEnd: scheduledStart.add(duration),
          status: WorkRecordStatus.scheduled,
        ),
      );
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

  Future<void> _startWorkday() async {
    final result = await Navigator.of(context).push<StartWorkdayResult>(
      MaterialPageRoute(builder: (_) => const StartWorkdayScreen()),
    );
    if (!mounted || result == null || _workday != null) return;
    final session = DashboardWorkdaySession.start(result);
    final employee = _employeeFor(
      OperationalScope.of(context).selectedEmployeeId,
    );
    final current = _dayData(employee);
    final started = DayEntry(
      id: 'workday-started-${session.startedAt.microsecondsSinceEpoch}',
      time: MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(TimeOfDay.fromDateTime(session.startedAt)),
      title: 'Workday started',
      detail: session.vehicleLabel,
      kind: DayEntryKind.workday,
      color: const Color(0xFF087A4A),
      odometer: '${formatOdometerTenths(session.startOdometerTenths)} mi',
    );
    _saveDay(
      dashboardToday,
      DashboardDayData(
        plan: current.plan,
        entries: [...current.entries, started],
      ),
    );
    setState(() => _workday = session);
  }

  Future<void> _openWorkdayActions() async {
    final session = _workday;
    if (session == null) return;
    final action = await Navigator.of(context).push<DashboardWorkdayAction>(
      MaterialPageRoute(
        builder: (_) => WorkdayActionsScreen(
          session: session,
          enabledActions: _enabledWorkdayActions,
        ),
      ),
    );
    if (!mounted || action == null || _workday == null) return;
    switch (action) {
      case DashboardWorkdayAction.pauseOrResume:
        setState(() => _workday = _workday!.togglePause());
        return;
      case DashboardWorkdayAction.endDay:
        await _endWorkday();
        return;
      case DashboardWorkdayAction.addStop:
        await _addScheduleItem();
        return;
      case DashboardWorkdayAction.addFuel:
        await _recordDashboardExpense(initialCategory: ExpenseCategory.fuel);
        return;
      case DashboardWorkdayAction.addExpense:
        await _recordDashboardExpense();
        return;
      case DashboardWorkdayAction.addReceipt:
        await _openReceiptIntake(dashboardToday);
        return;
      case DashboardWorkdayAction.addNote:
        await _addDayEntry();
        return;
      case DashboardWorkdayAction.createEstimate:
        await _createDashboardDocument(WorkRecordKind.estimate);
        return;
      case DashboardWorkdayAction.configureActions:
        await _openDashboardSettings();
        return;
    }
  }

  Future<void> _openDashboardSettings() async {
    final result = await Navigator.of(context)
        .push<Set<DashboardWorkdayAction>>(
          MaterialPageRoute(
            builder: (_) =>
                DashboardSettingsScreen(enabledActions: _enabledWorkdayActions),
          ),
        );
    if (!mounted || result == null) return;
    setState(() => _enabledWorkdayActions = Set.of(result));
  }

  Future<void> _endWorkday() async {
    final session = _workday;
    if (session == null) return;
    final scope = OperationalScope.of(context);
    final reading = await showDialog<int>(
      context: context,
      builder: (context) => _EndWorkdayDialog(
        initialOdometerTenths: scope.confirmedOdometerTenthsFor(
          session.vehicleId,
        ),
        minimumOdometerTenths: session.startOdometerTenths,
      ),
    );
    if (!mounted || reading == null) return;
    scope.confirmOdometer(vehicleId: session.vehicleId, readingTenths: reading);
    final current = _dayData(_employeeFor(scope.selectedEmployeeId));
    final ended = DayEntry(
      id: 'workday-ended-${DateTime.now().microsecondsSinceEpoch}',
      time: MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.now()),
      title: 'Workday ended',
      detail: '${session.vehicleLabel} · ${formatOdometerTenths(reading)} mi',
      kind: DayEntryKind.workday,
      color: const Color(0xFF65727A),
      odometer: '${formatOdometerTenths(reading)} mi',
    );
    _saveDay(
      dashboardToday,
      DashboardDayData(
        plan: current.plan,
        entries: [...current.entries, ended],
      ),
    );
    setState(() => _workday = null);
  }

  Future<void> _showAddActions() async {
    final action = await Navigator.of(context).push<DashboardAddAction>(
      MaterialPageRoute(
        builder: (_) => DashboardAddActionsScreen(
          day: _selectedDate,
          actions: _availableAddActions,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case DashboardAddAction.schedule:
        await _addScheduleItem();
      case DashboardAddAction.job:
        await _createDashboardJob();
      case DashboardAddAction.estimate:
        await _createDashboardDocument(WorkRecordKind.estimate);
      case DashboardAddAction.invoice:
        await _createDashboardDocument(WorkRecordKind.invoice);
      case DashboardAddAction.expense:
        await _recordDashboardExpense();
      case DashboardAddAction.fuel:
        await _recordDashboardExpense(initialCategory: ExpenseCategory.fuel);
      case DashboardAddAction.receipt:
        await _openReceiptIntake(_selectedDate);
      case DashboardAddAction.dayRecord:
        await _addDayEntry();
    }
  }

  Future<void> _createDashboardJob() async {
    final record = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => WorkJobEditor(initialDay: _selectedDate),
      ),
    );
    if (!mounted || record == null) return;
    PrototypeOperationsScope.of(context).addWorkRecord(record);
    _projectJobToDashboard(record);
  }

  Future<void> _createDashboardDocument(WorkRecordKind type) async {
    if (type == WorkRecordKind.estimate) {
      final employeeId = OperationalScope.of(context).selectedEmployeeId;
      final record = await Navigator.of(context).push<WorkRecord>(
        MaterialPageRoute(
          builder: (_) => EstimateEditorScreen(
            initialDay: _selectedDate,
            createdByEmployeeId: employeeId,
          ),
        ),
      );
      if (!mounted || record == null) return;
      PrototypeOperationsScope.of(context).addWorkRecord(record);
      _projectWorkDocumentToDashboard(record);
      return;
    }
    final invoice = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          initialDay: _selectedDate,
          createdByEmployeeId:
              OperationalScope.of(context).selectedEmployeeId ??
              demoEmployees.first.id,
        ),
      ),
    );
    if (!mounted || invoice == null) return;
    PrototypeOperationsScope.of(context).addWorkRecord(invoice);
    _projectWorkDocumentToDashboard(invoice);
  }

  Future<void> _recordDashboardExpense({
    ExpenseCategory initialCategory = ExpenseCategory.materials,
  }) async {
    if (!_DashboardScreenState._permissions.canRecordExpense) return;
    final permissions = expensePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (!permissions.canCreate) return;
    final record = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(
          expenseDate: _selectedDate,
          initialCategory: initialCategory,
          permissions: permissions,
        ),
      ),
    );
    if (!mounted || record == null) return;
    final saved = await PrototypeOperationsScope.of(context).addExpense(record);
    if (!mounted || saved == null) return;
  }

  Future<void> _addScheduleItem() => _createDashboardJob();

  Future<void> _openReceiptIntake(DateTime day) async {
    if (!_DashboardScreenState._permissions.canAddReceipt) return;
    final permissions = expensePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (!permissions.canAttachReceipt) return;
    final record = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) =>
            ReceiptIntakeScreen(expenseDate: day, permissions: permissions),
      ),
    );
    if (!mounted || record == null) return;
  }

  Future<void> _addDayEntry() async {
    final title = await _askForTitle('Add day record', 'Record description');
    if (!mounted || title == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Choose the record time',
    );
    if (!mounted || time == null) return;
    final current = _dayData(
      _employeeFor(OperationalScope.of(context).selectedEmployeeId),
    );
    final entry = DayEntry(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      time: MaterialLocalizations.of(context).formatTimeOfDay(time),
      title: title,
      detail: 'Manually added record',
      kind: DayEntryKind.note,
      color: const Color(0xFF65727A),
    );
    _saveDay(
      _selectedDate,
      DashboardDayData(
        plan: current.plan,
        entries: [...current.entries, entry],
      ),
    );
  }

  Future<String?> _askForTitle(String title, String label) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }
}

String _dashboardContextId(OperationalScopeController scope) =>
    scope.view == AppViewMode.admin
    ? scope.selectedEmployeeId ?? 'company'
    : scope.selectedEmployeeId ?? 'technician';

TimeOfDay _timeFromLabel(String label) {
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
