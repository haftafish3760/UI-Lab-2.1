import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/workday/stored_workday_record.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';

/// Read-only confirmed workday time. A correction request and reviewer workflow
/// must be added before any employee-facing edit control is offered here.
class EmployeeTimesheetScreen extends StatelessWidget {
  const EmployeeTimesheetScreen({
    required this.employeeId,
    this.employeeName,
    super.key,
  });

  final String employeeId;
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final session = PrototypeOperationsScope.of(context).workdaySession;
    if (session == null || !session.access.employeeIds.contains(employeeId)) {
      return const Scaffold(
        key: ValueKey('employee-timesheet-screen'),
        body: Center(child: Text('Recorded work time is unavailable.')),
      );
    }
    final records =
        session.records
            .map((item) => item.record)
            .where((record) => record.employeeId == employeeId)
            .toList()
          ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return Scaffold(
      key: const ValueKey('employee-timesheet-screen'),
      appBar: AppBar(
        title: Text(
          employeeName == null ? 'My timesheet' : '$employeeName · Timesheet',
        ),
      ),
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
                        'Recorded work time',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Time from saved workdays. Open workdays keep counting until ended. This is not a payroll calculation.',
                      ),
                      const SizedBox(height: 14),
                      if (records.isEmpty)
                        const SectionCard(
                          child: Text('No workday time has been recorded yet.'),
                        )
                      else
                        SectionCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < records.length;
                                index++
                              ) ...[
                                if (index > 0) const Divider(height: 1),
                                _timeRow(context, records[index]),
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

  Widget _timeRow(BuildContext context, StoredWorkdayRecord record) {
    final now = DateTime.now();
    final localStart = record.startedAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(localStart);
    final started = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localStart));
    final duration = record.elapsedAt(now);
    final state = switch (record.status) {
      StoredWorkdayStatus.active => 'In progress',
      StoredWorkdayStatus.paused => 'Paused',
      StoredWorkdayStatus.ended => 'Finished',
    };
    return ListTile(
      key: ValueKey('timesheet-workday-${record.id}'),
      title: Text(date),
      subtitle: Text('Started $started · $state'),
      trailing: Text(
        '${duration.inHours} hr ${duration.inMinutes.remainder(60)} min',
      ),
    );
  }
}
