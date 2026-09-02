import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_theme.dart';
import 'dashboard_models.dart';

class TodayEntries extends StatefulWidget {
  const TodayEntries({
    super.key,
    this.date,
    this.entries = demoEntries,
    this.showOdometer = false,
    this.onOpen,
  });

  final DateTime? date;
  final List<DayEntry> entries;
  final bool showOdometer;
  final ValueChanged<DayEntry>? onOpen;

  @override
  State<TodayEntries> createState() => _TodayEntriesState();
}

class _TodayEntriesState extends State<TodayEntries> {
  var _expanded = false;

  @override
  void didUpdateWidget(covariant TodayEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!sameDashboardDay(
      oldWidget.date ?? dashboardToday,
      widget.date ?? dashboardToday,
    )) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<AppSemanticColors>() ??
        (colors.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
    final headerBackground = semantic.currentSurface;
    final headerForeground = colors.onSurface;
    final entries = [...widget.entries]
      ..sort(
        (a, b) => dashboardTimeMinutes(
          a.time,
        ).compareTo(dashboardTimeMinutes(b.time)),
      );
    final visibleCount = _expanded
        ? entries.length
        : entries.length.clamp(0, 3);
    final sectionBackground = Color.alphaBlend(
      semantic.current.withValues(alpha: .055),
      colors.surface,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
        return SectionCard(
          padding: EdgeInsets.zero,
          backgroundColor: sectionBackground,
          borderColor: semantic.current.withValues(alpha: .62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const ValueKey('today-entries-header'),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: headerBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.surface - 1),
                  ),
                ),
                child: _EntriesSectionHeader(
                  title:
                      sameDashboardDay(
                        widget.date ?? dashboardToday,
                        dashboardToday,
                      )
                      ? "Today's Entries"
                      : 'Entries',
                  total: entries.length,
                  expanded: _expanded,
                  foreground: headerForeground,
                  iconColor: semantic.current,
                  type: type,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ),
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _countLabel(visibleCount, entries.length),
                      key: const ValueKey('entries-visible-count'),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No entries have been recorded for this day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    children: [
                      for (var index = 0; index < visibleCount; index++) ...[
                        _EntryRow(
                          entry: entries[index],
                          showOdometer: widget.showOdometer,
                          onTap: widget.onOpen == null
                              ? null
                              : () => widget.onOpen!(entries[index]),
                        ),
                        if (index != visibleCount - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _countLabel(int visible, int total) {
    final noun = total == 1 ? 'entry' : 'entries';
    return '$visible of $total $noun';
  }
}

class _EntriesSectionHeader extends StatelessWidget {
  const _EntriesSectionHeader({
    required this.title,
    required this.total,
    required this.expanded,
    required this.foreground,
    required this.iconColor,
    required this.type,
    required this.onToggle,
  });

  final String title;
  final int total;
  final bool expanded;
  final Color foreground;
  final Color iconColor;
  final AppTypography type;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: [
        Icon(Icons.history_rounded, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: type.sectionTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    if (total <= 3) return titleRow;
    final enlarged = MediaQuery.textScalerOf(context).scale(13) > 18;
    final action = TextButton(
      key: const ValueKey('entries-expand-button'),
      onPressed: onToggle,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      child: enlarged
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expanded ? 'Show less' : 'Show all $total'),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expanded ? 'Show less' : 'Show all $total'),
                const SizedBox(width: 2),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                ),
              ],
            ),
    );
    if (enlarged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          Align(alignment: AlignmentDirectional.centerEnd, child: action),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: titleRow),
        action,
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.showOdometer,
    required this.onTap,
  });

  final DayEntry entry;
  final bool showOdometer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(context);
    return Material(
      key: ValueKey('day-entry-${entry.id}'),
      color: tone.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: tone.border),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
            final compact = AppLayoutEngine.stackOperationalRecordFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: type.operationRowHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: compact ? _compact(context, type) : _wide(context, type),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, AppTypography type) => Row(
    children: [
      _icon(context),
      const SizedBox(width: 10),
      SizedBox(width: 62, child: _time()),
      const SizedBox(width: 6),
      Expanded(child: _details(type)),
      const Icon(Icons.chevron_right, size: 20),
    ],
  );

  Widget _compact(BuildContext context, AppTypography type) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _icon(context),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_details(type), const SizedBox(height: 3), _time()],
        ),
      ),
      const Icon(Icons.chevron_right, size: 20),
    ],
  );

  Widget _icon(BuildContext context) {
    final color = _toneFor(context).accent;
    return CircleAvatar(
      radius: 17,
      backgroundColor: color.withValues(alpha: .13),
      foregroundColor: color,
      child: Icon(entry.kind.icon, size: 18),
    );
  }

  ({Color surface, Color border, Color accent}) _toneFor(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
    return switch (entry.reviewStatus) {
      DayEntryReviewStatus.needsApproval => (
        surface: semantic.attentionSurface,
        border: semantic.attention.withValues(alpha: .74),
        accent: semantic.attention,
      ),
      DayEntryReviewStatus.approved => (
        surface: semantic.successSurface,
        border: semantic.success.withValues(alpha: .7),
        accent: semantic.success,
      ),
      DayEntryReviewStatus.denied => (
        surface: semantic.dangerSurface,
        border: semantic.danger.withValues(alpha: .72),
        accent: semantic.danger,
      ),
      DayEntryReviewStatus.none => (
        surface: Color.alphaBlend(
          semantic.current.withValues(alpha: .045),
          colors.surfaceContainerLow,
        ),
        border: semantic.current.withValues(alpha: .45),
        accent: entry.color,
      ),
    };
  }

  Widget _time() => Text(
    entry.time,
    maxLines: 1,
    softWrap: false,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  Widget _details(AppTypography type) => Builder(
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      final metadata = <String>[
        if (entry.reviewStatus != DayEntryReviewStatus.none)
          entry.reviewStatus.label,
        ?entry.amount,
        entry.detail,
        if (showOdometer)
          if (entry.odometer case final value?) 'Odometer · $value',
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.title,
            style: TextStyle(
              fontSize: type.rowTitle,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            metadata.join(' · '),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: type.rowTitle - 1,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    },
  );
}
