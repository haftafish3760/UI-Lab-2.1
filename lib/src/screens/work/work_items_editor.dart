import '../../data/work/work_items_draft_input.dart';
import '../../data/work/work_line_item_draft_input.dart';
import 'package:flutter/material.dart';

import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/nested_editor_draft_status.dart';

import '../../layout/app_layout_engine.dart';
import '../../data/prototype_operations_store.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_models.dart';
import '../inventory/inventory_models.dart';
import 'work_detail_header.dart';
import 'work_item_source_picker.dart';
import 'work_models.dart';

part 'work_line_item_form_widgets.dart';
part 'work_line_item_editor.dart';
part 'work_items_draft_recovery.dart';
part 'work_line_item_draft_recovery.dart';

class WorkItemsEditor extends StatefulWidget {
  const WorkItemsEditor({
    required this.initialItems,
    required this.pricing,
    this.draftSession,
    this.recoveryInput,
    this.onDraftChanged,
    this.onConfirm,
    this.onDiscard,
    this.workspaceLabel = 'Estimate Items',
    this.allowedTypes = WorkLineItemType.values,
    this.allowMaterialCostHistory = true,
    this.allowExpenseEvidence = true,
    this.allowTruckStock = false,
    this.canViewInternalCost = true,
    this.canViewCustomerPrice = true,
    this.canSetCustomerPrice = true,
    this.allowedJobBillingTreatments = const [],
    this.selectedDay,
    super.key,
  }) : assert(allowedTypes.length > 0);

  final Future<bool> Function(List<WorkLineItem>)? onConfirm;
  final Future<void> Function()? onDiscard;
  final DraftAutosaveSession? draftSession;
  final WorkItemsDraftInput? recoveryInput;
  final ValueChanged<WorkItemsDraftInput>? onDraftChanged;
  final List<WorkLineItem> initialItems;
  final WorkPricingModel pricing;
  final String workspaceLabel;
  final List<WorkLineItemType> allowedTypes;
  final bool allowMaterialCostHistory;
  final bool allowExpenseEvidence;
  final bool allowTruckStock;
  final bool canViewInternalCost;
  final bool canViewCustomerPrice;
  final bool canSetCustomerPrice;
  final List<JobMaterialBillingTreatment> allowedJobBillingTreatments;
  final DateTime? selectedDay;

  @override
  State<WorkItemsEditor> createState() => _WorkItemsEditorState();
}

class _WorkItemsEditorState extends State<WorkItemsEditor>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.draftSession;
  WorkLineItemDraftInput? _pendingItem;
  bool _confirming = false;
  String? _confirmationError;
  @override
  bool get blockDraftNavigation => _confirming;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void initState() {
    super.initState();
    final input = widget.recoveryInput;
    if (input != null) {
      _items
        ..clear()
        ..addAll(input.items);
      _pendingItem = input.pendingItem;
    }
  }

  late final List<WorkLineItem> _items = [...widget.initialItems];

  bool get _materialOnly =>
      widget.allowedTypes.length == 1 &&
      widget.allowedTypes.single == WorkLineItemType.material;

  bool get _jobMaterialMode => widget.allowedJobBillingTreatments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return guardDraftNavigation(
      Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final available = constraints.maxWidth - insets.horizontal;
              final layout = AppLayoutEngine.detailWorkspaceFor(
                available,
                textScaler: MediaQuery.textScalerOf(context),
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(insets.left, 12, insets.right, 96),
                children: [
                  Center(
                    child: SizedBox(
                      width: layout.columns == 1
                          ? layout.columnWidth
                          : layout.workspaceWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WorkDetailHeader(
                            label: widget.workspaceLabel,
                            selectedDay: widget.selectedDay ?? DateTime.now(),
                            onBack: () => leaveDraftRoute(),
                          ),
                          if (widget.draftSession case final session?)
                            NestedEditorDraftStatus(session: session),
                          if (_pendingItem != null) ...[
                            const Text(
                              'Finish or discard the unfinished item before starting another.',
                            ),
                            TextButton(
                              onPressed: _resumeItem,
                              child: const Text('Continue unfinished item'),
                            ),
                          ],
                          if (_confirmationError != null)
                            Text(_confirmationError!),
                          if (widget.draftSession != null)
                            TextButton(
                              onPressed: _discardItemChanges,
                              child: const Text('Discard item changes'),
                            ),
                          const SizedBox(height: 14),
                          Text(
                            widget.workspaceLabel,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _materialOnly
                                ? 'Record actual material used. Cost evidence stays private, and a customer charge is added only when an authorized person chooses one.'
                                : widget.pricing == WorkPricingModel.flatRate
                                ? 'Build the customer-facing flat-rate scope. Internal costs stay separate.'
                                : 'Add labor, materials, equipment, and other billable work.',
                          ),
                          const SizedBox(height: 12),
                          _ImportActions(
                            enabled: _pendingItem == null,
                            onAdd: _addNewItem,
                            addLabel: _materialOnly
                                ? 'Add material manually'
                                : 'Add line item',
                            onMaterials: widget.allowMaterialCostHistory
                                ? _addFromMaterials
                                : null,
                            onEvidence: widget.allowExpenseEvidence
                                ? _linkEvidence
                                : null,
                            onStock: widget.allowTruckStock
                                ? _addFromTruckStock
                                : null,
                          ),
                          const SizedBox(height: 14),
                          if (_items.isEmpty)
                            _EmptyItems(materialOnly: _materialOnly)
                          else
                            for (final item in _items)
                              _LineItemRow(
                                enabled: _pendingItem == null,
                                item: item,
                                canViewCustomerPrice:
                                    widget.canViewCustomerPrice ||
                                    widget.canSetCustomerPrice,
                                showJobBillingTreatment: _jobMaterialMode,
                                onEdit: () => _editItem(item),
                                onDelete: () => _changeItems(
                                  () => _items.removeWhere(
                                    (candidate) => candidate.id == item.id,
                                  ),
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
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: FilledButton.icon(
                onPressed: _pendingItem == null && !_confirming
                    ? _confirmItems
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(_materialOnly ? 'Save materials' : 'Save items'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addNewItem() async {
    if (_pendingItem != null) return;
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          draftSession: widget.draftSession,
          onDraftChanged: widget.onDraftChanged == null
              ? null
              : _capturePendingItem,
          initialType: widget.allowedTypes.first,
          initialUnit: 'item',
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (item != null && mounted) _acceptItem(item);
  }

  Future<void> _editItem(WorkLineItem original) async {
    if (_pendingItem != null) return;
    final updated = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          draftSession: widget.draftSession,
          onDraftChanged: widget.onDraftChanged == null
              ? null
              : _capturePendingItem,
          initialItem: original,
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    final index = _items.indexWhere((item) => item.id == original.id);
    if (index < 0) return;
    _acceptItem(updated);
  }

  Future<void> _addFromMaterials() async {
    if (_pendingItem != null) return;
    if (!widget.allowMaterialCostHistory) return;
    final source = await Navigator.of(context).push<MaterialCostRecord>(
      MaterialPageRoute(
        builder: (_) => MaterialCostSourcePicker(
          costs: PrototypeOperationsScope.of(context).materialCosts,
        ),
      ),
    );
    if (!mounted || source == null) return;
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          draftSession: widget.draftSession,
          onDraftChanged: widget.onDraftChanged == null
              ? null
              : _capturePendingItem,
          initialType: WorkLineItemType.material,
          initialName: source.materialName,
          initialUnit: source.unitLabel,
          initialCost: source.unitCostCents / 100,
          sourceExpenseId: source.sourceExpenseId,
          sourceReceiptId: source.sourceReceiptId,
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
  }

  Future<void> _linkEvidence() async {
    if (_pendingItem != null) return;
    if (!widget.allowExpenseEvidence) return;
    final expense = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEvidenceSourcePicker(
          expenses: PrototypeOperationsScope.of(context).expenses,
          recordedOnly: true,
          title: 'Use a receipt item',
          description:
              'Choose a recorded business expense, then choose the exact reviewed material line to use. The full receipt total is never copied into the job.',
        ),
      ),
    );
    if (!mounted || expense == null) return;
    final source = await Navigator.of(context).push<ExpenseLineItem>(
      MaterialPageRoute(
        builder: (_) => ExpenseLineItemSourcePicker(expense: expense),
      ),
    );
    if (!mounted || source == null) return;
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          draftSession: widget.draftSession,
          onDraftChanged: widget.onDraftChanged == null
              ? null
              : _capturePendingItem,
          initialType: WorkLineItemType.material,
          initialName: source.description,
          initialQuantity: source.quantity,
          initialUnit: source.unit,
          initialCost: source.unitPrice,
          sourceExpenseId: expense.id,
          sourceExpenseLineId: source.id,
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
  }

  Future<void> _addFromTruckStock() async {
    if (_pendingItem != null) return;
    if (!widget.allowTruckStock) return;
    final store = PrototypeOperationsScope.of(context);
    final source = await Navigator.of(context).push<InventoryStockRecord>(
      MaterialPageRoute(
        builder: (_) => TruckStockSourcePicker(stock: store.inventoryStock),
      ),
    );
    if (!mounted || source == null) return;
    MaterialCostRecord? cost;
    for (final candidate in store.materialCosts) {
      if (candidate.materialId == source.materialId &&
          (cost == null || candidate.purchasedOn.isAfter(cost.purchasedOn))) {
        cost = candidate;
      }
    }
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          draftSession: widget.draftSession,
          onDraftChanged: widget.onDraftChanged == null
              ? null
              : _capturePendingItem,
          initialType: WorkLineItemType.material,
          initialName: source.materialName,
          initialUnit: source.unitLabel,
          initialCost: cost?.unitCostCents == null
              ? null
              : cost!.unitCostCents / 100,
          sourceExpenseId: cost?.sourceExpenseId,
          sourceReceiptId: cost?.sourceReceiptId,
          sourceStockId: source.id,
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
  }
}

class _ImportActions extends StatelessWidget {
  const _ImportActions({
    this.enabled = true,
    required this.onAdd,
    required this.addLabel,
    this.onMaterials,
    this.onEvidence,
    this.onStock,
  });

  final VoidCallback onAdd;
  final bool enabled;
  final String addLabel;
  final VoidCallback? onMaterials;
  final VoidCallback? onEvidence;
  final VoidCallback? onStock;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const ValueKey('add-estimate-line-item'),
          onPressed: enabled ? onAdd : null,
          icon: const Icon(Icons.add_rounded),
          label: Text(addLabel),
        ),
        if (onMaterials != null)
          OutlinedButton.icon(
            onPressed: enabled ? onMaterials : null,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Use recent material cost'),
          ),
        if (onEvidence != null)
          OutlinedButton.icon(
            key: const ValueKey('link-receipt-expense'),
            onPressed: enabled ? onEvidence : null,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Use receipt item'),
          ),
        if (onStock != null)
          OutlinedButton.icon(
            key: const ValueKey('use-truck-stock'),
            onPressed: enabled ? onStock : null,
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Use truck stock'),
          ),
      ],
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems({required this.materialOnly});

  final bool materialOnly;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          const Icon(Icons.playlist_add_rounded, size: 32),
          const SizedBox(height: 8),
          Text(
            materialOnly ? 'No job materials added' : 'No line items yet',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            materialOnly
                ? 'Add a material manually, use confirmed truck stock, or choose one reviewed receipt item. Evidence never becomes a customer charge by itself.'
                : 'Add labor, materials, equipment, material pickup, or other charges. A receipt is evidence of cost—not an automatic customer charge.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
