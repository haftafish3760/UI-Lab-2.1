import '../../data/receipts/receipt_text_editing_session.dart';
import '../../shared/editor_input_lock.dart';

import 'package:flutter/material.dart';

import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/receipts/receipt_draft_record.dart' as draft_data;
import '../../data/receipts/receipt_draft_repository.dart' as draft_data;
import '../../data/receipts/receipt_draft_submission_coordinator.dart';
import '../../data/receipts/receipt_draft_ui_controller.dart';
import '../../data/receipts/receipt_submission_session.dart';
import '../../data/receipts/receipt_media_session.dart';
import '../../data/storage/local_media_picker_request.dart';
import '../../shared/section_card.dart';
import '../../shared/operational_scope.dart';
import 'expense_editor_screen.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'receipt_evidence_review_screen.dart';
import 'receipt_intake_settings_screen.dart';
import 'receipt_source_picker.dart';
import 'receipt_source_choices.dart';
import 'receipt_text_entry_screen.dart';
import '../../data/receipts/receipt_entry_setup.dart';
import '../../data/receipts/receipt_field_proposals.dart';

part 'receipt_intake_widgets.dart';
part 'receipt_intake_confirmation.dart';
part 'receipt_intake_media.dart';

class ReceiptIntakeScreen extends StatefulWidget {
  const ReceiptIntakeScreen({
    required this.expenseDate,
    this.initialReceiptType,
    this.initialCategory = ExpenseCategory.uncategorized,
    this.applyInitialSetup = false,
    this.onDraftReady,
    this.draftId,
    this.draftTitle,
    this.linkedJobId,
    this.linkedJobLabel,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final DateTime expenseDate;
  final ExpenseReceiptType? initialReceiptType;
  final ExpenseCategory initialCategory;
  final bool applyInitialSetup;
  final ValueChanged<String>? onDraftReady;
  final String? draftId;
  final String? draftTitle;
  final String? linkedJobId;
  final String? linkedJobLabel;
  final ExpensePermissions permissions;

  @override
  State<ReceiptIntakeScreen> createState() => _ReceiptIntakeScreenState();
}

class _ReceiptIntakeScreenState extends State<ReceiptIntakeScreen> {
  final _picker = ReceiptSourcePicker();
  final _evidence = <ReceiptEvidenceSelection>[];
  var _openingPicker = false;
  var _savingDraft = false;
  var _draftLoaded = false;
  String? _activeDraftId;
  int? _evidenceBaseRevision;
  String? _draftFailure;
  var _fixturePreferences = const ReceiptIntakeDisplayPreferences();
  ReceiptIntakeDisplayPreferences get _preferences =>
      readReceiptIntakeDisplayPreferences(context, _fixturePreferences);
  ExpenseRecord? _reviewDraft;
  ExpenseReceiptType? _chosenReceiptType;
  ExpenseCategory? _chosenCategory;
  String _pastedText = '';
  ReceiptEntrySetup get _entrySetup => ReceiptEntrySetup(
    category: _chosenCategory ?? widget.initialCategory,
    type:
        _chosenReceiptType ??
        widget.initialReceiptType ??
        (_preferences.detailedReceipts
            ? ExpenseReceiptType.detailed
            : ExpenseReceiptType.basic),
    pastedText: _pastedText,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draftLoaded || widget.draftId == null) {
      _draftLoaded = true;
      return;
    }
    final controller = ReceiptDraftUiScope.maybeOf(context);
    if (controller == null) {
      _draftLoaded = true;
      return;
    }
    final stored = controller.recordById(widget.draftId!);
    if (stored == null) {
      if (controller.phase == ReceiptDraftUiPhase.idle ||
          controller.phase == ReceiptDraftUiPhase.loading) {
        return;
      }
      _draftLoaded = true;
      _draftFailure =
          controller.failure?.message ??
          'That receipt draft is no longer available.';
      return;
    }
    _activeDraftId = stored.draftId;
    _chosenCategory = widget.applyInitialSetup
        ? widget.initialCategory
        : stored.entrySetup?.category;
    _chosenReceiptType = widget.applyInitialSetup
        ? widget.initialReceiptType
        : stored.entrySetup?.type;
    _pastedText = stored.entrySetup?.pastedText ?? '';
    _evidenceBaseRevision = stored.lifecycle.revision;
    _evidence
      ..clear()
      ..addAll(stored.activeEvidence.map(_selectionFromStored));
    _draftLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final media = ReceiptSubmissionScope.maybeOf(context)?.media;
    return media == null
        ? _buildReceipt(context)
        : ListenableBuilder(
            listenable: media,
            builder: (context, _) => _buildReceipt(context),
          );
  }

  Widget _buildReceipt(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canAttachReceipt) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('receipt-intake-screen'),
        message: 'You do not have permission to add receipts.',
      );
    }
    final draftController = ReceiptDraftUiScope.maybeOf(context);
    final loading =
        widget.draftId != null && draftController != null && !_draftLoaded;
    return Scaffold(
      key: const ValueKey('receipt-intake-screen'),
      appBar: AppBar(
        title: Text(
          widget.draftId == null ? 'Add receipt' : 'Continue receipt',
        ),
        actions: [
          if (widget.permissions.canConfigureDisplay)
            IconButton(
              key: const ValueKey('receipt-settings-button'),
              onPressed: () => _openSettings(context),
              tooltip: 'Receipt settings',
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            final media = ReceiptSubmissionScope.maybeOf(context)?.media;
            return ListView(
              padding: insets.copyWith(top: 12, bottom: 32),
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_draftFailure case final failure?) ...[
                          Text(
                            failure,
                            key: const ValueKey('receipt-draft-failure'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (media != null) _mediaRecoveryNotice(media),
                        EditorInputLock(
                          locked: _hasPendingMedia(media),
                          child: _ReceiptSourceCard(
                            evidence: _evidence,
                            openingPicker:
                                _openingPicker || _savingDraft || loading,
                            onCapture: () =>
                                _pickMedia(MediaPickerSource.camera),
                            onChoosePhotos: () =>
                                _pickMedia(MediaPickerSource.library),
                            onText: _openPastedText,
                            pastedText: _pastedText,
                            onReview: _openEvidenceReview,
                            onRemove: _removeEvidence,
                          ),
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
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    if (!widget.permissions.canConfigureDisplay) return;
    final result = await Navigator.of(context)
        .push<ReceiptIntakeDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => ReceiptIntakeSettingsScreen(initial: _preferences),
          ),
        );
    if (mounted && result != null) setState(() => _fixturePreferences = result);
  }

  Future<void> _openReceiptEditor({
    required int imageCount,
    bool persistFirst = true,
    draft_data.StoredReceiptDraft? sourceReceipt,
    ReceiptFieldProposals? suggestedDetails,
  }) async {
    if (persistFirst && !await _persistDraft()) return;
    if (!mounted) return;
    final activeDraft =
        sourceReceipt ??
        ReceiptDraftUiScope.maybeOf(context)?.recordById(_activeDraftId ?? '');
    final record = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(
          suggestedDetails:
              activeDraft?.activeSelectedDetails?.details ?? suggestedDetails,
          expenseDate: activeDraft?.expenseDate ?? widget.expenseDate,
          initialCategory:
              activeDraft?.entrySetup?.category ?? _entrySetup.category,
          initialReceiptType: activeDraft?.entrySetup?.type ?? _entrySetup.type,
          initialReceiptImageCount:
              activeDraft?.activeEvidence.length ?? imageCount,
          initialJobId: activeDraft?.linkedJobId ?? widget.linkedJobId,
          initialJobLabel: activeDraft?.linkedJobLabel ?? widget.linkedJobLabel,
          existing: _reviewDraft,
          receiptDraftId: activeDraft?.draftId,
          permissions: widget.permissions,
          purpose: ExpenseEditorPurpose.receiptReview,
          onConfirm: (record) => _confirmReceiptRecord(
            record,
            expectedReceiptRevision: activeDraft?.lifecycle.revision,
          ),
        ),
      ),
    );
    if (!mounted || record == null) return;
    Navigator.pop(context, record);
  }

  Future<void> _openEvidenceReview(int initialIndex) async {
    if (!await _persistDraft() || !mounted) return;
    final result = await Navigator.of(context)
        .push<ReceiptEvidenceReviewResult>(
          MaterialPageRoute(
            builder: (_) => ReceiptEvidenceReviewScreen(
              assistanceEnabled: _preferences.assistanceEnabled,
              evidence: List.unmodifiable(_evidence),
              permissions: widget.permissions,
              initialIndex: initialIndex,
              receiptDraftId: _activeDraftId,
              receiptRevision: _evidenceBaseRevision,
            ),
          ),
        );
    if (!mounted || result == null) return;
    final committed = result.committedReceipt;
    setState(() {
      if (committed != null) {
        _evidenceBaseRevision = committed.lifecycle.revision;
      }
      _evidence
        ..clear()
        ..addAll(result.orderedEvidence);
    });
    if (committed == null && !await _persistDraft()) return;
    if (!mounted) return;
    if (result.continueToDetails) {
      await _openReceiptEditor(
        imageCount: _evidence.length,
        persistFirst: false,
        sourceReceipt: committed,
        suggestedDetails: result.suggestedDetails,
      );
    }
  }

  Future<void> _removeEvidence(ReceiptEvidenceSelection item) async {
    setState(() => _evidence.remove(item));
    await _persistDraft();
  }

  Future<bool> _persistDraft() async {
    final controller = ReceiptDraftUiScope.maybeOf(context);
    if (controller == null) return true;
    if (_savingDraft) return false;
    setState(() {
      _savingDraft = true;
      _draftFailure = null;
    });
    try {
      final requestedId = _activeDraftId ?? widget.draftId;
      final current = requestedId == null
          ? null
          : controller.recordById(requestedId);
      if (requestedId != null && current == null) {
        _showDraftMessage(
          controller.failure?.message ??
              'That receipt draft is no longer available.',
        );
        return false;
      }
      if (current != null &&
          _evidenceBaseRevision != current.lifecycle.revision) {
        _showDraftMessage(
          'That receipt changed after this review started. Your choices have not been applied; reload and review the receipt.',
        );
        return false;
      }
      final activeEvidenceIds = {
        for (final item
            in current?.activeEvidence ??
                const <draft_data.ReceiptDraftEvidence>[])
          item.evidenceId,
      };
      if (_evidence.any(
        (item) =>
            item.evidenceId != null &&
            !activeEvidenceIds.contains(item.evidenceId),
      )) {
        _showDraftMessage(
          'That receipt draft changed. Reload it and review the receipt order again.',
        );
        return false;
      }
      final retainedIds = [for (final item in _evidence) ?item.evidenceId];
      final imports = [
        for (final item in _evidence)
          if (item.evidenceId == null) _importFrom(item),
      ];
      final occurredAtUtc = DateTime.now().toUtc();
      final title = current?.title ?? widget.draftTitle ?? 'Receipt draft';
      final currentIds = current?.activeEvidence
          .map((item) => item.evidenceId)
          .toList();
      final unchanged =
          currentIds != null &&
          current?.entrySetup?.category == _entrySetup.category &&
          current?.entrySetup?.type == _entrySetup.type &&
          current?.entrySetup?.pastedText == _entrySetup.pastedText &&
          imports.isEmpty &&
          retainedIds.length == currentIds.length &&
          List.generate(
            retainedIds.length,
            (index) => retainedIds[index] == currentIds[index],
          ).every((same) => same);
      final stored = unchanged
          ? current
          : current == null
          ? await controller.create(
              draftId: _newDraftId(occurredAtUtc),
              entrySetup: _entrySetup,
              title: title,
              expenseDate: widget.expenseDate,
              evidence: imports,
              occurredAtUtc: occurredAtUtc,
              linkedJobId: widget.linkedJobId,
              linkedJobLabel: widget.linkedJobLabel,
            )
          : await controller.update(
              draftId: current.draftId,
              entrySetup: _entrySetup,
              expectedRevision: _evidenceBaseRevision,
              title: title,
              expenseDate: current.expenseDate,
              retainedEvidenceIds: retainedIds,
              addedEvidence: imports,
              occurredAtUtc: occurredAtUtc,
              linkedJobId: current.linkedJobId,
              linkedJobLabel: current.linkedJobLabel,
            );
      if (stored == null) {
        _showDraftMessage(
          controller.failure?.message ?? 'The receipt draft was not saved.',
        );
        return false;
      }
      if (!mounted) return false;
      widget.onDraftReady?.call(stored.draftId);
      setState(() {
        _activeDraftId = stored.draftId;
        _evidenceBaseRevision = stored.lifecycle.revision;
        _draftLoaded = true;
        _evidence
          ..clear()
          ..addAll(stored.activeEvidence.map(_selectionFromStored));
      });
      return true;
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  void _updateMedia(VoidCallback change) {
    if (mounted) setState(change);
  }

  void _showDraftMessage(String message) {
    if (!mounted) return;
    setState(() => _draftFailure = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

ReceiptEvidenceSelection _selectionFromStored(
  draft_data.ReceiptDraftEvidence evidence,
) => ReceiptEvidenceSelection(
  path: evidence.localPath,
  name: evidence.originalName,
  kind: evidence.kind == draft_data.ReceiptDraftEvidenceKind.pdf
      ? ReceiptEvidenceKind.pdf
      : ReceiptEvidenceKind.photo,
  evidenceId: evidence.evidenceId,
);

draft_data.ReceiptEvidenceImport _importFrom(ReceiptEvidenceSelection item) =>
    draft_data.ReceiptEvidenceImport(
      sourcePath: item.path,
      originalName: item.name,
      kind: item.kind == ReceiptEvidenceKind.pdf
          ? draft_data.ReceiptDraftEvidenceKind.pdf
          : draft_data.ReceiptDraftEvidenceKind.photo,
    );

String _newDraftId(DateTime occurredAtUtc) =>
    'receipt-draft-${occurredAtUtc.microsecondsSinceEpoch}';
