import '../../shared/editor_input_lock.dart';
import 'dart:math' as math;

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
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expenses_scope_header.dart';
import 'expense_editor_screen.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'receipt_evidence_review_screen.dart';
import 'receipt_intake_settings_screen.dart';
import 'receipt_source_picker.dart';

part 'receipt_intake_widgets.dart';
part 'receipt_intake_confirmation.dart';
part 'receipt_intake_media.dart';

class ReceiptIntakeScreen extends StatefulWidget {
  const ReceiptIntakeScreen({
    required this.expenseDate,
    this.draftId,
    this.draftTitle,
    this.linkedJobId,
    this.linkedJobLabel,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final DateTime expenseDate;
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
    final scope = OperationalScope.of(context);
    final draftController = ReceiptDraftUiScope.maybeOf(context);
    final loadingExistingDraft =
        widget.draftId != null && draftController != null && !_draftLoaded;
    return Scaffold(
      key: const ValueKey('receipt-intake-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = math.max(
              0,
              constraints.maxWidth - insets.horizontal,
            );
            final layout = AppLayoutEngine.detailWorkspaceFor(
              available.toDouble(),
              textScaler: MediaQuery.textScalerOf(context),
            );
            final media = ReceiptSubmissionScope.maybeOf(context)?.media;
            final source = EditorInputLock(
              locked: _hasPendingMedia(media),
              child: _ReceiptSourceCard(
                evidence: _evidence,
                openingPicker:
                    _openingPicker || _savingDraft || loadingExistingDraft,
                showEvidenceReminders: _preferences.showEvidenceReminders,
                onCapture: () => _pickMedia(MediaPickerSource.camera),
                onChoosePhotos: () => _pickMedia(MediaPickerSource.library),
                onChooseFiles: () => _pickMedia(MediaPickerSource.files),
                onManualEntry: () => _openReceiptEditor(imageCount: 0),
                onReview: _openEvidenceReview,
                onRemove: _removeEvidence,
              ),
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
                          onSettings: () => _openSettings(context),
                          showSettings: widget.permissions.canConfigureDisplay,
                          workspaceLabel: 'Receipt intake',
                          showBackButton: true,
                          onBack: () => Navigator.of(context).pop(),
                          showEmployeeStrip: false,
                          contextKey: const ValueKey(
                            'receipt-context-selector',
                          ),
                          viewKey: const ValueKey('receipt-view-selector'),
                          settingsKey: const ValueKey(
                            'receipt-settings-button',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.draftTitle == null
                              ? 'Add receipt'
                              : 'Continue receipt draft',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.draftTitle ??
                              operationalDateLabel(context, widget.expenseDate),
                        ),
                        const SizedBox(height: 14),
                        if (_draftFailure case final failure?) ...[
                          Text(
                            failure,
                            key: const ValueKey('receipt-draft-failure'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (media != null) _mediaRecoveryNotice(media),
                        if (layout.columns == 1)
                          Column(
                            children: [
                              source,
                              if (_preferences.showReviewChecklist) ...[
                                SizedBox(height: layout.gap),
                                const _ReceiptReviewSteps(),
                              ],
                            ],
                          )
                        else if (_preferences.showReviewChecklist)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: layout.columnWidth,
                                child: source,
                              ),
                              SizedBox(width: layout.gap),
                              SizedBox(
                                width: layout.columnWidth,
                                child: const _ReceiptReviewSteps(),
                              ),
                            ],
                          )
                        else
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              width: layout.columnWidth,
                              child: source,
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
  }) async {
    if (persistFirst && !await _persistDraft()) return;
    if (!mounted) return;
    final activeDraft =
        sourceReceipt ??
        ReceiptDraftUiScope.maybeOf(context)?.recordById(_activeDraftId ?? '');
    final record = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(
          expenseDate: activeDraft?.expenseDate ?? widget.expenseDate,
          initialCategory: ExpenseCategory.materials,
          initialReceiptType: ExpenseReceiptType.detailed,
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
              title: title,
              expenseDate: widget.expenseDate,
              evidence: imports,
              occurredAtUtc: occurredAtUtc,
              linkedJobId: widget.linkedJobId,
              linkedJobLabel: widget.linkedJobLabel,
            )
          : await controller.update(
              draftId: current.draftId,
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
