import 'package:flutter/material.dart';

import 'expense_models.dart';

class ExpenseLineItemsEditor extends StatefulWidget {
  const ExpenseLineItemsEditor({
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<ExpenseLineItem> items;
  final VoidCallback onAdd;
  final ValueChanged<ExpenseLineItem> onEdit;
  final ValueChanged<ExpenseLineItem> onDelete;

  @override
  State<ExpenseLineItemsEditor> createState() => _ExpenseLineItemsEditorState();
}

class _ExpenseLineItemsEditorState extends State<ExpenseLineItemsEditor> {
  final _search = TextEditingController();
  var _visibleLimit = 25;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final matches = widget.items.where((item) {
      if (query.isEmpty) return true;
      return item.description.toLowerCase().contains(query) ||
          (item.partNumber ?? '').toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query) ||
          (item.jobLabel ?? '').toLowerCase().contains(query);
    }).toList();
    final visible = matches.take(_visibleLimit).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 4, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items on this receipt',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap any item to review or change it.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('add-expense-line-item'),
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add item'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: TextField(
              key: const ValueKey('expense-line-search'),
              controller: _search,
              onChanged: (_) => setState(() => _visibleLimit = 25),
              decoration: InputDecoration(
                labelText: 'Find an item on this receipt',
                hintText: 'Search item, part number, category, or job',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _visibleLimit = 25);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (widget.items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 4, 10, 12),
              child: Text('No receipt items have been added yet.'),
            )
          else if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 4, 10, 12),
              child: Text('No receipt items match that search.'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                'Showing ${visible.length} of ${matches.length}',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final item in visible)
              _EditableExpenseLine(
                item: item,
                onEdit: () => widget.onEdit(item),
                onDelete: () => widget.onDelete(item),
              ),
            if (visible.length < matches.length)
              TextButton.icon(
                onPressed: () => setState(() => _visibleLimit += 25),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'Show ${((matches.length - visible.length).clamp(0, 25))} more',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EditableExpenseLine extends StatelessWidget {
  const _EditableExpenseLine({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseLineItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
    child: Material(
      key: ValueKey('edit-expense-line-${item.id}'),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        mouseCursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 2, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lineDescription(item),
                    style: const TextStyle(fontSize: 12.5, height: 1.2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  expenseMoney(item.total),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit ${item.description}',
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Remove ${item.description}',
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _lineDescription(ExpenseLineItem item) {
  final part = item.partNumber?.trim();
  final partText = part == null || part.isEmpty ? '' : ' · Part $part';
  return '${item.description}$partText\n'
      '${_number(item.quantity)} ${item.unit} × ${expenseMoney(item.unitPrice)}';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
