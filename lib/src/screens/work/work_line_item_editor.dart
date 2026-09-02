part of 'work_items_editor.dart';

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.item,
    required this.canViewCustomerPrice,
    required this.showJobBillingTreatment,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkLineItem item;
  final bool canViewCustomerPrice;
  final bool showJobBillingTreatment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          Icon(_lineIcon(item.type), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(_summary),
                if (item.sourceExpenseId != null)
                  const Text('Linked to a recorded expense line'),
                if (item.sourceReceiptId != null)
                  const Text('Confirmed receipt evidence retained'),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Line item actions',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit item')),
              PopupMenuItem(value: 'delete', child: Text('Delete item')),
            ],
          ),
        ],
      ),
    ),
  );

  String get _summary {
    final quantity =
        '${item.type.label} · ${_formatWorkQuantity(item.quantity)} ${item.unit}';
    if (!showJobBillingTreatment) {
      return canViewCustomerPrice
          ? '$quantity · ${item.total.toStringAsFixed(2)} USD'
          : '$quantity · Customer charge hidden';
    }
    final treatment = item.resolvedJobMaterialBillingTreatment;
    if (treatment == JobMaterialBillingTreatment.nonBillable ||
        !canViewCustomerPrice) {
      return '$quantity · ${treatment.statusLabel}';
    }
    return '$quantity · ${treatment.statusLabel} · '
        '${item.total.toStringAsFixed(2)} USD';
  }
}

class WorkLineItemEditor extends StatefulWidget {
  const WorkLineItemEditor({
    this.initialItem,
    this.initialType = WorkLineItemType.material,
    this.initialName = '',
    this.initialUnit = 'item',
    this.initialQuantity = 1,
    this.initialCost,
    this.sourceExpenseId,
    this.sourceExpenseLineId,
    this.sourceReceiptId,
    this.sourceStockId,
    this.allowedTypes = WorkLineItemType.values,
    this.canViewInternalCost = true,
    this.canSetCustomerPrice = true,
    this.allowedJobBillingTreatments = const [],
    this.selectedDay,
    this.workspaceLabel = 'Line item',
    super.key,
  }) : assert(allowedTypes.length > 0);

  final WorkLineItem? initialItem;
  final WorkLineItemType initialType;
  final String initialName;
  final String initialUnit;
  final double initialQuantity;
  final double? initialCost;
  final String? sourceExpenseId;
  final String? sourceExpenseLineId;
  final String? sourceReceiptId;
  final String? sourceStockId;
  final List<WorkLineItemType> allowedTypes;
  final bool canViewInternalCost;
  final bool canSetCustomerPrice;
  final List<JobMaterialBillingTreatment> allowedJobBillingTreatments;
  final DateTime? selectedDay;
  final String workspaceLabel;

  @override
  State<WorkLineItemEditor> createState() => _WorkLineItemEditorState();
}

class _WorkLineItemEditorState extends State<WorkLineItemEditor> {
  bool get _materialOnly =>
      widget.allowedTypes.length == 1 &&
      widget.allowedTypes.single == WorkLineItemType.material;

  late final _name = TextEditingController(
    text: widget.initialItem?.name ?? widget.initialName,
  );
  late final _description = TextEditingController(
    text: widget.initialItem?.description ?? '',
  );
  late final _quantity = TextEditingController(
    text: _formatWorkQuantity(
      widget.initialItem?.quantity ?? widget.initialQuantity,
    ),
  );
  late final _price = TextEditingController(
    text: widget.initialItem?.customerPrice.toStringAsFixed(2) ?? '',
  );
  late final _cost = TextEditingController(
    text:
        (widget.initialItem?.internalUnitCost ?? widget.initialCost)
            ?.toStringAsFixed(2) ??
        '',
  );
  late var _type = widget.initialItem?.type ?? widget.initialType;
  late var _unit = widget.initialItem?.unit ?? widget.initialUnit;
  late var _billingTreatment =
      widget.initialItem?.jobMaterialBillingTreatment ??
      (widget.allowedJobBillingTreatments.isEmpty
          ? JobMaterialBillingTreatment.nonBillable
          : widget.allowedJobBillingTreatments.first);

  bool get _jobMaterialMode => widget.allowedJobBillingTreatments.isNotEmpty;

  bool get _chargesCustomer =>
      !_jobMaterialMode ||
      _billingTreatment != JobMaterialBillingTreatment.nonBillable;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    _price.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 12, insets.right, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: widget.initialItem == null
                            ? 'Add ${widget.workspaceLabel}'
                            : 'Edit ${widget.workspaceLabel}',
                        selectedDay: widget.selectedDay ?? DateTime.now(),
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 14),
                      if (widget.allowedTypes.length > 1) ...[
                        DropdownButtonFormField<WorkLineItemType>(
                          initialValue: _type,
                          decoration: const InputDecoration(
                            labelText: 'Item type',
                          ),
                          items: [
                            for (final type in widget.allowedTypes)
                              DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _type = value ?? _type),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _description,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Customer-facing description',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NumberAndUnitRow(
                        quantity: _quantity,
                        unit: _unit,
                        onUnitChanged: (value) => setState(() => _unit = value),
                      ),
                      const SizedBox(height: 10),
                      if (_jobMaterialMode) ...[
                        DropdownButtonFormField<JobMaterialBillingTreatment>(
                          key: const ValueKey('job-material-billing-treatment'),
                          isExpanded: true,
                          initialValue: _billingTreatment,
                          decoration: const InputDecoration(
                            labelText: 'How should this material be billed?',
                          ),
                          items: [
                            for (final treatment
                                in widget.allowedJobBillingTreatments)
                              DropdownMenuItem(
                                value: treatment,
                                child: Text(treatment.label),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () =>
                                _billingTreatment = value ?? _billingTreatment,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _billingTreatment.description,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (widget.canSetCustomerPrice && _chargesCustomer)
                        TextField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Customer price per unit',
                            suffixText: 'USD',
                          ),
                        )
                      else if (_jobMaterialMode)
                        const SectionCard(
                          child: Text(
                            'No customer charge will be added. This records material use and cost only.',
                          ),
                        )
                      else if (!widget.canSetCustomerPrice)
                        const SectionCard(
                          child: Text(
                            'Customer pricing is restricted. An authorized person can review billing later.',
                          ),
                        ),
                      if (widget.canViewInternalCost) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cost,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Internal cost per unit (optional)',
                            helperText:
                                'Private cost is never shown on the customer estimate.',
                            suffixText: 'USD',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _save,
                        child: Text(
                          widget.initialItem == null
                              ? _materialOnly
                                    ? 'Add material'
                                    : 'Add line item'
                              : 'Save item changes',
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

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an item name.')));
      return;
    }
    Navigator.of(context).pop(
      WorkLineItem(
        id:
            widget.initialItem?.id ??
            'line-${DateTime.now().microsecondsSinceEpoch}',
        type: _type,
        name: _name.text.trim(),
        description: _description.text.trim(),
        quantity: double.tryParse(_quantity.text) ?? 1,
        unit: _unit,
        customerPrice: widget.canSetCustomerPrice
            ? _chargesCustomer
                  ? double.tryParse(_price.text) ?? 0
                  : 0
            : widget.initialItem?.customerPrice ?? 0,
        internalUnitCost: widget.canViewInternalCost
            ? double.tryParse(_cost.text)
            : widget.initialItem?.internalUnitCost ?? widget.initialCost,
        sourceExpenseId:
            widget.initialItem?.sourceExpenseId ?? widget.sourceExpenseId,
        sourceExpenseLineId:
            widget.initialItem?.sourceExpenseLineId ??
            widget.sourceExpenseLineId,
        sourceReceiptId:
            widget.initialItem?.sourceReceiptId ?? widget.sourceReceiptId,
        sourceStockId:
            widget.initialItem?.sourceStockId ?? widget.sourceStockId,
        isJobAddition: widget.initialItem?.isJobAddition ?? false,
        jobMaterialBillingTreatment: _jobMaterialMode
            ? _billingTreatment
            : widget.initialItem?.jobMaterialBillingTreatment,
      ),
    );
  }
}
