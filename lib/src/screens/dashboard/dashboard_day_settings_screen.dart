import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';

class DashboardDaySettingsScreen extends StatefulWidget {
  const DashboardDaySettingsScreen({required this.day, super.key});

  final DateTime day;

  @override
  State<DashboardDaySettingsScreen> createState() =>
      _DashboardDaySettingsScreenState();
}

class _DashboardDaySettingsScreenState
    extends State<DashboardDaySettingsScreen> {
  var _showOdometer = false;
  var _showCompletedFirst = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar day settings'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            operationalDateLabel(context, widget.day),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'These choices apply only to the calendar day screen.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show odometer details'),
            subtitle: const Text(
              'Only authorized mileage details can appear in entries.',
            ),
            value: _showOdometer,
            onChanged: (value) => setState(() => _showOdometer = value),
          ),
          SwitchListTile(
            title: const Text('Show completed records first'),
            subtitle: const Text(
              'Changes the presentation only; source records are unchanged.',
            ),
            value: _showCompletedFirst,
            onChanged: (value) => setState(() => _showCompletedFirst = value),
          ),
        ],
      ),
    );
  }
}
