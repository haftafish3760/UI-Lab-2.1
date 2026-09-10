import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/work/job_schedule_draft_workflow.dart';
import '../../data/work/work_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'work_models.dart';
import '../../shared/module_month_calendar.dart';

class JobScheduleEditorSheet extends StatefulWidget {
  const JobScheduleEditorSheet({
    required this.record,
    this.work,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final WorkPersistenceSession? work;
  final JobScheduleDraftController? recoveredWorkflow;
  @override
  State<JobScheduleEditorSheet> createState() => _JobScheduleEditorSheetState();
}

class _JobScheduleEditorSheetState extends State<JobScheduleEditorSheet>
    with DraftNavigationGuard {
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  late DateTime _day;
  String _period = 'AM';
  late WorkRecord _base;
  late JobScheduleDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  void initState() {
    super.initState();
    _base = widget.record;
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final work = widget.work;
      if (work == null && widget.recoveredWorkflow != null) {
        throw StateError('Recovered input requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openJobScheduleDraft(widget.record.id);
        if (widget.recoveredWorkflow != null) {
          work.validateJobScheduleHandoff(workflow, widget.record.id);
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        final input = workflow.input;
        _day = input.day;
        _hour.text = input.hour;
        _minute.text = input.minute;
        _period = input.period;
        final draft = workflow.session;
        _subscription = draft.changes.listen((_) {
          if (mounted) setState(() {});
        });
      } else {
        _prefill();
      }
      if (!mounted) return;
      _hour.addListener(_capture);
      _minute.addListener(_capture);
      setState(() => _ready = true);
      _capture();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved schedule could not be opened. Leave and retry; saved input has been preserved.',
        );
      }
    }
  }

  void _capture() {
    if (!_ready || _saving) return;
    _workflow?.update(
      day: _day,
      hour: _hour.text,
      minute: _minute.text,
      period: _period,
    );
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    _capture();
    setState(() => _saving = true);
    try {
      final record = _workflow != null
          ? await _workflow!.confirm()
          : JobScheduleInput(
              base: _base,
              baseRevision: 0,
              day: _day,
              hour: _hour.text,
              minute: _minute.text,
              period: _period,
            ).confirmedRecord();
      if (record == null) {
        throw StateError(
          widget.work?.failureMessage ?? 'The schedule was not saved.',
        );
      }
      if (mounted) await finishDraftRoute(record);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              (error is StateError
                  ? error.message.toString()
                  : widget.work?.failureMessage) ??
              'The schedule was not saved. Your unfinished input has been kept. Retry saving.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished schedule?'),
        content: const Text('Previously saved job schedule stay unchanged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    setState(() => _saving = true);
    try {
      await _draft?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Unfinished schedule could not be discarded. They have been preserved.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _prefill() {
    final input = JobScheduleInput.initial(_base, baseRevision: 0);
    _day = input.day;
    _hour.text = input.hour;
    _minute.text = input.minute;
    _period = input.period;
  }

  void _change(VoidCallback change) {
    setState(change);
    _capture();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reschedule job',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_draft != null)
                EditorDraftStatus(
                  state: _draft!.state,
                  onRetry: _draft!.retry,
                  onDiscard: _discard,
                ),
              if (_error != null) Text(_error!),
              if (!_ready && _error == null) const Text('Opening saved input…'),
              if (_ready) ...[
                const SizedBox(height: 12),
                const Text(
                  'Choose the new arrival date and time. The recorded job duration stays the same.',
                ),
                ExpansionTile(
                  title: Text(
                    MaterialLocalizations.of(context).formatFullDate(_day),
                  ),
                  subtitle: const Text('Choose arrival date'),
                  children: [
                    WorkMonthCalendar(
                      selectedDay: _day,
                      onDaySelected: (day) => _change(() => _day = day),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hour,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hour',
                          hintText: '1–12',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minute,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          hintText: '00–59',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'AM', label: Text('AM')),
                    ButtonSegment(value: 'PM', label: Text('PM')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (value) =>
                      _change(() => _period = value.single),
                ),
              ],
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => leaveDraftRoute(),
                child: const Text('Keep unfinished schedule'),
              ),
              FilledButton(
                onPressed: _ready && !_saving ? _save : null,
                child: const Text('Save schedule'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
