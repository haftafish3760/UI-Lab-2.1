import '../../data/work/work_items_draft_input.dart';
import '../../data/work/work_line_item_draft_input.dart';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/nested_editor_draft_status.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_models.dart';
import '../inventory/inventory_models.dart';
import 'work_detail_header.dart';
import 'work_item_source_picker.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'estimate_item_sections.dart';
part 'estimate_items_draft_recovery.dart';

enum EstimateItemCategory { all, labor, materialsAndCharges }

class EstimateItemsScreen extends StatefulWidget {
  const EstimateItemsScreen({
    required this.initialItems,
    required this.pricing,
    this.category = EstimateItemCategory.all,
    this.selectedDay,
    this.draftSession,
    this.recoveryInput,
    this.onDraftChanged,
    this.onSave,
    this.onDiscard,
    super.key,
  });

  final Future<bool> Function(List<WorkLineItem>)? onSave;
  final Future<bool> Function()? onDiscard;
  final DraftAutosaveSession? draftSession;
  final WorkItemsDraftInput? recoveryInput;
  final ValueChanged<WorkItemsDraftInput>? onDraftChanged;
  final List<WorkLineItem> initialItems;
  final WorkPricingModel pricing;
  final EstimateItemCategory category;
  final DateTime? selectedDay;

  @override
  State<EstimateItemsScreen> createState() => _EstimateItemsScreenState();
}

class _EstimateItemsScreenState extends State<EstimateItemsScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.draftSession;
  bool _saving = false;
  @override
  bool get blockDraftNavigation => _saving;
  final _pendingItems = <String, WorkLineItemDraftInput>{};
  WorkLineItemDraftInput? get _pendingItem => _pendingItems.values.firstOrNull;
  void _refresh(VoidCallback change) => setState(change);
  List<WorkLineItemType> get _allowedTypes => _editingLabor
      ? const [WorkLineItemType.labor]
      : _editingAll
      ? WorkLineItemType.values
      : WorkLineItemType.values
            .where((type) => type != WorkLineItemType.labor)
            .toList();
  @override
  void initState() {
    super.initState();
    final input = widget.recoveryInput;
    if (input != null) {
      _items
        ..clear()
        ..addAll(input.items);
      _pendingItems.addEntries(
        input.pendingItems.map((item) => MapEntry(item.lineId, item)),
      );
    }
  }

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
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
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
                          onBack: () => leaveDraftRoute(),
                          showDateContext: true,
                        ),
                        if (widget.draftSession != null)
                          NestedEditorDraftStatus(
                            session: widget.draftSession!,
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
                        for (final pending in _pendingItems.values)
                          ListTile(
                            title: Text(
                              pending.name.trim().isEmpty
                                  ? 'Unnamed ${pending.type.label.toLowerCase()}'
                                  : pending.name,
                            ),
                            subtitle: Text(
                              '${pending.type.label} · Unfinished ${pending.original == null ? "item" : "changes"}',
                            ),
                            leading: const Icon(Icons.edit_note_outlined),
                            onTap: () => _resumeItem(pending),
                            trailing: IconButton(
                              tooltip: 'Discard unfinished changes',
                              icon: const Icon(Icons.close),
                              onPressed: () => _confirmDiscardPending(pending),
                            ),
                          ),
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
              onPressed:
                  !_saving &&
                      (_pendingItem == null || widget.onDraftChanged != null)
                  ? _saveItems
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _pendingItem == null ? 'Save items' : 'Save progress',
              ),
            ),
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
          allowedTypes:
              type == WorkLineItemType.labor ||
                  type == WorkLineItemType.material
              ? [type]
              : allowedTypes,
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          onDiscardInput: _discardPendingItem,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
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
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          onDiscardInput: _discardPendingItem,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
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
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          onDiscardInput: _discardPendingItem,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
  }

  Future<void> _edit(WorkLineItem original) async {
    final pending = _pendingItems[original.id];
    if (pending != null) {
      await _resumeItem(pending);
      return;
    }

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
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          onDiscardInput: _discardPendingItem,
        ),
      ),
    );
    if (!mounted || revised == null) return;
    _acceptItem(revised);
  }

  void _remove(WorkLineItem item) => _changeItems(() => _items.remove(item));
}
