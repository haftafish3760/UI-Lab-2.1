import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/work/work_job_attention.dart';
import '../../shared/section_card.dart';
import '../../shared/operational_card_color_scope.dart';
import '../../theme/operational_card_palette.dart';
import 'work_models.dart';

class JobAttentionSummary extends StatelessWidget {
  const JobAttentionSummary({required this.record, super.key});
  final WorkRecord record;
  @override
  Widget build(BuildContext context) {
    final facts = WorkJobAttention(record, DateTime.now());
    if (facts.issues.isEmpty) {
      return const SizedBox.shrink();
    }
    final date = facts.scheduleDate;
    return OperationalCardColorScope(
      tone: OperationalCardPalette.attention,
      builder: (context) => SectionCard(
        backgroundColor: OperationalCardPalette.attention.start,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This job needs attention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final issue in facts.issues)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $issue'),
              ),
            if (date != null)
              Text(
                'Scheduled work: ${DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toLanguageTag()).format(date)}',
              ),
          ],
        ),
      ),
    );
  }
}
