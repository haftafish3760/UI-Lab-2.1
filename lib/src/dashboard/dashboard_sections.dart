import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_models.dart';

enum DashboardSectionTone { attention, plan, entries }

class DashboardDateSummary extends StatelessWidget {
  const DashboardDateSummary({
    required this.date,
    required this.onStartWorkday,
    super.key,
  });

  final DateTime date;
  final VoidCallback onStartWorkday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Align(
      key: const ValueKey('dashboard-date-summary'),
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stacks = constraints.maxWidth < 330 || textScale > 1.3;
          final dateLabel = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED DAY',
                style: TextStyle(
                  color: colors.inkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
          final startButton = FilledButton.icon(
            key: const ValueKey('start-workday-button'),
            onPressed: onStartWorkday,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 19),
            label: const Text('Start workday'),
          );
          if (stacks) {
            return Column(
              key: const ValueKey('dashboard-date-content-stacked'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [dateLabel, const SizedBox(height: 8), startButton],
            );
          }
          return Row(
            key: const ValueKey('dashboard-date-content-row'),
            children: [
              Expanded(child: dateLabel),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: startButton,
              ),
            ],
          );
        },
      ),
    );
  }
}

class AttentionRegion extends StatelessWidget {
  const AttentionRegion({
    required this.dismissed,
    required this.onDismiss,
    required this.onRestore,
    super.key,
  });

  final bool dismissed;
  final VoidCallback onDismiss;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (dismissed) {
      final colors = Theme.of(context).extension<DashboardColors>()!;
      return Material(
        key: const ValueKey('attention-collapsed'),
        color: colors.attentionSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.attention),
          borderRadius: BorderRadius.circular(9),
        ),
        child: InkWell(
          onTap: onRestore,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.attention),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '2 unresolved items hidden',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Show',
                  style: TextStyle(
                    color: colors.attention,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return DashboardRecordSection(
      key: const ValueKey('needs-attention-section'),
      title: 'Needs attention',
      countLabel: '2 unresolved',
      icon: Icons.warning_amber_rounded,
      tone: DashboardSectionTone.attention,
      records: attentionRecords,
      initiallyVisible: 2,
      trailing: IconButton(
        key: const ValueKey('dismiss-attention'),
        onPressed: onDismiss,
        tooltip: 'Hide this panel',
        icon: const Icon(Icons.close_rounded, size: 20),
      ),
    );
  }
}

class DashboardRecordSection extends StatefulWidget {
  const DashboardRecordSection({
    required this.title,
    required this.countLabel,
    required this.icon,
    required this.tone,
    required this.records,
    this.initiallyVisible = 3,
    this.trailing,
    super.key,
  });

  final String title;
  final String countLabel;
  final IconData icon;
  final DashboardSectionTone tone;
  final List<DashboardRecord> records;
  final int initiallyVisible;
  final Widget? trailing;

  @override
  State<DashboardRecordSection> createState() => _DashboardRecordSectionState();
}

class _DashboardRecordSectionState extends State<DashboardRecordSection> {
  var expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    final sectionColors = _sectionColors(colors, widget.tone);
    final visible = expanded
        ? widget.records
        : widget.records.take(widget.initiallyVisible).toList();
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          sectionColors.accent.withValues(alpha: .045),
          colors.surface,
        ),
        border: Border.all(color: sectionColors.accent, width: .8),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: sectionColors.surface,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
            child: Row(
              children: [
                Icon(widget.icon, color: sectionColors.accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.countLabel,
                        style: TextStyle(
                          color: colors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
            child: Column(
              children: [
                for (final record in visible) ...[
                  DashboardRecordRow(
                    record: record,
                    accent: sectionColors.accent,
                  ),
                  if (record != visible.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          if (widget.records.length > widget.initiallyVisible)
            TextButton.icon(
              key: ValueKey('${widget.title}-expand'),
              onPressed: () => setState(() => expanded = !expanded),
              iconAlignment: IconAlignment.end,
              icon: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(
                expanded ? 'Show less' : 'Show all ${widget.records.length}',
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardRecordRow extends StatelessWidget {
  const DashboardRecordRow({
    required this.record,
    required this.accent,
    super.key,
  });

  final DashboardRecord record;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    final recordSurface = Color.alphaBlend(
      accent.withValues(
        alpha: Theme.of(context).brightness == Brightness.light ? .11 : .15,
      ),
      colors.surfaceRaised,
    );
    return Material(
      key: ValueKey('record-${record.title}'),
      color: recordSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colors.border.withValues(alpha: .78),
          width: .75,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRecord(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 5, 6),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    record.time,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(record.icon, color: accent, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        record.detail,
                        style: TextStyle(
                          color: colors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRecord(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(record.icon, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(Icons.schedule_outlined),
              title: Text(record.time),
              subtitle: Text(record.detail),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}

({Color accent, Color surface}) _sectionColors(
  DashboardColors colors,
  DashboardSectionTone tone,
) => switch (tone) {
  DashboardSectionTone.attention => (
    accent: colors.attention,
    surface: colors.attentionSurface,
  ),
  DashboardSectionTone.plan => (
    accent: colors.plan,
    surface: colors.planSurface,
  ),
  DashboardSectionTone.entries => (
    accent: colors.entries,
    surface: colors.entriesSurface,
  ),
};
