import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import 'dashboard_models.dart';

class CalendarApprovalScreen extends StatelessWidget {
  const CalendarApprovalScreen({required this.entry, super.key});

  final DayEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Review entry')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(entry.kind.icon, color: colors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.time} · ${entry.kind.label}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const Divider(height: 28),
                    Text(
                      'Submitted record',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Submitted by',
                      value: entry.submittedBy ?? 'Employee not available',
                    ),
                    _DetailRow(
                      label: 'Linked job',
                      value: entry.linkedRecord ?? 'No linked job',
                    ),
                    _DetailRow(
                      label: 'Vendor',
                      value: entry.title.replaceFirst(
                        RegExp(r'\s+receipt$', caseSensitive: false),
                        '',
                      ),
                    ),
                    _DetailRow(label: 'Recorded at', value: entry.time),
                    const Divider(height: 28),
                    Text(
                      'Amount comparison',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SectionCard(
                      backgroundColor: colors.surfaceContainerLow,
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Receipt total',
                            value: entry.amount ?? 'Not recorded',
                            emphasize: true,
                          ),
                          const Divider(height: 18),
                          _DetailRow(
                            label: 'Assigned job amount',
                            value:
                                entry.approvalExpectedAmount ?? 'Not recorded',
                          ),
                          const Divider(height: 18),
                          _DetailRow(
                            label: 'Difference',
                            value: entry.approvalDifference ?? 'Not calculated',
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Why the amounts differ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(entry.approvalReason ?? entry.detail),
                    const SizedBox(height: 24),
                    Text(
                      'Approving changes the review status only. The entry remains at ${entry.time} in the day record.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const ValueKey('deny-calendar-entry'),
                          onPressed: () => Navigator.pop(
                            context,
                            DayEntryReviewStatus.denied,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Return for correction'),
                        ),
                        FilledButton.icon(
                          key: const ValueKey('approve-calendar-entry'),
                          onPressed: () => Navigator.pop(
                            context,
                            DayEntryReviewStatus.approved,
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Approve entry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: emphasize ? 14 : 12.5,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
