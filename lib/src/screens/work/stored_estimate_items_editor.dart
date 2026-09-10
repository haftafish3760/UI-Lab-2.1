import '../../data/work/work_items_draft_input.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/estimate_items_draft_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import 'estimate_items_screen.dart';
import 'work_models.dart';

/// Supplies the existing nested item editor with its own estimate-owned draft
/// when opened outside the full estimate editor.
class StoredEstimateItemsEditor extends StatefulWidget {
  const StoredEstimateItemsEditor({
    required this.record,
    required this.work,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final WorkPersistenceSession work;
  final EstimateItemsDraftController? recoveredWorkflow;
  @override
  State<StoredEstimateItemsEditor> createState() =>
      _StoredEstimateItemsEditorState();
}

class _StoredEstimateItemsEditorState extends State<StoredEstimateItemsEditor> {
  late WorkRecord _base = widget.record;
  late EstimateItemsDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  WorkItemsDraftInput? _input;
  bool _ready = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final workflow =
          widget.recoveredWorkflow ??
          await widget.work.openEstimateItemsDraft(widget.record);
      if (widget.recoveredWorkflow != null) {
        widget.work.validateEstimateItemsHandoff(workflow, widget.record.id);
      }
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      _workflow = workflow;
      _base = workflow.input.base;
      _input = workflow.input.workspace;
      setState(() => _ready = true);
    } on Object catch (error) {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Saved estimate items could not be opened. Input has been preserved.',
        );
      }
    }
  }

  void _changed(WorkItemsDraftInput input) {
    _workflow!.updateWorkspace(input);
    _input = input;
  }

  Future<bool> _save(List<WorkLineItem> items) async {
    try {
      final record = await _workflow!.confirm();
      if (record == null) {
        throw StateError(widget.work.failureMessage ?? 'Items were not saved.');
      }
      return true;
    } on Object catch (error) {
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Items were not saved. Your input is retained.',
      );
      return false;
    }
  }

  Future<bool> _discard() async {
    try {
      await _draft!.discard();
      return true;
    } on Object {
      _showError(
        'Item changes could not be discarded. They have been preserved.',
      );
      return false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    unawaited(_draft?.close().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ready
      ? EstimateItemsScreen(
          initialItems: _base.items,
          pricing: _base.pricing,
          selectedDay: _base.estimateDates?.createdOn ?? _base.createdOn,
          draftSession: _draft,
          recoveryInput: _input,
          onDraftChanged: _changed,
          onSave: _save,
          onDiscard: _discard,
        )
      : Scaffold(
          appBar: AppBar(title: const Text('Estimate items')),
          body: Center(child: Text(_error ?? 'Opening saved items…')),
        );
}
