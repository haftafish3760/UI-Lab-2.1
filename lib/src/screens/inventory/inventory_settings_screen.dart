import 'package:flutter/material.dart';

@immutable
class InventoryDisplayPreferences {
  const InventoryDisplayPreferences({
    required this.showTruckStock,
    required this.showCostSources,
  });

  const InventoryDisplayPreferences.defaults()
    : showTruckStock = true,
      showCostSources = true;

  final bool showTruckStock;
  final bool showCostSources;
}

class InventorySettingsScreen extends StatefulWidget {
  const InventorySettingsScreen({
    this.initial = const InventoryDisplayPreferences.defaults(),
    this.workspaceLabel = 'Materials',
    this.showCostSourcesOption = true,
    super.key,
  });

  final InventoryDisplayPreferences initial;
  final String workspaceLabel;
  final bool showCostSourcesOption;

  @override
  State<InventorySettingsScreen> createState() =>
      _InventorySettingsScreenState();
}

class _InventorySettingsScreenState extends State<InventorySettingsScreen> {
  late var _showTruckStock = widget.initial.showTruckStock;
  late var _showCostSources = widget.initial.showCostSources;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.workspaceLabel} settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose what appears on the ${widget.workspaceLabel} screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'These display choices do not change permissions, verified costs, receipt evidence, or stock records.',
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Show truck stock'),
          subtitle: const Text(
            'Display dated quantities and whether each count is verified, reported, or unknown.',
          ),
          value: _showTruckStock,
          onChanged: (value) => setState(() => _showTruckStock = value),
        ),
        if (widget.showCostSourcesOption)
          SwitchListTile(
            title: const Text('Show cost sources'),
            subtitle: const Text(
              'Show how many prices came from receipts or manual confirmation.',
            ),
            value: _showCostSources,
            onChanged: (value) => setState(() => _showCostSources = value),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _showTruckStock = true;
                _showCostSources = true;
              }),
              child: const Text('Restore defaults'),
            ),
            FilledButton.icon(
              key: const ValueKey('save-inventory-settings-button'),
              onPressed: () => Navigator.pop(
                context,
                InventoryDisplayPreferences(
                  showTruckStock: _showTruckStock,
                  showCostSources: _showCostSources,
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text('Save ${widget.workspaceLabel} settings'),
            ),
          ],
        ),
      ],
    ),
  );
}
