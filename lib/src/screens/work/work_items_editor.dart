import 'package:flutter/material.dart';

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

class WorkItemsEditor extends StatefulWidget {
  const WorkItemsEditor({
    required this.initialItems,
    required this.pricing,
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

class _WorkItemsEditorState extends State<WorkItemsEditor> {
  late final List<WorkLineItem> _items = [...widget.initialItems];

  bool get _materialOnly =>
      widget.allowedTypes.length == 1 &&
      widget.allowedTypes.single == WorkLineItemType.material;

  bool get _jobMaterialMode => widget.allowedJobBillingTreatments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
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
                          onBack: () => Navigator.of(context).pop(),
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
                              item: item,
                              canViewCustomerPrice:
                                  widget.canViewCustomerPrice ||
                                  widget.canSetCustomerPrice,
                              showJobBillingTreatment: _jobMaterialMode,
                              onEdit: () => _editItem(item),
                              onDelete: () => setState(
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
              onPressed: () => Navigator.of(context).pop(_items),
              icon: const Icon(Icons.save_outlined),
              label: Text(_materialOnly ? 'Save materials' : 'Save items'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addNewItem() async {
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
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
    if (item != null && mounted) setState(() => _items.add(item));
  }

  Future<void> _editItem(WorkLineItem original) async {
    final updated = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
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
    setState(() => _items[index] = updated);
  }

  Future<void> _addFromMaterials() async {
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
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _linkEvidence() async {
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
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _addFromTruckStock() async {
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
    if (mounted && item != null) setState(() => _items.add(item));
  }
}

class _ImportActions extends StatelessWidget {
  const _ImportActions({
    required this.onAdd,
    required this.addLabel,
    this.onMaterials,
    this.onEvidence,
    this.onStock,
  });

  final VoidCallback onAdd;
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
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(addLabel),
        ),
        if (onMaterials != null)
          OutlinedButton.icon(
            onPressed: onMaterials,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Use recent material cost'),
          ),
        if (onEvidence != null)
          OutlinedButton.icon(
            key: const ValueKey('link-receipt-expense'),
            onPressed: onEvidence,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Use receipt item'),
          ),
        if (onStock != null)
          OutlinedButton.icon(
            key: const ValueKey('use-truck-stock'),
            onPressed: onStock,
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
