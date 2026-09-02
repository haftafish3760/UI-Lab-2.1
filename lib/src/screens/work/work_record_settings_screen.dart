import 'package:flutter/material.dart';

@immutable
class WorkRecordDisplayPreferences {
  const WorkRecordDisplayPreferences({
    this.showStatusDetails = true,
    this.showAssignments = true,
    this.includeClosedRecords = true,
  });

  final bool showStatusDetails;
  final bool showAssignments;
  final bool includeClosedRecords;
}

class WorkRecordSettingsScreen extends StatefulWidget {
  const WorkRecordSettingsScreen({
    required this.workspaceLabel,
    required this.initial,
    super.key,
  });

  final String workspaceLabel;
  final WorkRecordDisplayPreferences initial;

  @override
  State<WorkRecordSettingsScreen> createState() =>
      _WorkRecordSettingsScreenState();
}

class _WorkRecordSettingsScreenState extends State<WorkRecordSettingsScreen> {
  late var _showStatusDetails = widget.initial.showStatusDetails;
  late var _showAssignments = widget.initial.showAssignments;
  late var _includeClosedRecords = widget.initial.includeClosedRecords;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.workspaceLabel} settings')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        Text(
          'Choose what appears in the ${widget.workspaceLabel} list. These choices do not change records or permissions.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey('show-work-record-status-details'),
          title: const Text('Show status details'),
          subtitle: const Text('Shows the current state and supporting note.'),
          value: _showStatusDetails,
          onChanged: (value) => setState(() => _showStatusDetails = value),
        ),
        SwitchListTile(
          key: const ValueKey('show-work-record-assignments'),
          title: const Text('Show job assignments'),
          subtitle: const Text('Shows assigned employee and vehicle on jobs.'),
          value: _showAssignments,
          onChanged: (value) => setState(() => _showAssignments = value),
        ),
        SwitchListTile(
          key: const ValueKey('include-closed-work-records'),
          title: const Text('Include completed or paid records'),
          value: _includeClosedRecords,
          onChanged: (value) => setState(() => _includeClosedRecords = value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('save-work-record-settings'),
          onPressed: () => Navigator.pop(
            context,
            WorkRecordDisplayPreferences(
              showStatusDetails: _showStatusDetails,
              showAssignments: _showAssignments,
              includeClosedRecords: _includeClosedRecords,
            ),
          ),
          icon: const Icon(Icons.check_rounded),
          label: Text('Save ${widget.workspaceLabel} settings'),
        ),
      ],
    ),
  );
}
