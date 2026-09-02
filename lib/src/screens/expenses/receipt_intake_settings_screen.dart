import 'package:flutter/material.dart';

@immutable
class ReceiptIntakeDisplayPreferences {
  const ReceiptIntakeDisplayPreferences({
    this.showReviewChecklist = true,
    this.showEvidenceReminders = true,
  });

  final bool showReviewChecklist;
  final bool showEvidenceReminders;
}

class ReceiptIntakeSettingsScreen extends StatefulWidget {
  const ReceiptIntakeSettingsScreen({required this.initial, super.key});

  final ReceiptIntakeDisplayPreferences initial;

  @override
  State<ReceiptIntakeSettingsScreen> createState() =>
      _ReceiptIntakeSettingsScreenState();
}

class _ReceiptIntakeSettingsScreenState
    extends State<ReceiptIntakeSettingsScreen> {
  late var _showReviewChecklist = widget.initial.showReviewChecklist;
  late var _showEvidenceReminders = widget.initial.showEvidenceReminders;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Receipt intake settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Show review checklist'),
          subtitle: const Text(
            'Explains the required human review before anything is saved.',
          ),
          value: _showReviewChecklist,
          onChanged: (value) => setState(() => _showReviewChecklist = value),
        ),
        SwitchListTile(
          title: const Text('Show evidence reminders'),
          subtitle: const Text(
            'Reminds the user about photo order and retained originals.',
          ),
          value: _showEvidenceReminders,
          onChanged: (value) => setState(() => _showEvidenceReminders = value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('save-receipt-intake-settings-button'),
          onPressed: () => Navigator.pop(
            context,
            ReceiptIntakeDisplayPreferences(
              showReviewChecklist: _showReviewChecklist,
              showEvidenceReminders: _showEvidenceReminders,
            ),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save receipt display settings'),
        ),
      ],
    ),
  );
}
