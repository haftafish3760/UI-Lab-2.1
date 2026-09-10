import 'package:flutter/material.dart';
import '../../data/workday/workday_persistence_session.dart';
import '../../data/workday/workday_dashboard_projection.dart';
import 'stored_day_entry_details_screen.dart';

class SavedWorkdayEventDetailsScreen extends StatelessWidget {
  const SavedWorkdayEventDetailsScreen({
    required this.workdayId,
    required this.eventId,
    required this.session,
    required this.showOdometer,
    super.key,
  });
  final String workdayId;
  final String eventId;
  final WorkdayPersistenceSession session;
  final bool showOdometer;
  @override
  Widget build(BuildContext context) => StoredDayEntryDetailsScreen(
    key: ValueKey((session, workdayId, eventId)),
    title: 'Workday details',
    unavailableMessage: 'This workday event is unavailable.',
    showOdometer: showOdometer,
    load: () async {
      if (eventId != 'workday-$workdayId-started' &&
          eventId != 'workday-$workdayId-ended') {
        return null;
      }
      final snapshot = (await session.repository.read(
        session.access,
      )).where((item) => item.record.id == workdayId).firstOrNull;
      if (snapshot == null) return null;
      final event = projectWorkdayEvent(
        snapshot.record,
        ended: eventId == 'workday-$workdayId-ended',
      );
      return event == null
          ? null
          : StoredDayEntryDetails(
              entry: event.$2,
              date: DateUtils.dateOnly(event.$1),
            );
    },
  );
}
