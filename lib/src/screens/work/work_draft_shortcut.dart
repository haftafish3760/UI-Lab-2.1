import 'dart:async';
import '../../../l10n/app_localizations_extension.dart';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_recovery_catalog.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/work_primary_draft_recovery.dart';
import 'work_drafts_screen.dart';
import 'work_models.dart';
import 'estimate_models.dart';

/// Opens a document's drafts only when saved or recoverable input exists.
class WorkDraftShortcut extends StatefulWidget {
  const WorkDraftShortcut({
    required this.kind,
    required this.buttonKey,
    this.textButtonLabel,
    super.key,
  });

  final WorkRecordKind kind;
  final Key buttonKey;

  /// Optional compact text action; other workspaces keep their existing button.
  final String? textButtonLabel;

  @override
  State<WorkDraftShortcut> createState() => _WorkDraftShortcutState();
}

class _WorkDraftShortcutState extends State<WorkDraftShortcut> {
  WorkPersistenceSession? _session;
  List<DraftRecoveryEntry> _unfinishedInput = const [];
  bool _loadFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = PrototypeOperationsScope.of(context).workSession;
    if (!identical(_session, session)) {
      _session = session;
      _unfinishedInput = const [];
      _loadFailed = false;
      if (session != null) unawaited(_reload(session));
    }
  }

  Future<void> _reload(WorkPersistenceSession session) async {
    try {
      final entries = await WorkPrimaryDraftRecovery(session).list();
      if (!mounted || !identical(_session, session)) return;
      setState(() {
        _unfinishedInput = entries
            .where((entry) => entry.domain == 'work/${widget.kind.name}-editor')
            .toList();
        _loadFailed = false;
      });
    } on Object {
      if (mounted && identical(_session, session)) {
        setState(() => _loadFailed = true);
      }
    }
  }

  bool _hasSavedDraft(PrototypeOperationsStore store) => store.workRecords.any(
    (record) =>
        record.kind == widget.kind &&
        (_session?.permissions.canEdit(record) ?? true) &&
        (record.kind == WorkRecordKind.estimate
            ? record.resolvedEstimateStage == EstimateStage.draft
            : record.status == WorkRecordStatus.draft),
  );

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    if (!_hasSavedDraft(store) && _unfinishedInput.isEmpty && !_loadFailed) {
      return const SizedBox.shrink();
    }
    final label = switch (widget.kind) {
      WorkRecordKind.estimate => 'Estimate drafts',
      WorkRecordKind.quote => 'Quote drafts',
      WorkRecordKind.invoice => context.l10n.workInvoiceDrafts,
      WorkRecordKind.job => 'Job drafts',
    };
    Future<void> openDrafts() async {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => WorkDraftsScreen(kind: widget.kind)),
      );
      if (mounted && _session != null) await _reload(_session!);
    }

    if (widget.textButtonLabel case final compactLabel?) {
      return TextButton(
        key: widget.buttonKey,
        onPressed: openDrafts,
        child: Text(compactLabel),
      );
    }
    return FilledButton.icon(
      key: widget.buttonKey,
      onPressed: openDrafts,
      icon: const Icon(Icons.edit_note_outlined),
      label: Text(label),
    );
  }
}
