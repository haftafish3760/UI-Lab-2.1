part of 'dashboard_screen.dart';

extension _DashboardManualEntryActions on _DashboardScreenState {
  Future<void> _addDayEntry() async {
    if (await DashboardRecordNavigation.openStoredDayNoteEditor(
      context,
      _selectedDate,
    )) {
      return;
    }
    if (!mounted) return;
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
}
