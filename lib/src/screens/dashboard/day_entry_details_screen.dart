import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import '../../shared/section_card.dart';
import 'dashboard_models.dart';

class DayEntryDetailsScreen extends StatelessWidget {
  const DayEntryDetailsScreen({
    super.key,
    required this.entry,
    required this.date,
    required this.showOdometer,
  });

  final DayEntry entry;
  final DateTime date;
  final bool showOdometer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('${entry.kind.label} details')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: entry.color.withValues(
                                alpha: .14,
                              ),
                              foregroundColor: entry.color,
                              child: Icon(entry.kind.icon),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    entry.kind.label,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _Detail(
                          label: 'Date',
                          value: operationalDateLabel(context, date),
                        ),
                        _Detail(label: 'Time', value: entry.time),
                        _Detail(label: 'Record ID', value: entry.id),
                        if (entry.customer case final value?)
                          _Detail(label: 'Customer', value: value),
                        if (entry.amount case final value?)
                          _Detail(label: 'Amount', value: value),
                        _Detail(label: 'Details', value: entry.detail),
                        if (showOdometer)
                          if (entry.odometer case final value?)
                            _Detail(label: 'Odometer (shared)', value: value),
                      ],
                    ),
                  ),
                  if (!showOdometer && entry.odometer != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Odometer is private and not shared in this view',
                      child: Text(
                        'Odometer details are hidden because sharing is not enabled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
