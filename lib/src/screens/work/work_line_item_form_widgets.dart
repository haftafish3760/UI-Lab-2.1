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
      'piece',
      'yard',
      'box',
      'bag',
      'package',
      'case',
      'day',
      'mile',
      'kilometer',
      'trip',
      'load',
      'square foot',
      'square meter',
    };
    final fields = <Widget>[
      TextField(
        controller: quantity,
        textInputAction: TextInputAction.next,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: unit == 'hour' ? 'Hours per worker' : 'Quantity',
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: unit,
        isExpanded: true,
        itemHeight: null,
        decoration: const InputDecoration(labelText: 'Unit of measure'),
        items: units
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          if (value != null) onUnitChanged(value);
        },
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppLayoutEngine.stackCompactFieldsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        )) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fields[1], const SizedBox(height: 20), fields[0]],
          );
        }
        return Row(
          children: [
            Expanded(child: fields[1]),
            const SizedBox(width: 10),
            Expanded(child: fields[0]),
          ],
        );
      },
    );
  }
}

IconData _lineIcon(WorkLineItemType type) => switch (type) {
  WorkLineItemType.service => Icons.home_repair_service_outlined,
  WorkLineItemType.labor => Icons.engineering_outlined,
  WorkLineItemType.material => Icons.inventory_2_outlined,
  WorkLineItemType.equipment => Icons.construction_outlined,
  WorkLineItemType.procurement => Icons.local_shipping_outlined,
  WorkLineItemType.fee => Icons.request_quote_outlined,
};

String _formatWorkQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
