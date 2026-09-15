import '../../data/work/work_persistence_session.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_recovery_catalog.dart';
import '../../data/work/work_primary_draft_recovery.dart';
import '../../layout/app_layout_engine.dart';
import '../../theme/app_semantic_colors.dart';

import 'estimate_editor_screen.dart';
import 'estimate_models.dart';
import 'invoice_editor_screen.dart';
import 'job_workspace_screen.dart';
import 'work_models.dart';

import 'work_primary_recovery_routes.dart';
import 'work_saved_document_route.dart';

class WorkDraftsScreen extends StatefulWidget {
  const WorkDraftsScreen({this.kind, super.key});
  final WorkRecordKind? kind;
  @override
  State<WorkDraftsScreen> createState() => _WorkDraftsScreenState();
}

class _WorkDraftsScreenState extends State<WorkDraftsScreen> {
  WorkPrimaryDraftRecovery? _recovery;
  List<DraftRecoveryEntry> _input = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final work = PrototypeOperationsScope.of(context).workSession;
    if (_recovery == null && work != null) {
      _recovery = WorkPrimaryDraftRecovery(work);
      _reload();
    } else if (work == null) {
      _loading = false;
    }
  }

  Future<void> _reload() async {
    try {
      final input = await _recovery?.list() ?? <DraftRecoveryEntry>[];
      if (mounted) {
        setState(() {
          _input = input
              .where(
                (e) =>
                    widget.kind == null ||
                    e.domain == 'work/${widget.kind!.name}-editor',
              )
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Drafts could not be loaded. Please retry.';
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'That action could not be completed. Your saved work has been kept.',
        );
      }
    } finally {
      if (mounted) {
        await _reload();
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirmDelete(String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete draft?'),
          content: Text('Delete “$name”? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep draft'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete draft'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _openRecord(WorkRecord record) async {
    final store = PrototypeOperationsScope.of(context);
    final saved = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => switch (record.kind) {
          WorkRecordKind.estimate => EstimateEditorScreen(
            initialDay: record.createdOn ?? DateTime.now(),
            initialRecord: record,
          ),
          WorkRecordKind.invoice => InvoiceEditorScreen(
            initialRecord: record,
            initialDay: record.createdOn ?? DateTime.now(),
          ),
          WorkRecordKind.job => JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: store.updateWorkRecord,
          ),
        },
      ),
    );
    if (saved != null && mounted) {
      await openSavedWorkDocument(context, saved);
    }
  }

  Future<void> _deleteInput(DraftRecoveryEntry entry) async {
    final work = PrototypeOperationsScope.of(context).workSession;
    final parent = work?.records
        .where((r) => r.id == entry.preview.recordId)
        .firstOrNull;
    if (parent != null && !work!.canDeleteDraft(parent)) {
      throw StateError('This saved document cannot be deleted as a draft.');
    }
    if (!await _confirmDelete(entry.preview.title) || !mounted) return;
    // Keep the recoverable input if deleting its saved draft fails.
    if (parent != null && !await work!.deleteDraft(parent)) {
      throw StateError('The saved draft was not deleted.');
    }
    await _recovery!.discard(entry);
  }

  @override
  Widget build(BuildContext context) {
    final work = PrototypeOperationsScope.of(context).workSession;
    final records =
        (work?.records ?? <WorkRecord>[])
            .where((r) => widget.kind == null || r.kind == widget.kind)
            .where((r) => !_input.any((e) => e.preview.recordId == r.id))
            .where(
              (r) => r.kind == WorkRecordKind.estimate
                  ? r.resolvedEstimateStage == EstimateStage.draft
                  : r.status == WorkRecordStatus.draft,
            )
            .toList()
          ..sort(
            (a, b) => (b.createdOn ?? DateTime(1970)).compareTo(
              a.createdOn ?? DateTime(1970),
            ),
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Drafts')),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: AppLayoutEngine.pageInsetsFor(
            constraints.maxWidth,
          ).copyWith(top: 12, bottom: 24),
          children: [
            Text(
              'Continue your saved work',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Choose a draft to continue editing. Returning to Work never opens a draft automatically.',
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (_error != null)
              TextButton(onPressed: _reload, child: const Text('Retry')),
            if (!_loading && records.isEmpty && _input.isEmpty)
              const Text('No drafts yet. Start a new document from Add Work.'),
            for (final record in records) ...[
              ListTile(
                tileColor: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.draftSurface,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  record.title.isEmpty
                      ? 'Untitled ${record.kind.name}'
                      : record.title,
                ),
                subtitle: Text(
                  '${record.client} · ${record.number}\nLast edited: ${_dateLabel(record.estimateDates?.lastEditedOn ?? record.createdOn)}',
                ),
                onTap: _busy ? null : () => _run(() => _openRecord(record)),
                trailing: work!.canDeleteDraft(record)
                    ? IconButton(
                        tooltip: 'Delete draft',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                if (await _confirmDelete(record.title) &&
                                    mounted &&
                                    !await work.deleteDraft(record)) {
                                  throw StateError('Draft deletion failed.');
                                }
                              }),
                      )
                    : null,
              ),
              const Divider(height: 1),
            ],
            for (final entry in _input)
              ListTile(
                tileColor: Theme.of(
                  context,
                ).extension<AppSemanticColors>()!.draftSurface,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.preview.title),
                subtitle: Text(
                  '${entry.workflowLabel}\nLast edited: ${_dateLabel(entry.updatedAt)}',
                ),
                onTap:
                    _busy ||
                        entry.preview.availability !=
                            DraftRecoveryAvailability.recoverable
                    ? null
                    : () => _run(() async {
                        final resumed = await _recovery!.resume(entry);
                        if (context.mounted) {
                          await openPrimaryWorkRecovery(context, resumed);
                        } else {
                          await switch (resumed) {
                            ResumedEstimateDraft(:final controller) =>
                              controller.session.close(),
                            ResumedInvoiceDraft(:final controller) =>
                              controller.session.close(),
                            ResumedJobDraft(:final controller) =>
                              controller.session.close(),
                          };
                        }
                      }),
                trailing: IconButton(
                  tooltip: 'Delete draft',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy
                      ? null
                      : () => _run(() => _deleteInput(entry)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime? value) => value == null
      ? 'Not recorded'
      : '${MaterialLocalizations.of(context).formatMediumDate(value.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(value.toLocal()))}';
}
