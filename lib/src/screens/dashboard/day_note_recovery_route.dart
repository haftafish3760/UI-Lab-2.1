import 'package:flutter/material.dart';
import '../../data/day_notes/day_note_draft_workflow.dart';
import '../../data/day_notes/day_note_persistence_session.dart';
import 'day_note_editor_dialog.dart';

/// Opens retained note input independently of the originating calendar layout.
Future<void> openDayNoteRecovery(
  BuildContext context,
  DayNoteDraftController workflow, {
  required DayNotePersistenceSession session,
  required String employeeLabel,
}) async {
  try {
    if (!context.mounted) return;
    final input = workflow.input;
    final date = DateTime.parse(input.date);
    session.validateDayNoteHandoff(
      workflow,
      date: date,
      employeeId: input.employeeId,
    );
    await showDialog<void>(
      context: context,
      builder: (_) => DayNoteEditorDialog(
        session: session,
        date: date,
        employeeId: input.employeeId,
        employeeLabel: employeeLabel,
        recoveredWorkflow: workflow,
      ),
    );
  } finally {
    await workflow.session.close();
  }
}
