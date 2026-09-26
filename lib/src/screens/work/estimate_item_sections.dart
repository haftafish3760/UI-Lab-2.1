part of 'estimate_items_screen.dart';

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
  Widget build(BuildContext context) {
    final primary = <Widget>[
      if (category != EstimateItemCategory.materialsAndCharges)
        FilledButton.icon(
          key: const ValueKey('add-estimate-labor'),
          onPressed: onLabor,
          icon: const Icon(Icons.engineering_outlined),
          label: const Text('Add labor', textAlign: TextAlign.center),
        ),
      if (category != EstimateItemCategory.labor)
        FilledButton.icon(
          key: const ValueKey('add-estimate-material'),
          onPressed: onMaterial,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Add material', textAlign: TextAlign.center),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (AppLayoutEngine.stackCompactFieldsFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            )) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final button in primary)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: button,
                    ),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < primary.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(child: primary[index]),
                  ],
                ],
              ),
            );
          },
        ),
        if (category != EstimateItemCategory.labor) ...[
          const SizedBox(height: 8),
          PopupMenuButton<String>(
            key: const ValueKey('estimate-more-item-options'),
            tooltip: 'Import materials, link expense, or add another charge',
            onSelected: (value) {
              switch (value) {
                case 'materials':
                  onHistory();
                case 'expense':
                  onExpense();
                case 'other':
                  onOther();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'materials',
                child: Text('Add from materials'),
              ),
              PopupMenuItem(
                key: ValueKey('link-receipt-expense'),
                value: 'expense',
                child: Text('Link receipt or expense'),
              ),
              PopupMenuItem(value: 'other', child: Text('Add other charge')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Flexible(child: Text('More item options')),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
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
