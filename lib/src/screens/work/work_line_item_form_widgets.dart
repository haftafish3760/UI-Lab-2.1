part of 'work_items_editor.dart';

class _NumberAndUnitRow extends StatelessWidget {
  const _NumberAndUnitRow({
    required this.quantity,
    required this.unit,
    required this.onUnitChanged,
  });

  final TextEditingController quantity;
  final String unit;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final units = <String>{
      unit,
      'item',
      'each',
      'service',
      'hour',
      'foot',
      'meter',
      'gallon',
      'liter',
      'roll',
      'pack',
    };
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: unit,
            decoration: const InputDecoration(labelText: 'Unit'),
            items: units
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onUnitChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

IconData _lineIcon(WorkLineItemType type) => switch (type) {
  WorkLineItemType.labor => Icons.engineering_outlined,
  WorkLineItemType.material => Icons.inventory_2_outlined,
  WorkLineItemType.equipment => Icons.construction_outlined,
  WorkLineItemType.procurement => Icons.local_shipping_outlined,
  WorkLineItemType.fee => Icons.request_quote_outlined,
};

String _formatWorkQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
