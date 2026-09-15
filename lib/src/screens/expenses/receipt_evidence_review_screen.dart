import '../../shared/local_draft_scope.dart';
import '../../data/receipts/receipt_evidence_review_input.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/receipts/receipt_evidence_draft_workflow.dart';
import '../../data/receipts/receipt_submission_session.dart';
import '../../data/receipts/receipt_draft_record.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/local_document_preview.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';
import 'receipt_source_picker.dart';
import 'receipt_photo_text_panel.dart';
import 'receipt_photo_preview.dart';

part 'receipt_evidence_review_widgets.dart';
part 'receipt_evidence_draft_recovery.dart';

@immutable
class ReceiptEvidenceReviewResult {
  const ReceiptEvidenceReviewResult({
    required this.orderedEvidence,
    required this.continueToDetails,
    this.committedReceipt,
  });

  final List<ReceiptEvidenceSelection> orderedEvidence;
  final bool continueToDetails;
  final StoredReceiptDraft? committedReceipt;
}

class ReceiptEvidenceReviewScreen extends StatefulWidget {
  const ReceiptEvidenceReviewScreen({
    required this.evidence,
    required this.permissions,
    this.initialIndex = 0,
    this.receiptDraftId,
    this.receiptRevision,
    this.recoveredWorkflow,
    super.key,
  });

  final List<ReceiptEvidenceSelection> evidence;
  final ExpensePermissions permissions;
  final int initialIndex;
  final String? receiptDraftId;
  final int? receiptRevision;
  final ReceiptEvidenceDraftController? recoveredWorkflow;

  @override
  State<ReceiptEvidenceReviewScreen> createState() =>
      _ReceiptEvidenceReviewScreenState();
}

class _ReceiptEvidenceReviewScreenState
    extends State<ReceiptEvidenceReviewScreen>
    with DraftNavigationGuard {
  late final List<ReceiptEvidenceSelection> _evidence;
  late int _selectedIndex;

  late ReceiptEvidenceDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  bool _saving = false;
  String? _failure;
  ReceiptEvidenceSelection? _undoItem;
  int? _undoIndex;
  ReceiptSubmissionSession? get _submission =>
      ReceiptSubmissionScope.maybeOf(context);
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_openDraft());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _evidence = [...widget.evidence];
    _selectedIndex = _evidence.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _evidence.length - 1);
  }

  ReceiptEvidenceSelection? get _selected =>
      _evidence.isEmpty ? null : _evidence[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canAttachReceipt) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('receipt-evidence-review-screen'),
        message: 'You do not have permission to review receipt evidence.',
      );
    }
    final scope = OperationalScope.of(context);
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('receipt-evidence-review-screen'),
        body: !_ready
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_failure ?? 'Opening saved review…'),
                    TextButton(
                      onPressed: leaveDraftRoute,
                      child: const Text('Back to receipt'),
                    ),
                    if (_draft != null)
                      EditorDraftStatus(
                        state: _draft!.state,
                        onRetry: _draft!.retry,
                        onDiscard: _discardDraft,
                      ),
                  ],
                ),
              )
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final insets = AppLayoutEngine.pageInsetsFor(
                      constraints.maxWidth,
                    );
                    final available = math.max(
                      0,
                      constraints.maxWidth - insets.horizontal,
                    );
                    final layout = AppLayoutEngine.detailWorkspaceFor(
                      available.toDouble(),
                      textScaler: MediaQuery.textScalerOf(context),
                    );
                    final previewHeight = math.min(
                      480.0,
                      math.max(240.0, constraints.maxHeight * 0.5),
                    );
                    final preview = _EvidencePreviewPane(
                      evidence: _selected,
                      selectedIndex: _selectedIndex,
                      evidenceCount: _evidence.length,
                      height: previewHeight,
                    );
                    final order = _EvidenceOrderPanel(
                      evidence: _evidence,
                      selectedIndex: _selectedIndex,
                      onSelect: (index) {
                        setState(() {
                          if (_draft != null) {
                            _bindReview(
                              _reviewInput.select(index),
                              _reviewEvidenceById,
                            );
                          } else {
                            _selectedIndex = index;
                          }
                        });
                        _capture();
                      },
                      onMoveEarlier: (index) => _move(index, index - 1),
                      onMoveLater: (index) => _move(index, index + 1),
                      onRemove: _remove,
                    );
                    return ListView(
                      padding: insets.copyWith(top: 10, bottom: 32),
                      children: [
                        Center(
                          child: SizedBox(
                            width: layout.workspaceWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ExpensesScopeHeader(
                                  view: scope.view,
                                  selectedEmployeeId: scope.selectedEmployeeId,
                                  onViewChanged: scope.setView,
                                  onEmployeeChanged: scope.selectEmployee,
                                  workspaceLabel: 'Receipt evidence',
                                  showBackButton: true,
                                  onBack: leaveDraftRoute,
                                  showEmployeeStrip: false,
                                  showSettings: false,
                                  onSettings: () {},
                                  contextKey: const ValueKey(
                                    'receipt-evidence-context-selector',
                                  ),
                                  viewKey: const ValueKey(
                                    'receipt-evidence-view-selector',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (_draft != null)
                                  EditorDraftStatus(
                                    state: _draft!.state,
                                    onRetry: _draft!.retry,
                                    onDiscard: _discardDraft,
                                  ),
                                if (_failure != null) Text(_failure!),
                                if (_undoItem != null)
                                  TextButton(
                                    onPressed: _undo,
                                    child: const Text('Undo last removal'),
                                  ),
                                Text(
                                  'Review receipt evidence',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Check every image or PDF and put receipt photos in top-to-bottom order.',
                                ),
                                const SizedBox(height: 14),
                                if (layout.columns == 1) ...[
                                  preview,
                                  SizedBox(height: layout.gap),
                                  order,
                                ] else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: layout.columnWidth,
                                        child: preview,
                                      ),
                                      SizedBox(width: layout.gap),
                                      SizedBox(
                                        width: layout.columnWidth,
                                        child: order,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 14),
                                _ReviewActions(
                                  hasEvidence: _evidence.isNotEmpty,
                                  onSave: () =>
                                      _finish(continueToDetails: false),
                                  onContinue: () =>
                                      _finish(continueToDetails: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _move(int from, int to) {
    if (!_ready || _saving) return;
    if (to < 0 || to >= _evidence.length || from == to) return;
    if (_draft != null) {
      setState(
        () => _bindReview(_reviewInput.move(from, to), _reviewEvidenceById),
      );
      _capture();
      return;
    }
    setState(() {
      final item = _evidence.removeAt(from);
      _evidence.insert(to, item);
      _selectedIndex = to;
    });
    _capture();
  }

  void _remove(int index) {
    if (!_ready || _saving) return;
    final removed = _evidence[index];
    setState(() {
      if (_draft != null) {
        _bindReview(_reviewInput.remove(index), _reviewEvidenceById);
        return;
      }
      _undoItem = removed;
      _undoIndex = index;
      _evidence.removeAt(index);
      if (_evidence.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _evidence.length) {
        _selectedIndex = _evidence.length - 1;
      } else if (index < _selectedIndex) {
        _selectedIndex--;
      }
    });
    _capture();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${removed.name} removed from this review.'),
          action: SnackBarAction(label: 'Undo', onPressed: _undo),
        ),
      );
  }

  void _undo() {
    if (_saving || !_ready || _undoItem == null) return;
    setState(() {
      if (_draft != null) {
        _bindReview(_reviewInput.undo(), _reviewEvidenceById);
        return;
      }
      final restoredIndex = (_undoIndex ?? 0).clamp(0, _evidence.length);
      _evidence.insert(restoredIndex, _undoItem!);
      _selectedIndex = restoredIndex;
      _undoItem = null;
      _undoIndex = null;
    });
    _capture();
  }
}
