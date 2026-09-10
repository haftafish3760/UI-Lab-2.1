import 'package:flutter/widgets.dart';
import '../../screens/dashboard/dashboard_models.dart';
import 'day_note_persistence_session.dart';
import 'stored_day_note.dart';

DashboardDayData withDayNoteProjections({
  required DashboardDayData data,
  required DayNotePersistenceSession session,
  required DateTime day,
  String? employeeId,
}) {
  final date =
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  final notes =
      session.records
          .where(
            (note) =>
                note.date == date &&
                (employeeId == null || note.employeeId == employeeId),
          )
          .toList()
        ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
  return DashboardDayData(
    plan: data.plan,
    entries: [
      ...data.entries.where(
        (entry) =>
            !(entry.kind == DayEntryKind.note && entry.sourceRecordId != null),
      ),
      for (final note in notes) projectDayNote(note),
    ],
  );
}

String _timeLabel(int minutes) {
  final hour = minutes ~/ 60;
  return '${hour % 12 == 0 ? 12 : hour % 12}:${(minutes % 60).toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
}

DayEntry projectDayNote(StoredDayNote note) => DayEntry(
  id: 'day-note-${note.id}',
  sourceRecordId: note.id,
  time: _timeLabel(note.timeMinutes),
  title: note.text,
  detail: 'Manually added record',
  kind: DayEntryKind.note,
  submittedBy:
      demoEmployees
          .where((employee) => employee.id == note.employeeId)
          .firstOrNull
          ?.name ??
      note.employeeId,
  color: const Color(0xFF65727A),
);
