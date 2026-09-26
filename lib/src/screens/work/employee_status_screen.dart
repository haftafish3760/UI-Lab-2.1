import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../data/work/employee_directory_profile.dart';
import '../../data/work/employee_work_status.dart';
import '../../data/work/models/work_models.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'job_assignment_editor_sheet.dart';
import 'job_workspace_screen.dart';
import 'employee_timesheet_screen.dart';

/// Work activity belongs here; private profile details stay in the menu.
class EmployeeStatusScreen extends StatelessWidget {
  const EmployeeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final directory = store.directorySession;
    if (directory?.permissions.canViewEmployees != true) {
      return const Scaffold(
        key: ValueKey('employee-status-screen'),
        body: Center(
          child: Text('Employee status is unavailable for this account.'),
        ),
      );
    }
    final employees =
        directory!.employees.where((person) => person.active).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      key: const ValueKey('employee-status-screen'),
      appBar: AppBar(title: const Text('Employee status')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 16, insets.right, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Status comes from saved jobs and workday records.',
                      ),
                      const SizedBox(height: 14),
                      if (employees.isEmpty)
                        const SectionCard(
                          child: Text('No active employees are saved.'),
                        )
                      else
                        SectionCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < employees.length;
                                index++
                              ) ...[
                                if (index > 0) const Divider(height: 1),
                                _employeeRow(context, store, employees[index]),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _employeeRow(
    BuildContext context,
    PrototypeOperationsStore store,
    EmployeeDirectoryProfile employee,
  ) {
    final work = store.workSession;
    final workday = store.workdaySession;
    final status = employeeWorkStatus(
      employeeId: employee.id,
      visibleJobs: work?.records ?? const <WorkRecord>[],
      visibleWorkdays: workday?.records.map((item) => item.record) ?? const [],
      now: DateTime.now(),
    );
    return ListTile(
      key: ValueKey('employee-status-${employee.id}'),
      title: Text(employee.name),
      subtitle: Text(
        work == null
            ? 'Job status unavailable'
            : workday == null && status.jobs.isEmpty
            ? 'Workday status unavailable'
            : status.label,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => EmployeeWorkStatusDetailScreen(employee: employee),
        ),
      ),
    );
  }
}

class EmployeeWorkStatusDetailScreen extends StatelessWidget {
  const EmployeeWorkStatusDetailScreen({required this.employee, super.key});

  final EmployeeDirectoryProfile employee;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final directory = store.directorySession;
    if (directory?.permissions.canViewEmployees != true ||
        !directory!.employees.any(
          (person) => person.id == employee.id && person.active,
        )) {
      return const Scaffold(
        body: Center(child: Text('This employee is unavailable.')),
      );
    }
    final work = store.workSession;
    final workday = store.workdaySession;
    final now = DateTime.now();
    final status = employeeWorkStatus(
      employeeId: employee.id,
      visibleJobs: work?.records ?? const <WorkRecord>[],
      visibleWorkdays: workday?.records.map((item) => item.record) ?? const [],
      now: now,
    );
    final canAssign = work?.permissions.canAssignJobs == true;
    return Scaffold(
      key: ValueKey('employee-work-status-${employee.id}'),
      appBar: AppBar(title: Text(employee.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 16, insets.right, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest recorded status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              work == null
                                  ? 'Job status unavailable'
                                  : workday == null && status.jobs.isEmpty
                                  ? 'Workday status unavailable'
                                  : status.label,
                            ),
                            if (status.runningLate) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'A scheduled job is past its planned end time.',
                              ),
                            ],
                            if (status.currentJob != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${status.currentJob!.number} · ${status.currentJob!.title}',
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              workday == null
                                  ? 'Workday hours unavailable'
                                  : status.workday == null &&
                                        status.recordedTime == Duration.zero
                                  ? 'No workday time recorded today'
                                  : 'Time recorded today: ${_duration(status.recordedTime)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (canAssign)
                        FilledButton.icon(
                          key: const ValueKey('assign-employee-work'),
                          onPressed: () => _chooseJob(context, store),
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: const Text('Assign work'),
                        ),
                      if (workday?.access.employeeIds.contains(employee.id) ==
                          true) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const ValueKey('view-employee-timesheet'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => EmployeeTimesheetScreen(
                                employeeId: employee.id,
                                employeeName: employee.name,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.access_time_rounded),
                          label: const Text('View timesheet'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Today’s jobs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SectionCard(
                        padding: EdgeInsets.zero,
                        child: status.jobs.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No assigned jobs are visible for today.',
                                ),
                              )
                            : Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < status.jobs.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const Divider(height: 1),
                                    ListTile(
                                      key: ValueKey(
                                        'employee-job-${status.jobs[index].id}',
                                      ),
                                      title: Text(status.jobs[index].title),
                                      subtitle: Text(
                                        '${status.jobs[index].client} · ${status.jobs[index].status.label}',
                                      ),
                                      trailing: canAssign
                                          ? IconButton(
                                              key: ValueKey(
                                                'change-employee-job-${status.jobs[index].id}',
                                              ),
                                              tooltip:
                                                  'Change employees on this job',
                                              onPressed: () =>
                                                  showModalBottomSheet<
                                                    WorkRecord
                                                  >(
                                                    context: context,
                                                    showDragHandle: true,
                                                    isScrollControlled: true,
                                                    builder: (_) =>
                                                        JobAssignmentEditorSheet(
                                                          record: status
                                                              .jobs[index],
                                                          work: work,
                                                        ),
                                                  ),
                                              icon: const Icon(
                                                Icons.group_outlined,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.chevron_right_rounded,
                                            ),
                                      onTap: () =>
                                          Navigator.of(context).push<void>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  JobWorkspaceScreen(
                                                    workRecord:
                                                        status.jobs[index],
                                                  ),
                                            ),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _chooseJob(
    BuildContext context,
    PrototypeOperationsStore store,
  ) async {
    final work = store.workSession;
    if (work == null || !work.permissions.canAssignJobs) return;
    final jobs = work.records
        .where(
          (record) =>
              record.kind == WorkRecordKind.job &&
              record.status != WorkRecordStatus.completed &&
              work.permissions.canEdit(record),
        )
        .toList();
    final chosen = await showModalBottomSheet<WorkRecord>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Choose a job to assign')),
            if (jobs.isEmpty)
              const ListTile(
                title: Text('No open jobs are available to assign.'),
              ),
            for (final job in jobs)
              ListTile(
                title: Text(job.title),
                subtitle: Text('${job.client} · ${job.number}'),
                onTap: () => Navigator.of(sheetContext).pop(job),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || chosen == null) return;
    await showModalBottomSheet<WorkRecord>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => JobAssignmentEditorSheet(
        record: chosen,
        work: work,
        initialEmployeeId: employee.id,
      ),
    );
  }

  String _duration(Duration value) =>
      '${value.inHours} hr ${value.inMinutes.remainder(60)} min';
}
