import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/reusable_job.dart';
import '../../data/work/reusable_job_library.dart';
import '../../data/work/work_items_draft_input.dart';
import '../../data/work/work_record_detail_codec.dart';
import '../../data/work/work_service_price.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'work_items_editor.dart';
import 'work_models.dart';
import 'work_detail_header.dart';

class ReusableJobEditor extends StatefulWidget {
  const ReusableJobEditor({
    required this.library,
    this.initial,
    this.seed,
    this.recoveryDraftId,
    super.key,
  });
  final ReusableJobLibrary library;
  final SavedReusableJob? initial;
  final ReusableJob? seed;
  final String? recoveryDraftId;
  @override
  State<ReusableJobEditor> createState() => _ReusableJobEditorState();
}

class _ReusableJobEditorState extends State<ReusableJobEditor>
    with DraftNavigationGuard {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  DraftAutosaveSession? _draft;
  StreamSubscription<DraftSaveState>? _subscription;
  late String _id, _owner;
  int _revision = 0;
  WorkPricingModel _pricing = WorkPricingModel.flatRate;
  List<WorkLineItem> _items = [];
  WorkItemsDraftInput? _pendingItems;
  bool _ready = false, _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  bool get confirmDraftExit => _ready && _draft!.input.isNotEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final initial = widget.initial?.job ?? widget.seed;
      _id = initial?.id ?? newLocalRecordIdentity('reusable-job');
      _owner =
          initial?.ownerId ?? widget.library.work.permissions.actorEmployeeId;
      _revision = widget.initial?.revision ?? 0;
      _title.text = initial?.title ?? '';
      _description.text = initial?.description ?? '';
      _pricing = initial?.pricing ?? WorkPricingModel.flatRate;
      _items = [...?initial?.items];
      final draft = await widget.library.openInput(
        draftId:
            widget.recoveryDraftId ??
            (widget.initial == null
                ? null
                : 'edit-${widget.library.work.permissions.actorEmployeeId}-$_id'),
      );
      _draft = draft;
      if (!mounted) {
        await draft.close();
        return;
      }
      if (draft.input.isNotEmpty) {
        final input = draft.input;
        if (widget.initial != null && input['id'] != widget.initial!.job.id) {
          throw StateError(
            'This unfinished work belongs to a different reusable job.',
          );
        }
        _id = input['id'] as String;
        _owner = input['ownerId'] as String;
        _revision = input['baseRevision'] as int;
        _title.text = input['title'] as String;
        _description.text = input['description'] as String;
        _price.text = input['price'] as String;
        _pricing = WorkPricingModel.values.byName(input['pricing'] as String);
        _items = (input['items'] as List)
            .map((i) => decodeWorkLineItem(Map<String, Object?>.from(i as Map)))
            .toList();
        if (input['itemEditor'] != null) {
          _pendingItems = WorkItemsDraftInput.fromPayload(
            Map<String, Object?>.from(input['itemEditor'] as Map),
          );
        }
      } else if (_items.isNotEmpty && canUseWorkServicePrice(_id, _items)) {
        _price.text = _items.single.customerPrice.toStringAsFixed(2);
        _items = [];
      }
      for (final controller in [_title, _description, _price]) {
        controller.addListener(_capture);
      }
      _subscription = draft.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Reusable job input could not be opened. Saved information has been kept.',
        );
      }
    }
  }

  void _capture() {
    if (!_ready || _saving) return;
    _draft!.replaceInput({
      'id': _id,
      'ownerId': _owner,
      'baseRevision': _revision,
      'title': _title.text,
      'description': _description.text,
      'price': _price.text,
      'pricing': _pricing.name,
      'items': _items.map(encodeWorkLineItem).toList(),
      'itemEditor': _pendingItems?.toPayload(),
    });
  }

  Future<void> _editItems() async {
    var starting = _items;
    if (_price.text.trim().isNotEmpty) {
      try {
        starting = workServicePricedItems(
          recordId: _id,
          title: _title.text,
          description: _description.text,
          priceText: _price.text,
          items: _items,
        );
      } on FormatException catch (e) {
        setState(() => _error = e.message);
        return;
      }
    }
    final result = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: starting,
          pricing: _pricing,
          workspaceLabel: 'Reusable job items',
          draftSession: _draft,
          recoveryInput: _pendingItems,
          allowExpenseEvidence: false,
          allowMaterialCostHistory: false,
          allowTruckStock: false,
          canViewInternalCost: false,
          onDraftChanged: (input) {
            _pendingItems = input;
            _capture();
          },
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _items = result;
        _price.clear();
        _pendingItems = null;
      });
      _capture();
    }
  }

  Future<void> _save() async {
    _capture();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await _draft!.confirm((checkpoint) async {
        final input = _draft!.input;
        if (input['itemEditor'] != null) {
          throw const FormatException(
            'Finish the unfinished items before saving this reusable job.',
          );
        }
        final items = (input['items'] as List)
            .map((i) => decodeWorkLineItem(Map<String, Object?>.from(i as Map)))
            .toList();
        final price = input['price'] as String;
        final job = ReusableJob(
          id: input['id'] as String,
          ownerId: input['ownerId'] as String,
          title: (input['title'] as String).trim(),
          description: (input['description'] as String).trim(),
          pricing: WorkPricingModel.values.byName(input['pricing'] as String),
          items: price.trim().isEmpty
              ? items
              : workServicePricedItems(
                  recordId: _id,
                  title: _title.text,
                  description: _description.text,
                  priceText: price,
                  items: items,
                ),
        );
        await widget.library.save(
          job,
          expectedRevision: input['baseRevision'] as int,
          checkpoint: checkpoint,
        );
        return true;
      });
      if (mounted && saved) {
        await finishDraftRoute(true);
      } else if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Not saved. Keep this input and try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is FormatException
              ? error.message
              : 'Not saved. The reusable job may have changed. Your input has been kept.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: AppLayoutEngine.formWorkspaceWidthFor(
                constraints.maxWidth,
              ),
              child: ListView(
                padding: AppLayoutEngine.pageInsetsFor(constraints.maxWidth),
                children: [
                  WorkDetailHeader(
                    label: 'Reusable job',
                    selectedDay: DateTime.now(),
                    onBack: leaveDraftRoute,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) Text(_error!),
                  if (!_ready && _error == null)
                    const LinearProgressIndicator(),
                  if (_ready) ...[
                    EditorDraftStatus(
                      state: _draft!.state,
                      onRetry: _draft!.retry,
                    ),
                    const Text(
                      'Save work you do often. Choose the client and schedule when you use it.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('reusable-job-title'),
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Job name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('reusable-job-description'),
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Work description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_items.isEmpty)
                      TextField(
                        key: const ValueKey('reusable-job-price'),
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Usual price (optional)',
                        ),
                      ),
                    TextButton.icon(
                      key: const ValueKey('reusable-job-items'),
                      onPressed: _editItems,
                      icon: const Icon(Icons.format_list_bulleted),
                      label: Text(
                        _items.isEmpty
                            ? 'Add items (optional)'
                            : 'Edit items (${_items.length})',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('save-reusable-job'),
                      onPressed: _saving ? null : _save,
                      child: const Text('Save reusable job'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
