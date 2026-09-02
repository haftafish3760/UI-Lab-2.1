import 'package:flutter/material.dart';

@immutable
class WorkDisplayPreferences {
  const WorkDisplayPreferences({
    this.showEmployeeCards = true,
    this.showDailySummaries = true,
    this.includeCompletedWork = true,
  });

  final bool showEmployeeCards;
  final bool showDailySummaries;
  final bool includeCompletedWork;

  WorkDisplayPreferences copyWith({
    bool? showEmployeeCards,
    bool? showDailySummaries,
    bool? includeCompletedWork,
  }) => WorkDisplayPreferences(
    showEmployeeCards: showEmployeeCards ?? this.showEmployeeCards,
    showDailySummaries: showDailySummaries ?? this.showDailySummaries,
    includeCompletedWork: includeCompletedWork ?? this.includeCompletedWork,
  );
}

class WorkSettingsScreen extends StatefulWidget {
  const WorkSettingsScreen({required this.initial, super.key});

  final WorkDisplayPreferences initial;

  @override
  State<WorkSettingsScreen> createState() => _WorkSettingsScreenState();
}

class _WorkSettingsScreenState extends State<WorkSettingsScreen> {
  late var _draft = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Work settings')),
    body: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'Choose what appears on Work home',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'These choices change presentation only. They do not change access, assignments, records, or the required Work calendar.',
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          key: const ValueKey('show-work-employee-cards'),
          value: _draft.showEmployeeCards,
          title: const Text('Show employee status cards'),
          subtitle: const Text(
            'Shown in Admin view for quick employee selection and status.',
          ),
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(showEmployeeCards: value),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('show-work-daily-summaries'),
          value: _draft.showDailySummaries,
          title: const Text('Show daily Jobs, Estimates, and Invoices'),
          subtitle: const Text(
            'The labeled Work shortcuts and required Work calendar remain visible.',
          ),
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(showDailySummaries: value),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('show-completed-work'),
          value: _draft.includeCompletedWork,
          title: const Text('Include completed work in daily summaries'),
          subtitle: const Text(
            'Completed records remain available from Jobs and Calendar Day.',
          ),
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(includeCompletedWork: value),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey('save-work-settings'),
          onPressed: () => Navigator.of(context).pop(_draft),
          child: const Text('Save Work settings'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () =>
              setState(() => _draft = const WorkDisplayPreferences()),
          child: const Text('Reset to recommended'),
        ),
      ],
    ),
  );
}
