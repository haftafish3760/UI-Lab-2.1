import 'package:flutter/material.dart';
import 'estimate_document_items.dart';
import 'work_models.dart';

/// Bounds only the material list; its action and subtotal never scroll away.
class EstimateMaterialsPanel extends StatefulWidget {
  const EstimateMaterialsPanel({
    required this.items,
    required this.onEdit,
    super.key,
  });
  final List<WorkLineItem> items;
  final VoidCallback onEdit;

  @override
  State<EstimateMaterialsPanel> createState() => _EstimateMaterialsPanelState();
}

class _EstimateMaterialsPanelState extends State<EstimateMaterialsPanel> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.padding.vertical - media.viewInsets.bottom;
    final total = widget.items.fold<double>(0, (sum, item) => sum + item.total);
    return Container(
      key: const ValueKey('estimate-materials-panel'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Materials · ${widget.items.length} items',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('estimate-materials-edit'),
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Add or edit materials'),
            ),
          ),
          if (widget.items.isEmpty)
            const Text('No materials added.')
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (available * .5).clamp(120.0, 520.0),
              ),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: const ValueKey('estimate-materials-scroll'),
                  controller: _scroll,
                  primary: false,
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: EstimateDocumentItems(items: widget.items),
                ),
              ),
            ),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              const Text('Materials subtotal'),
              Text(
                '\$${total.toStringAsFixed(2)}',
                key: const ValueKey('estimate-materials-subtotal'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
