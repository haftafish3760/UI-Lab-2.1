import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/receipts/receipt_draft_record.dart';
import '../../data/receipts/receipt_draft_ui_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/local_document_preview.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'expense_record_unavailable.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

class ExpenseReceiptEvidenceScreen extends StatefulWidget {
  const ExpenseReceiptEvidenceScreen({
    required this.expenseId,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final String expenseId;
  final ExpensePermissions permissions;

  @override
  State<ExpenseReceiptEvidenceScreen> createState() =>
      _ExpenseReceiptEvidenceScreenState();
}

class _ExpenseReceiptEvidenceScreenState
    extends State<ExpenseReceiptEvidenceScreen> {
  ReceiptDraftUiController? _draftController;
  String? _receiptId;
  Future<ReceiptDraftLookupResult>? _lookup;
  var _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final receiptId = ExpenseUiScope.maybeOf(
      context,
    )?.receiptIdForExpense(widget.expenseId);
    final controller = ReceiptDraftUiScope.maybeOf(context);
    if (receiptId == _receiptId && identical(controller, _draftController)) {
      return;
    }
    _receiptId = receiptId;
    _draftController = controller;
    _selectedIndex = 0;
    _lookup = receiptId == null || controller == null
        ? null
        : controller.findById(draftId: receiptId, includeClosed: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView || !widget.permissions.canViewAmounts) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('expense-receipt-evidence-denied'),
        message: 'You do not have permission to view receipt evidence.',
      );
    }
    final scope = OperationalScope.of(context);
    final expenseController = ExpenseUiScope.maybeOf(context);
    final expense = expenseController == null
        ? PrototypeOperationsScope.of(
            context,
          ).expenses.where((item) => item.id == widget.expenseId).firstOrNull
        : expenseController.recordById(widget.expenseId);
    if (expense == null) {
      return ExpenseRecordUnavailable(
        screenKey: ValueKey('expense-evidence-unavailable-${widget.expenseId}'),
      );
    }
    return Scaffold(
      key: const ValueKey('expense-receipt-evidence-screen'),
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
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExpensesSettingsScreen(),
                            ),
                          ),
                          showSettings: widget.permissions.canConfigureDisplay,
                          workspaceLabel: 'Receipt evidence',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(
                            context,
                            expense.resolvedDate ?? dashboardToday,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.displayVendor,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        _EvidenceBody(
                          expenseId: expense.id,
                          receiptId: _receiptId,
                          lookup: _lookup,
                          selectedIndex: _selectedIndex,
                          layout: layout,
                          previewHeight: math.min(
                            520,
                            math.max(260, constraints.maxHeight * 0.52),
                          ),
                          onSelect: (index) =>
                              setState(() => _selectedIndex = index),
                          onRetry: _retry,
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

  void _retry() {
    final controller = _draftController;
    final receiptId = _receiptId;
    if (controller == null || receiptId == null) return;
    setState(() {
      _lookup = controller.findById(draftId: receiptId, includeClosed: true);
    });
  }
}

class _EvidenceBody extends StatelessWidget {
  const _EvidenceBody({
    required this.expenseId,
    required this.receiptId,
    required this.lookup,
    required this.selectedIndex,
    required this.layout,
    required this.previewHeight,
    required this.onSelect,
    required this.onRetry,
  });

  final String expenseId;
  final String? receiptId;
  final Future<ReceiptDraftLookupResult>? lookup;
  final int selectedIndex;
  final DetailWorkspaceLayout layout;
  final double previewHeight;
  final ValueChanged<int> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (receiptId == null) {
      return const _EvidenceMessage(
        title: 'No retained receipt is linked',
        message:
            'This expense has no durable receipt evidence link. Nothing was substituted or guessed.',
      );
    }
    if (lookup == null) {
      return const _EvidenceMessage(
        title: 'Receipt evidence storage is unavailable',
        message:
            'The expense remains available, but its retained receipt files cannot be opened in this session.',
      );
    }
    return FutureBuilder<ReceiptDraftLookupResult>(
      future: lookup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SectionCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data;
        if (result == null || !result.succeeded) {
          return _EvidenceMessage(
            title: 'Receipt evidence unavailable',
            message:
                result?.failure?.message ??
                'The retained receipt evidence could not be opened.',
            actionLabel: 'Try again',
            onAction: onRetry,
          );
        }
        final draft = result.record!;
        if (draft.state != ReceiptDraftState.submitted ||
            draft.submittedExpenseId != expenseId ||
            draft.draftId != receiptId) {
          return const _EvidenceMessage(
            title: 'Receipt link could not be verified',
            message:
                'The retained files are not linked to this exact confirmed expense, so no evidence is shown.',
          );
        }
        final evidence = draft.activeEvidence;
        if (evidence.isEmpty) {
          return const _EvidenceMessage(
            title: 'No retained receipt files',
            message:
                'The receipt record exists, but it does not contain an active image or PDF.',
          );
        }
        final selected = selectedIndex.clamp(0, evidence.length - 1);
        final preview = _ReadOnlyPreview(
          evidence: evidence[selected],
          position: selected + 1,
          count: evidence.length,
          height: previewHeight,
        );
        final files = _EvidenceFileList(
          draftTitle: draft.title,
          evidence: evidence,
          selectedIndex: selected,
          onSelect: onSelect,
        );
        if (layout.columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              preview,
              SizedBox(height: layout.gap),
              files,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: layout.columnWidth, child: preview),
            SizedBox(width: layout.gap),
            SizedBox(width: layout.columnWidth, child: files),
          ],
        );
      },
    );
  }
}

class _ReadOnlyPreview extends StatelessWidget {
  const _ReadOnlyPreview({
    required this.evidence,
    required this.position,
    required this.count,
    required this.height,
  });

  final ReceiptDraftEvidence evidence;
  final int position;
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: const ValueKey('confirmed-receipt-preview-panel'),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Retained file $position of $count',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(evidence.originalName),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: LocalDocumentPreview(
            key: ValueKey('confirmed-receipt-preview-${evidence.evidenceId}'),
            path: evidence.localPath,
            kind: evidence.kind == ReceiptDraftEvidenceKind.pdf
                ? LocalDocumentKind.pdf
                : LocalDocumentKind.image,
            semanticsLabel: 'Retained receipt file ${evidence.originalName}',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Read-only evidence copy. Receipt items, totals, and editing stay on Expense details.',
        ),
      ],
    ),
  );
}

class _EvidenceFileList extends StatelessWidget {
  const _EvidenceFileList({
    required this.draftTitle,
    required this.evidence,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String draftTitle;
  final List<ReceiptDraftEvidence> evidence;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SectionCard(
    key: const ValueKey('confirmed-receipt-file-list'),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receipt files', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(draftTitle),
        const SizedBox(height: 10),
        for (var index = 0; index < evidence.length; index++) ...[
          _EvidenceFileButton(
            evidence: evidence[index],
            position: index + 1,
            selected: index == selectedIndex,
            onPressed: () => onSelect(index),
          ),
          if (index < evidence.length - 1) const SizedBox(height: 8),
        ],
      ],
    ),
  );
}

class _EvidenceFileButton extends StatelessWidget {
  const _EvidenceFileButton({
    required this.evidence,
    required this.position,
    required this.selected,
    required this.onPressed,
  });

  final ReceiptDraftEvidence evidence;
  final int position;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: 'Receipt file $position, ${evidence.originalName}',
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                evidence.kind == ReceiptDraftEvidenceKind.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.originalName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('File $position'),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EvidenceMessage extends StatelessWidget {
  const _EvidenceMessage({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(message),
        if (actionLabel case final label?) ...[
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onAction, child: Text(label)),
        ],
      ],
    ),
  );
}
