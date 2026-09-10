import 'package:flutter/material.dart';
import 'dashboard_models.dart';
import 'day_entry_details_screen.dart';

class StoredDayEntryDetails {
  const StoredDayEntryDetails({required this.entry, required this.date});
  final DayEntry entry;
  final DateTime date;
}

/// Shared loading/retry presentation. Owning adapters provide scoped SQLite
/// reads; a new resource must use a different widget key to discard old data.
class StoredDayEntryDetailsScreen extends StatefulWidget {
  const StoredDayEntryDetailsScreen({
    required this.load,
    required this.title,
    required this.unavailableMessage,
    required this.showOdometer,
    super.key,
  });
  final Future<StoredDayEntryDetails?> Function() load;
  final String title;
  final String unavailableMessage;
  final bool showOdometer;
  @override
  State<StoredDayEntryDetailsScreen> createState() =>
      _StoredDayEntryDetailsScreenState();
}

class _StoredDayEntryDetailsScreenState
    extends State<StoredDayEntryDetailsScreen> {
  late Future<StoredDayEntryDetails?> _entry;
  @override
  void initState() {
    super.initState();
    _entry = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StoredDayEntryDetails?>(
    future: _entry,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return DayEntryDetailsScreen(
          entry: snapshot.data!.entry,
          date: snapshot.data!.date,
          showOdometer: widget.showOdometer,
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: snapshot.connectionState != ConnectionState.done
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.unavailableMessage),
                    if (snapshot.hasError)
                      TextButton(
                        onPressed: () => setState(() => _entry = widget.load()),
                        child: const Text('Retry loading'),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
