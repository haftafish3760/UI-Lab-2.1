import 'package:flutter/material.dart';
import '../../data/work/job_schedule_availability.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/work_schedule_openings.dart';
import 'work_models.dart';

class JobOpeningPicker extends StatefulWidget {
  const JobOpeningPicker({
    required this.job,
    this.work,
    this.jobs = const [],
    required this.initialDay,
    super.key,
  });
  final WorkRecord job;
  final WorkPersistenceSession? work;

  /// Isolated preview/test input; saved Work always supplies [work].
  final List<WorkRecord> jobs;
  final DateTime initialDay;
  @override
  State<JobOpeningPicker> createState() => _JobOpeningPickerState();
}

class _JobOpeningPickerState extends State<JobOpeningPicker> {
  late DateTimeRange _dates = DateTimeRange(
    start: DateUtils.dateOnly(widget.initialDay),
    end: DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day + 6,
    ),
  );
  TimeOfDay _from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _until = const TimeOfDay(hour: 17, minute: 0);
  List<JobScheduleOpening>? _openings;
  String? _error;
  bool _searching = false;

  Future<void> _hours(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _from : _until,
    );
    if (!mounted || value == null) return;
    setState(() {
      if (start) {
        _from = value;
      } else {
        _until = value;
      }
      _openings = null;
    });
  }

  Future<void> _find() async {
    final start = widget.job.scheduledStart;
    final end = widget.job.scheduledEnd;
    if (start == null || end == null || !end.isAfter(start)) {
      setState(
        () => _error = 'Set the job duration before finding an opening.',
      );
      return;
    }
    if (_until.hour * 60 + _until.minute <= _from.hour * 60 + _from.minute) {
      setState(() => _error = 'Search end time must be after the start time.');
      return;
    }
    try {
      final windows = <JobScheduleWindow>[];
      for (
        var day = _dates.start;
        !day.isAfter(_dates.end);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final from = DateTime(
          day.year,
          day.month,
          day.day,
          _from.hour,
          _from.minute,
        );
        final until = DateTime(
          day.year,
          day.month,
          day.day,
          _until.hour,
          _until.minute,
        );
        // Skip civil times that do not exist on a daylight-saving transition.
        if (from.hour != _from.hour ||
            from.minute != _from.minute ||
            until.hour != _until.hour ||
            until.minute != _until.minute) {
          continue;
        }
        windows.add(JobScheduleWindow(from, until));
      }
      setState(() => _searching = true);
      final found = widget.work == null
          ? JobScheduleAvailability(widget.jobs).firstOpenings(
              windows: windows,
              duration: end.difference(start),
              employeeIds: widget.job.assignedEmployeeIds.toSet(),
              vehicle: widget.job.vehicle,
              excludingJobId: widget.job.id,
              bufferMinutes: widget.job.scheduleBufferMinutes,
              notBefore: DateTime.now(),
            )
          : await widget.work!.findJobOpenings(
              job: widget.job,
              windows: windows,
              notBefore: DateTime.now(),
            );
      if (!mounted) return;
      setState(() {
        _error = null;
        _openings = found;
        _searching = false;
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _openings = null;
        _error = error.message.toString();
        _searching = false;
      });
    } on ArgumentError {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _openings = null;
        _error = 'Assign an employee or vehicle before checking openings.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return AlertDialog(
      title: const Text('Find an opening'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose dates and hours. Results check all locally saved company bookings for the assigned employees and vehicle, including jobs outside your list. Review travel and working hours before saving.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final dates = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: _dates,
                  );
                  if (mounted && dates != null) {
                    setState(() {
                      _dates = dates;
                      _openings = null;
                    });
                  }
                },
                child: Text(
                  '${locale.formatShortDate(_dates.start)} – ${locale.formatShortDate(_dates.end)}',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _hours(true),
                    child: Text('From ${_from.format(context)}'),
                  ),
                  OutlinedButton(
                    onPressed: () => _hours(false),
                    child: Text('Until ${_until.format(context)}'),
                  ),
                ],
              ),
              FilledButton(
                onPressed: _searching ? null : _find,
                child: Text(
                  _searching ? 'Checking bookings…' : 'Find openings',
                ),
              ),
              if (_error != null) Text(_error!),
              if (_openings?.isEmpty ?? false)
                const Text(
                  'No opening fits this job in these hours. Try different dates or hours.',
                ),
              for (final slot in _openings ?? <JobScheduleOpening>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(locale.formatFullDate(slot.start)),
                  subtitle: Text(
                    '${TimeOfDay.fromDateTime(slot.start).format(context)} – ${TimeOfDay.fromDateTime(slot.end).format(context)}',
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.pop(context, slot.start),
                    child: const Text('Use time'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
