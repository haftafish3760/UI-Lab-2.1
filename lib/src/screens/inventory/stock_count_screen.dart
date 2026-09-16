import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'inventory_models.dart';

class StockCountScreen extends StatefulWidget {
  const StockCountScreen({required this.record, super.key});
  final InventoryStockRecord record;
  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  final _form = GlobalKey<FormState>();
  late final _quantity = TextEditingController(
    text: widget.record.confidence == InventoryStockConfidence.unknown
        ? ''
        : '${widget.record.quantity}',
  );
  late final _threshold = TextEditingController(
    text: widget.record.lowAt?.toString() ?? '',
  );
  late bool _watch = widget.record.lowAt != null;
  bool _saved = false;
  @override
  void dispose() {
    _quantity.dispose();
    _threshold.dispose();
    super.dispose();
  }

  String? _number(String? input) {
    final value = double.tryParse(input?.trim() ?? '');
    return value == null || !value.isFinite || value < 0
        ? 'Enter zero or a positive number.'
        : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('stock-count-screen'),
    appBar: AppBar(title: const Text('Check stock')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayoutEngine.maximumFormWorkspaceWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            SectionCard(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.record.materialName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.record.locationLabel),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('stock-quantity-field'),
                      controller: _quantity,
                      validator: _number,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'How many are here now?',
                        helperText:
                            'This replaces the old count. It does not add to it.',
                        suffixText: widget.record.unitLabel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show when running low'),
                      subtitle: const Text(
                        'Applies to this item at this location.',
                      ),
                      value: _watch,
                      onChanged: (value) => setState(() => _watch = value),
                    ),
                    if (_watch)
                      TextFormField(
                        controller: _threshold,
                        validator: _number,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Low at this quantity or less',
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('save-stock-count-button'),
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Save count'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Layout review: changes are not yet saved after closing the app.',
            ),
          ],
        ),
      ),
    ),
  );
  void _save() {
    if (_saved || !_form.currentState!.validate()) return;
    _saved = true;
    Navigator.pop(
      context,
      widget.record.copyWith(
        quantity: double.parse(_quantity.text.trim()),
        confidence: InventoryStockConfidence.verified,
        updatedOn: DateTime.now(),
        lowAt: _watch ? double.parse(_threshold.text.trim()) : null,
        clearLowAt: !_watch,
      ),
    );
  }
}
