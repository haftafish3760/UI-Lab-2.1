import 'package:flutter/material.dart';
import '../../data/day_notes/day_note_persistence_session.dart';
import '../../data/day_notes/day_note_dashboard_projection.dart';
import 'stored_day_entry_details_screen.dart';

/// Resolve the owning record under scoped read authority, never caller text.
class SavedDayNoteDetailsScreen extends StatelessWidget {
  const SavedDayNoteDetailsScreen({
    required this.noteId,
    required this.session,
    super.key,
  });
  final String noteId;
  final DayNotePersistenceSession session;
  @override
  Widget build(BuildContext context) => StoredDayEntryDetailsScreen(
    key: ValueKey((session, noteId)),
    title: 'Work note details',
    unavailableMessage: 'This day record is unavailable.',
    showOdometer: false,
    load: () async {
      final note = (await session.repository.read(
        session.access,
      )).where((note) => note.id == noteId).firstOrNull;
      return note == null
          ? null
          : StoredDayEntryDetails(
              entry: projectDayNote(note),
              date: DateTime.parse(note.date),
            );
    },
  );
}
