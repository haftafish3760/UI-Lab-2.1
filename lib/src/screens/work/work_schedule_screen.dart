import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../shared/operations_workspace.dart';
import '../../theme/operational_card_palette.dart';
import 'work_models.dart';
import 'work_selected_date_bar.dart';
import 'work_month_calendar.dart';
import 'work_job_editor.dart';
import 'job_workspace_screen.dart';
import 'work_record_settings_screen.dart';

/// Scheduling projects authorized Job records; it never creates a second diary.
class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({required this.initialDay, super.key});
  final DateTime initialDay;
  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  late DateTime _day = DateUtils.dateOnly(widget.initialDay);
  String? _employee;
  var _fixturePreferences = const WorkRecordDisplayPreferences();
  WorkRecordDisplayPreferences get _preferences =>
      readWorkRecordDisplayPreferences(
        context,
        'scheduling',
        _fixturePreferences,
      );

  Future<void> _settings() async {
    final updated = await Navigator.of(context)
        .push<WorkRecordDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => WorkRecordSettingsScreen(
              workspaceId: 'scheduling',
              workspaceLabel: 'Scheduling',
              initial: _preferences,
            ),
          ),
        );
    if (updated != null && mounted) {
      setState(() => _fixturePreferences = updated);
    }
  }

  bool _onDay(WorkRecord job, DateTime day) {
    final start = job.scheduledStart;
    if (start == null) {
      return false;
    }
    final end = job.scheduledEnd;
    final midnight = DateUtils.dateOnly(day);
    return end == null
        ? DateUtils.isSameDay(start, day)
        : start.isBefore(midnight.add(const Duration(days: 1))) &&
              end.isAfter(midnight);
  }

  Future<void> _newJob() async {
    final store = PrototypeOperationsScope.of(context);
    final job = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(builder: (_) => WorkJobEditor(initialDay: _day)),
    );
    if (job != null && mounted) {
      final saved = await store.addWorkRecord(job);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The job was not saved. Reopen your draft and try again.',
            ),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _open(WorkRecord job) async {
    final store = PrototypeOperationsScope.of(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobWorkspaceScreen(
          workRecord: job,
          onWorkRecordUpdated: store.updateWorkRecord,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final jobs = store.workRecords
        .where(
          (r) =>
              r.kind == WorkRecordKind.job &&
              (_preferences.includeClosedRecords ||
                  r.status != WorkRecordStatus.completed) &&
              (_employee == null || r.assignedEmployeeIds.contains(_employee)),
        )
        .toList();
    final booked = jobs.where((r) => _onDay(r, _day)).toList()
      ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
    final waiting = jobs
        .where(
          (r) =>
              r.scheduledStart == null &&
              r.status != WorkRecordStatus.completed,
        )
        .toList();
    final employees = store.directorySession?.employees ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduling'),
        actions: [
          IconButton(
            tooltip: 'Scheduling settings',
            onPressed: _settings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.workFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return SingleChildScrollView(
            padding: insets.copyWith(top: 12, bottom: 24),
            child: Center(
              child: SizedBox(
                width: layout.workspaceWidth,
                child: OperationsLaneGrid(
                  layout: layout,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkSelectedDateBar(
                          selectedDay: _day,
                          onPrevious: () => setState(
                            () => _day = _day.subtract(const Duration(days: 1)),
                          ),
                          onNext: () => setState(
                            () => _day = _day.add(const Duration(days: 1)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _employee,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Assigned employee',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All employees'),
                            ),
                            for (final employee in employees)
                              DropdownMenuItem(
                                value: employee.id,
                                child: Text(employee.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _employee = value),
                        ),
                        const SizedBox(height: 12),
                        if (store.workSession?.permissions.editableKinds
                                .contains(WorkRecordKind.job) ??
                            false)
                          FilledButton.icon(
                            onPressed: _newJob,
                            icon: const Icon(Icons.add),
                            label: const Text('New job'),
                          ),
                        const SizedBox(height: 12),
                        _group(
                          'Scheduled jobs',
                          booked,
                          'No jobs scheduled for this day.',
                        ),
                        const SizedBox(height: 12),
                        _group(
                          'Needs scheduling',
                          waiting,
                          'No jobs waiting to be scheduled.',
                        ),
                      ],
                    ),
                    WorkMonthCalendar(
                      maximumWidth: AppLayoutEngine.calendarMaximum,
                      selectedDay: _day,
                      onDaySelected: (day) =>
                          setState(() => _day = DateUtils.dateOnly(day)),
                      entryCountForDay: (day) =>
                          jobs.where((r) => _onDay(r, day)).length,
                      recordKind: CalendarRecordKind.job,
                      needsApprovalForDay: (_) => false,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _group(String title, List<WorkRecord> records, String empty) {
    final tone = OperationalCardPalette.plan;
    return SectionCard(
      padding: const EdgeInsets.all(8),
      backgroundColor: tone.start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$title (${records.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: tone.foreground),
            ),
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(empty, style: TextStyle(color: tone.foreground)),
            ),
          for (final job in records)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: tone.row,
                child: ListTile(
                  title: Text(
                    job.client,
                    style: const TextStyle(
                      color: OperationalCardTone.darkInk,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    [
                      job.title,
                      '${job.number}${_preferences.showStatusDetails ? ' · ${job.status.label}' : ''}',
                      if (job.scheduledStart == null)
                        'Choose a date and employees'
                      else
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay.fromDateTime(job.scheduledStart!),
                        ),
                      if (_preferences.showAssignments)
                        job.assignee ?? 'Unassigned',
                    ].join('\n'),
                    style: const TextStyle(color: OperationalCardTone.darkInk),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: OperationalCardTone.darkInk,
                  ),
                  onTap: () => _open(job),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
