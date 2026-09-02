import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/local_document_preview.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';
import 'receipt_source_picker.dart';

@immutable
class ReceiptEvidenceReviewResult {
  const ReceiptEvidenceReviewResult({
    required this.orderedEvidence,
    required this.continueToDetails,
  });

  final List<ReceiptEvidenceSelection> orderedEvidence;
  final bool continueToDetails;
}

class ReceiptEvidenceReviewScreen extends StatefulWidget {
  const ReceiptEvidenceReviewScreen({
    required this.evidence,
    required this.permissions,
    this.initialIndex = 0,
    super.key,
  });

  final List<ReceiptEvidenceSelection> evidence;
  final ExpensePermissions permissions;
  final int initialIndex;

  @override
  State<ReceiptEvidenceReviewScreen> createState() =>
      _ReceiptEvidenceReviewScreenState();
}

class _ReceiptEvidenceReviewScreenState
    extends State<ReceiptEvidenceReviewScreen> {
  late final List<ReceiptEvidenceSelection> _evidence;
  late int _selectedIndex;

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
    return Scaffold(
      key: const ValueKey('receipt-evidence-review-screen'),
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
              onSelect: (index) => setState(() => _selectedIndex = index),
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
                          onBack: () => Navigator.of(context).pop(),
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
                        Text(
                          'Review receipt evidence',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: layout.columnWidth,
                                child: preview,
                              ),
                              SizedBox(width: layout.gap),
                              SizedBox(width: layout.columnWidth, child: order),
                            ],
                          ),
                        const SizedBox(height: 14),
                        _ReviewActions(
                          hasEvidence: _evidence.isNotEmpty,
                          onSave: () => _finish(continueToDetails: false),
                          onContinue: () => _finish(continueToDetails: true),
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

  void _move(int from, int to) {
    if (to < 0 || to >= _evidence.length || from == to) return;
    setState(() {
      final item = _evidence.removeAt(from);
      _evidence.insert(to, item);
      _selectedIndex = to;
    });
  }

  void _remove(int index) {
    final removed = _evidence[index];
    setState(() {
      _evidence.removeAt(index);
      if (_evidence.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _evidence.length) {
        _selectedIndex = _evidence.length - 1;
      } else if (index < _selectedIndex) {
        _selectedIndex--;
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${removed.name} removed from this review.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                final restoredIndex = index.clamp(0, _evidence.length);
                _evidence.insert(restoredIndex, removed);
                _selectedIndex = restoredIndex;
              });
            },
          ),
        ),
      );
  }

  void _finish({required bool continueToDetails}) {
    Navigator.of(context).pop(
      ReceiptEvidenceReviewResult(
        orderedEvidence: List.unmodifiable(_evidence),
        continueToDetails: continueToDetails,
      ),
    );
  }
}

class _EvidencePreviewPane extends StatelessWidget {
  const _EvidencePreviewPane({
    required this.evidence,
    required this.selectedIndex,
    required this.evidenceCount,
    required this.height,
  });

  final ReceiptEvidenceSelection? evidence;
  final int selectedIndex;
  final int evidenceCount;
  final double height;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          evidence == null
              ? 'No receipt evidence selected'
              : 'Item ${selectedIndex + 1} of $evidenceCount',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (evidence case final item?) ...[
          const SizedBox(height: 2),
          Text(item.name),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: LocalDocumentPreview(
              key: ValueKey('receipt-evidence-preview-${item.identity}'),
              path: item.path,
              kind: item.kind == ReceiptEvidenceKind.pdf
                  ? LocalDocumentKind.pdf
                  : LocalDocumentKind.image,
              semanticsLabel: 'Preview of ${item.name}',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pinch, scroll, or drag to inspect the original.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class _EvidenceOrderPanel extends StatelessWidget {
  const _EvidenceOrderPanel({
    required this.evidence,
    required this.selectedIndex,
    required this.onSelect,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onRemove,
  });

  final List<ReceiptEvidenceSelection> evidence;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onMoveEarlier;
  final ValueChanged<int> onMoveLater;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receipt order', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(
          evidence.isEmpty
              ? 'Return to receipt sources to add an image or PDF.'
              : 'Select an item to preview it. Use the labeled controls to change photo order.',
        ),
        if (evidence.isNotEmpty) const SizedBox(height: 10),
        for (var index = 0; index < evidence.length; index++) ...[
          _EvidenceOrderRow(
            key: ValueKey('receipt-evidence-order-${evidence[index].identity}'),
            evidence: evidence[index],
            position: index + 1,
            isSelected: index == selectedIndex,
            canMoveEarlier: index > 0,
            canMoveLater: index < evidence.length - 1,
            onSelect: () => onSelect(index),
            onMoveEarlier: () => onMoveEarlier(index),
            onMoveLater: () => onMoveLater(index),
            onRemove: () => onRemove(index),
          ),
          if (index < evidence.length - 1) const SizedBox(height: 8),
        ],
      ],
    ),
  );
}

class _EvidenceOrderRow extends StatelessWidget {
  const _EvidenceOrderRow({
    required this.evidence,
    required this.position,
    required this.isSelected,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onSelect,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onRemove,
    super.key,
  });

  final ReceiptEvidenceSelection evidence;
  final int position;
  final bool isSelected;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onSelect;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: isSelected,
    button: true,
    label: 'Receipt item $position, ${evidence.name}',
    child: Material(
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    evidence.kind == ReceiptEvidenceKind.pdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$position. ${evidence.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          evidence.kind == ReceiptEvidenceKind.pdf
                              ? 'PDF document'
                              : 'Receipt photo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: canMoveEarlier ? onMoveEarlier : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Earlier'),
                  ),
                  TextButton.icon(
                    onPressed: canMoveLater ? onMoveLater : null,
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Later'),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.hasEvidence,
    required this.onSave,
    required this.onContinue,
  });

  final bool hasEvidence;
  final VoidCallback onSave;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 8,
    children: [
      OutlinedButton(onPressed: onSave, child: const Text('Save order')),
      FilledButton.icon(
        onPressed: hasEvidence ? onContinue : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue to receipt details'),
      ),
    ],
  );
}
