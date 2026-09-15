import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../data/work/work_activity_reader.dart';
import '../../data/work/work_export_audit.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/recorded_entries_section.dart';
import 'work_models.dart';

class WorkActivityButton extends StatelessWidget {
  const WorkActivityButton({required this.record, super.key});
  final WorkRecord record;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: ValueKey('work-activity-${record.id}'),
    icon: const Icon(Icons.history),
    label: const Text('People and activity'),
    onPressed: () => Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => WorkActivityScreen(record: record)),
    ),
  );
}

class WorkActivityScreen extends StatefulWidget {
  const WorkActivityScreen({required this.record, super.key});
  final WorkRecord record;
  @override
  State<WorkActivityScreen> createState() => _WorkActivityScreenState();
}

class _WorkActivityScreenState extends State<WorkActivityScreen> {
  WorkActivityReader? _reader;
  final _entries = <WorkActivityEntry>[];
  List<WorkActivityEntry> _exports = [];
  int _exportLimit = 100;
  int? _next;
  bool _initialized = false, _loading = false;
  String? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work != null) {
      _reader = WorkActivityReader(work);
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || _reader == null) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _reader!.read(
        widget.record.id,
        beforeRevision: reset ? null : _next,
      );
      final exports = await WorkExportAudit(
        _reader!.work,
      ).read(widget.record.id, limit: _exportLimit);
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _entries.clear();
        }
        _entries.addAll(page.entries);
        _exports = exports;
        _next = page.nextBeforeRevision;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Activity could not be loaded or verified. Retry to read the saved history.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _employee(String id) {
    final names = PrototypeOperationsScope.of(
      context,
    ).directorySession?.employees;
    final name = names?.where((e) => e.id == id).firstOrNull?.name;
    return name == null ? 'Employee ID: $id' : '$name · ID: $id';
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final record = store.workRecords
        .where((r) => r.id == widget.record.id)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('People and activity')),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: AppLayoutEngine.pageInsetsFor(
            constraints.maxWidth,
          ).copyWith(top: 12, bottom: 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayoutEngine.singleMaximum,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (record == null)
                      const Text('This record is no longer available.')
                    else ...[
                      Text(
                        '${record.number} · ${record.client}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Created by\n${_employee(record.createdByEmployeeId)}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        record.assignedEmployeeIds.isEmpty
                            ? 'Assigned employees\nNo employees assigned to this record.'
                            : 'Assigned employees\n${record.assignedEmployeeIds.map(_employee).join('\n')}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Assignment identifies responsibility. The saved activity below identifies who actually made each change. Employee names reflect the current directory; IDs remain unchanged.',
                      ),
                      const SizedBox(height: 16),
                      if (_exports.isNotEmpty) ...[
                        Text(
                          'PDF sharing, saving and printing',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'A sharing app response is not proof that the customer received or read the document.',
                        ),
                        for (final entry in _exports)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '${entry.changes.single}\n${_employee(entry.actorId)}\n${MaterialLocalizations.of(context).formatFullDate(entry.at.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(entry.at.toLocal()))} · Saved version ${entry.revision}',
                            ),
                          ),
                        if (_exports.length == _exportLimit)
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    _exportLimit += 100;
                                    _load(reset: true);
                                  },
                            child: const Text('Show earlier sharing activity'),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (_reader == null)
                        const Text(
                          'Saved activity is unavailable in this preview. No activity has been invented.',
                        ),
                      if (_loading) const LinearProgressIndicator(),
                      if (_error != null) ...[
                        Text(_error!),
                        TextButton(
                          onPressed: _loading ? null : () => _load(reset: true),
                          child: const Text('Retry'),
                        ),
                      ],
                      if (_entries.isNotEmpty)
                        RecordedEntriesSection(
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Saved activity',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                for (final entry in _entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          entry.changes.join(' · '),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(_employee(entry.actorId)),
                                        Text(
                                          '${MaterialLocalizations.of(context).formatFullDate(entry.at.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(entry.at.toLocal()))} · Saved version ${entry.revision}',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (_next != null)
                        TextButton(
                          onPressed: _loading ? null : () => _load(),
                          child: const Text('Show earlier activity'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
