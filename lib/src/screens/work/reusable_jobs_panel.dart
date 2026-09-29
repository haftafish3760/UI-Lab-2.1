import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_repository.dart';
import '../../data/work/reusable_job.dart';
import '../../data/work/reusable_job_library.dart';
import '../../data/work/work_persistence_session.dart';
import 'reusable_job_editor.dart';
import 'work_job_editor.dart';
import 'work_models.dart';
import 'work_saved_document_route.dart';

/// A compact second tab within Add work; no copied customer records or fixtures.
class ReusableWorkTabs extends StatefulWidget {
  const ReusableWorkTabs({
    required this.newWork,
    required this.day,
    this.firstTabLabel = 'New work',
    this.onReusableSelected,
    super.key,
  });
  final Widget newWork;
  final DateTime day;
  final String firstTabLabel;
  final ValueChanged<bool>? onReusableSelected;
  @override
  State<ReusableWorkTabs> createState() => _ReusableWorkTabsState();
}

class _ReusableWorkTabsState extends State<ReusableWorkTabs>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)
    ..addListener(_changed);
  bool _reusableSelected = false;
  void _changed() {
    final selected = _tabs.index == 1;
    if (selected == _reusableSelected) return;
    setState(() => _reusableSelected = selected);
    widget.onReusableSelected?.call(selected);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TabBar(
        controller: _tabs,
        tabs: [
          for (final label in [widget.firstTabLabel, 'Reusable jobs'])
            Tab(
              height: 24 + MediaQuery.textScalerOf(context).scale(32),
              child: Text(label, textAlign: TextAlign.center, softWrap: true),
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (_tabs.index == 0)
        widget.newWork
      else
        ReusableJobsPanel(day: widget.day),
    ],
  );
}

class ReusableJobsPanel extends StatefulWidget {
  const ReusableJobsPanel({required this.day, super.key});
  final DateTime day;
  @override
  State<ReusableJobsPanel> createState() => _ReusableJobsPanelState();
}

class _ReusableJobsPanelState extends State<ReusableJobsPanel> {
  WorkPersistenceSession? _work;
  ReusableJobLibrary? _library;
  Future<(List<SavedReusableJob>, List<SavedDraft>)>? _loaded;
  String _query = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final work = PrototypeOperationsScope.of(context).workSession;
    if (!identical(_work, work)) {
      _work = work;
      _library = work == null ? null : ReusableJobLibrary(work);
      if (_library != null) _reload();
    }
  }

  void _reload() {
    _loaded = _load();
  }

  Future<(List<SavedReusableJob>, List<SavedDraft>)> _load() async =>
      (await _library!.list(), await _library!.unfinished());

  Future<void> _edit({
    SavedReusableJob? initial,
    ReusableJob? seed,
    String? draftId,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReusableJobEditor(
          library: _library!,
          initial: initial,
          seed: seed,
          recoveryDraftId: draftId,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _use(SavedReusableJob saved) async {
    try {
      final current = await _library!.forUse(saved.job.id, saved.revision);
      if (!mounted) return;
      final job = await Navigator.of(context).push<WorkRecord>(
        MaterialPageRoute(
          builder: (_) =>
              WorkJobEditor(initialDay: widget.day, reusableJob: current),
        ),
      );
      if (!mounted || job == null) return;
      final store = PrototypeOperationsScope.of(context);
      final committed =
          store.workSession != null || await store.addWorkRecord(job);
      if (mounted && committed) await openSavedWorkDocument(context, job);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This reusable job is unavailable or changed. Refresh the list and try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fromJob() async {
    final store = PrototypeOperationsScope.of(context);
    final jobs = store.workRecords
        .where(
          (r) => r.kind == WorkRecordKind.job && _work!.permissions.canEdit(r),
        )
        .toList();
    final selected = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Choose a job to reuse')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (jobs.isEmpty)
                const Text('Create a job first, or create a new reusable job.'),
              for (final job in jobs)
                ListTile(
                  title: Text(job.title),
                  subtitle: Text('${job.number} · ${job.client}'),
                  onTap: () => Navigator.pop(context, job),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    final current = _work!.records
        .where((r) => r.id == selected.id && _work!.permissions.canEdit(r))
        .firstOrNull;
    if (current == null) return;
    await _edit(
      seed: ReusableJob.fromWork(
        current,
        ownerId: _work!.permissions.actorEmployeeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_library == null) {
      return const Text(
        'Open your saved company workspace to use reusable jobs.',
      );
    }
    return FutureBuilder<(List<SavedReusableJob>, List<SavedDraft>)>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reusable jobs could not be opened. Check your access and try again.',
              ),
              TextButton(
                onPressed: () => setState(_reload),
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final (saved, drafts) = snapshot.data!;
        final visible = saved.where(
          (entry) => '${entry.job.title} ${entry.job.description}'
              .toLowerCase()
              .contains(_query.toLowerCase().trim()),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  key: const ValueKey('new-reusable-job'),
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('New reusable job'),
                ),
                TextButton(
                  onPressed: _fromJob,
                  child: const Text('Save an existing job'),
                ),
                IconButton(
                  tooltip: 'Refresh reusable jobs',
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Keep common work here, then choose a new client when you use it.',
            ),
            if (drafts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Unfinished reusable jobs',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final draft in drafts)
                ListTile(
                  key: ValueKey('reusable-draft-${draft.draftId}'),
                  title: const Text('Continue saved input'),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatMediumDate(
                      DateTime.fromMicrosecondsSinceEpoch(draft.updatedAtUs),
                    ),
                  ),
                  onTap: () => _edit(draftId: draft.draftId),
                ),
            ],
            if (saved.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('reusable-job-search'),
                decoration: const InputDecoration(
                  labelText: 'Find reusable work',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
            for (final entry in visible) ...[
              const Divider(),
              Text(
                entry.job.title,
                key: ValueKey('reusable-job-${entry.job.id}'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (entry.job.description.isNotEmpty) Text(entry.job.description),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    key: ValueKey('use-reusable-${entry.job.id}'),
                    onPressed: () => _use(entry),
                    child: const Text('Use for a new job'),
                  ),
                  if (entry.job.ownerId == _work!.permissions.actorEmployeeId ||
                      _work!.permissions.canManageOtherCreators)
                    TextButton(
                      key: ValueKey('edit-reusable-${entry.job.id}'),
                      onPressed: () => _edit(initial: entry),
                      child: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
