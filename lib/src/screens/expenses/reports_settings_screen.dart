import 'package:flutter/material.dart';

import 'report_period.dart';

class ReportsSettingsScreen extends StatefulWidget {
  const ReportsSettingsScreen({required this.initial, super.key});

  final ReportDisplayPreferences initial;

  @override
  State<ReportsSettingsScreen> createState() => _ReportsSettingsScreenState();
}

class _ReportsSettingsScreenState extends State<ReportsSettingsScreen> {
  late ReportDisplayPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reports screen settings'),
      actions: [
        TextButton(
          key: const ValueKey('save-report-settings'),
          onPressed: () => Navigator.pop(context, _preferences),
          child: const Text('Save'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Choose which authorized summaries appear on Reports. These choices do not change accounting records or employee access.',
            ),
            const SizedBox(height: 12),
            _switch(
              title: 'Invoiced revenue',
              subtitle: 'Work billed during the selected period.',
              value: _preferences.showInvoicedRevenue,
              onChanged: (value) =>
                  _update(_preferences.copyWith(showInvoicedRevenue: value)),
            ),
            _switch(
              title: 'Money collected',
              subtitle: 'Payments actually received during the period.',
              value: _preferences.showMoneyCollected,
              onChanged: (value) =>
                  _update(_preferences.copyWith(showMoneyCollected: value)),
            ),
            _switch(
              title: 'Recorded expenses',
              subtitle: 'Confirmed business costs in the selected period.',
              value: _preferences.showRecordedExpenses,
              onChanged: (value) =>
                  _update(_preferences.copyWith(showRecordedExpenses: value)),
            ),
            _switch(
              title: 'Estimated gross profit and margin',
              subtitle: 'Invoiced revenue minus recorded costs.',
              value: _preferences.showEstimatedGrossProfit,
              onChanged: (value) => _update(
                _preferences.copyWith(showEstimatedGrossProfit: value),
              ),
            ),
            _switch(
              title: 'Vehicles and fuel',
              subtitle:
                  'Recorded fuel, repair, and maintenance costs. Mileage appears after trip records are stored.',
              value: _preferences.showVehicleHealth,
              onChanged: (value) =>
                  _update(_preferences.copyWith(showVehicleHealth: value)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('reset-report-settings'),
              onPressed: () =>
                  _update(const ReportDisplayPreferences.defaults()),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restore default report layout'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  void _update(ReportDisplayPreferences value) {
    setState(() => _preferences = value);
  }
}
