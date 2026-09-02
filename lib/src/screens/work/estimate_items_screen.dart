import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_models.dart';
import '../inventory/inventory_models.dart';
import 'work_detail_header.dart';
import 'work_item_source_picker.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

enum EstimateItemCategory { all, labor, materialsAndCharges }

class EstimateItemsScreen extends StatefulWidget {
  const EstimateItemsScreen({
    required this.initialItems,
    required this.pricing,
    this.category = EstimateItemCategory.all,
    this.selectedDay,
    super.key,
  });

  final List<WorkLineItem> initialItems;
  final WorkPricingModel pricing;
  final EstimateItemCategory category;
  final DateTime? selectedDay;

  @override
  State<EstimateItemsScreen> createState() => _EstimateItemsScreenState();
}

class _EstimateItemsScreenState extends State<EstimateItemsScreen> {
  late final _items = [...widget.initialItems];

  List<WorkLineItem> get _labor =>
      _items.where((item) => item.type == WorkLineItemType.labor).toList();
  List<WorkLineItem> get _materials =>
      _items.where((item) => item.type == WorkLineItemType.material).toList();
  List<WorkLineItem> get _other => _items
      .where(
        (item) =>
            item.type != WorkLineItemType.labor &&
            item.type != WorkLineItemType.material,
      )
      .toList();

  bool get _editingLabor => widget.category == EstimateItemCategory.labor;
  bool get _editingAll => widget.category == EstimateItemCategory.all;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('estimate-items-screen'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.detailWorkspaceFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 12, insets.right, 96),
            children: [
              Center(
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: _editingLabor
                            ? 'Estimate labor'
                            : _editingAll
                            ? 'Estimate items'
                            : 'Materials and charges',
                        selectedDay: widget.selectedDay ?? DateTime.now(),
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _editingLabor
                            ? 'Labor'
                            : _editingAll
                            ? 'Labor and materials'
                            : 'Materials and other charges',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _editingLabor
                            ? 'Add the work, service calls, and helper time included in this estimate.'
                            : _editingAll
                            ? 'Build the customer price while keeping labor and material costs separate.'
                            : 'Add parts, supplies, equipment, material pickup, disposal, and other charges. Private costs stay off the customer copy.',
                      ),
                      const SizedBox(height: 12),
                      _EstimateItemActions(
                        category: widget.category,
                        onLabor: () => _addManual(
                          WorkLineItemType.labor,
                          const [WorkLineItemType.labor],
                        ),
                        onMaterial: () =>
                            _addManual(WorkLineItemType.material, const [
                              WorkLineItemType.material,
                              WorkLineItemType.equipment,
                              WorkLineItemType.procurement,
                              WorkLineItemType.fee,
                            ]),
                        onOther: () =>
                            _addManual(WorkLineItemType.equipment, const [
                              WorkLineItemType.material,
                              WorkLineItemType.equipment,
                              WorkLineItemType.procurement,
                              WorkLineItemType.fee,
                            ]),
                        onHistory: _addFromHistory,
                        onExpense: _addFromExpense,
                      ),
                      const SizedBox(height: 14),
                      if (_editingLabor || _editingAll) ...[
                        _ItemSection(
                          title: 'Labor',
                          helper:
                              'Time, service calls, helpers, and other work performed. Tap an item to edit it.',
                          emptyText: 'No labor has been added.',
                          items: _labor,
                          onEdit: _edit,
                          onRemove: _remove,
                        ),
                        if (_editingAll) const SizedBox(height: 12),
                      ],
                      if (!_editingLabor) ...[
                        _ItemSection(
                          title: 'Materials',
                          helper:
                              'Parts and supplies, with optional receipt or expense evidence. Tap an item to edit it.',
                          emptyText: 'No materials have been added.',
                          items: _materials,
                          onEdit: _edit,
                          onRemove: _remove,
                        ),
                        if (_other.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _ItemSection(
                            title: 'Equipment and other charges',
                            helper:
                                'Equipment, material pickup, disposal, and other charges. Tap an item to edit it.',
                            emptyText: '',
                            items: _other,
                            onEdit: _edit,
                            onRemove: _remove,
                          ),
                        ],
                      ],
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
            key: const ValueKey('save-estimate-items'),
            onPressed: () => Navigator.of(context).pop(_items),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save items'),
          ),
        ),
      ),
    ),
  );

  Future<void> _addManual(
    WorkLineItemType type,
    List<WorkLineItemType> allowedTypes,
  ) async {
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          initialType: type,
          initialUnit: type == WorkLineItemType.labor ? 'hour' : 'item',
          allowedTypes: allowedTypes,
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
        ),
      ),
    );
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _addFromHistory() async {
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
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
        ),
      ),
    );
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _addFromExpense() async {
    final expense = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEvidenceSourcePicker(
          expenses: PrototypeOperationsScope.of(context).expenses,
          recordedOnly: true,
          title: 'Use a receipt item',
          description:
              'Choose a recorded business expense, then choose the exact reviewed material line. The full receipt total is never copied into the estimate.',
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
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
        ),
      ),
    );
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _edit(WorkLineItem original) async {
    final allowedTypes = _editingLabor
        ? const [WorkLineItemType.labor]
        : widget.category == EstimateItemCategory.materialsAndCharges
        ? const [
            WorkLineItemType.material,
            WorkLineItemType.equipment,
            WorkLineItemType.procurement,
            WorkLineItemType.fee,
          ]
        : WorkLineItemType.values;
    final revised = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          initialItem: original,
          allowedTypes: allowedTypes,
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
        ),
      ),
    );
    if (!mounted || revised == null) return;
    final index = _items.indexWhere((item) => item.id == original.id);
    if (index < 0) return;
    setState(() => _items[index] = revised);
  }

  void _remove(WorkLineItem item) => setState(() => _items.remove(item));
}

class _EstimateItemActions extends StatelessWidget {
  const _EstimateItemActions({
    required this.category,
    required this.onLabor,
    required this.onMaterial,
    required this.onOther,
    required this.onHistory,
    required this.onExpense,
  });

  final EstimateItemCategory category;
  final VoidCallback onLabor;
  final VoidCallback onMaterial;
  final VoidCallback onOther;
  final VoidCallback onHistory;
  final VoidCallback onExpense;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (category != EstimateItemCategory.materialsAndCharges)
        FilledButton.icon(
          key: const ValueKey('add-estimate-labor'),
          onPressed: onLabor,
          icon: const Icon(Icons.engineering_outlined),
          label: const Text('Add labor'),
        ),
      if (category != EstimateItemCategory.labor) ...[
        FilledButton.icon(
          key: const ValueKey('add-estimate-material'),
          onPressed: onMaterial,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Add material'),
        ),
        OutlinedButton.icon(
          onPressed: onHistory,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Add from materials'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('link-receipt-expense'),
          onPressed: onExpense,
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Link receipt or expense'),
        ),
        OutlinedButton.icon(
          onPressed: onOther,
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Add other charge'),
        ),
      ],
    ],
  );
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.title,
    required this.helper,
    required this.emptyText,
    required this.items,
    required this.onEdit,
    required this.onRemove,
  });

  final String title;
  final String helper;
  final String emptyText;
  final List<WorkLineItem> items;
  final ValueChanged<WorkLineItem> onEdit;
  final ValueChanged<WorkLineItem> onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          helper,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(emptyText)
        else
          for (final item in items) ...[
            _EstimateItemRow(
              item: item,
              onEdit: () => onEdit(item),
              onRemove: () => onRemove(item),
            ),
            if (item != items.last) const SizedBox(height: 8),
          ],
      ],
    ),
  );
}

class _EstimateItemRow extends StatelessWidget {
  const _EstimateItemRow({
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  final WorkLineItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      key: ValueKey('edit-estimate-item-${item.id}'),
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.description.isNotEmpty) Text(item.description),
                  Text(
                    '${_number(item.quantity)} ${item.unit} · ${_money(item.total)}',
                  ),
                  if (item.sourceExpenseId != null)
                    Text(
                      'Linked cost evidence: ${item.sourceExpenseId}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Item actions',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit item')),
                PopupMenuItem(value: 'remove', child: Text('Remove item')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _money(double value) => '\$${value.toStringAsFixed(2)}';
