import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';

class DaySummary extends StatelessWidget {
  const DaySummary({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Workday Snapshot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Appears after work begins; never shown as empty pre-work clutter.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric('Active time', '6 h 20 m', Icons.timer_outlined),
              _Metric('Miles today', '18.6 mi', Icons.route_outlined),
              _Metric('Completed', '2 of 3', Icons.task_alt),
              _Metric('Expenses', r'$48.72', Icons.receipt_long_outlined),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _noop,
                  icon: const Icon(Icons.local_gas_station_outlined),
                  label: const Text('Add fuel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _noop,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Add expense'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        border: Border.all(color: AppColors.blue),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
