import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_theme.dart';
import 'dashboard_models.dart';

enum PlanAction { viewDetails, markArrived, reschedule, markComplete }

class TodayPlan extends StatefulWidget {
  const TodayPlan({
    super.key,
    this.date,
    this.items = demoPlan,
    this.onOpen,
    this.onAction,
    this.allowedActions = const {
      PlanAction.viewDetails,
      PlanAction.markArrived,
      PlanAction.reschedule,
      PlanAction.markComplete,
    },
  });

  final DateTime? date;
  final List<PlanItem> items;
  final ValueChanged<PlanItem>? onOpen;
  final void Function(PlanItem item, PlanAction action)? onAction;
  final Set<PlanAction> allowedActions;

  @override
  State<TodayPlan> createState() => _TodayPlanState();
}

class _TodayPlanState extends State<TodayPlan> {
  var _expanded = false;

  @override
  void didUpdateWidget(covariant TodayPlan oldWidget) {
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
    final headerBackground = semantic.plannedSurface;
    final headerForeground = colors.onSurface;
    final items = [...widget.items]
      ..sort(
        (a, b) => dashboardTimeMinutes(
          a.time,
        ).compareTo(dashboardTimeMinutes(b.time)),
      );
    final visibleCount = _expanded ? items.length : items.length.clamp(0, 3);
    final sectionBackground = Color.alphaBlend(
      semantic.planned.withValues(alpha: .055),
      colors.surface,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
        return SectionCard(
          padding: EdgeInsets.zero,
          backgroundColor: sectionBackground,
          borderColor: semantic.planned.withValues(alpha: .62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const ValueKey('today-plan-header'),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: headerBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.surface - 1),
                  ),
                ),
                child: _PlanSectionHeader(
                  title:
                      sameDashboardDay(
                        widget.date ?? dashboardToday,
                        dashboardToday,
                      )
                      ? "Today's Plan"
                      : 'Planned Work',
                  total: items.length,
                  expanded: _expanded,
                  foreground: headerForeground,
                  iconColor: semantic.planned,
                  type: type,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _countLabel(visibleCount, items.length),
                    key: const ValueKey('plan-visible-count'),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: [
                    if (items.isEmpty)
                      const _EmptyPlan()
                    else
                      for (var i = 0; i < visibleCount; i++) ...[
                        _PlanRow(
                          item: items[i],
                          onOpen: widget.onOpen,
                          onAction: widget.onAction,
                          allowedActions: widget.allowedActions,
                        ),
                        if (i != visibleCount - 1) const SizedBox(height: 8),
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
    if (total == 0) return 'No stops planned';
    final noun = total == 1 ? 'stop' : 'stops';
    return '$visible of $total $noun';
  }
}

class _PlanSectionHeader extends StatelessWidget {
  const _PlanSectionHeader({
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
        Icon(Icons.event_note_outlined, size: 20, color: iconColor),
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
      key: const ValueKey('plan-expand-button'),
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.item,
    required this.allowedActions,
    this.onOpen,
    this.onAction,
  });

  final PlanItem item;
  final ValueChanged<PlanItem>? onOpen;
  final void Function(PlanItem item, PlanAction action)? onAction;
  final Set<PlanAction> allowedActions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('plan-row-${item.id}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen == null ? null : _openDetails,
        mouseCursor: SystemMouseCursors.click,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primaryContainer.withValues(alpha: .8);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.primaryContainer.withValues(alpha: .45);
          }
          return null;
        }),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
            final enlargedText =
                MediaQuery.textScalerOf(context).scale(type.rowTitle) > 18;
            final compact = AppLayoutEngine.stackOperationalRecordFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? 60 : type.operationRowHeight,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
                child: compact
                    ? _compactContent(context, type, enlargedText)
                    : _wideContent(context, type),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wideContent(BuildContext context, AppTypography type) {
    return Row(
      children: [
        _StatusBar(color: item.color),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: _TimeLabel(item.time)),
        Icon(item.icon, color: item.color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: type.rowTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.status != 'Scheduled') _statusLabel(context),
            ],
          ),
        ),
        _actions(context),
      ],
    );
  }

  Widget _compactContent(
    BuildContext context,
    AppTypography type,
    bool enlargedText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StatusBar(color: item.color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: type.rowTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.status != 'Scheduled') _statusLabel(context),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (!enlargedText) ...[
                    Icon(item.icon, color: item.color, size: 17),
                    const SizedBox(width: 6),
                  ],
                  _TimeLabel(item.time),
                ],
              ),
            ],
          ),
        ),
        _actions(context),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<PlanAction>(
        key: ValueKey('plan-actions-${item.id}'),
        tooltip: 'Stop actions',
        icon: const Icon(Icons.more_vert, size: 20),
        constraints: const BoxConstraints(minWidth: 200),
        onSelected: (action) {
          if (action == PlanAction.viewDetails) {
            _openDetails();
          } else if (onAction case final callback?) {
            callback(item, action);
          }
        },
        itemBuilder: (context) => [
          if (onOpen != null && allowedActions.contains(PlanAction.viewDetails))
            const PopupMenuItem(
              value: PlanAction.viewDetails,
              child: Text('View full details'),
            ),
          if (item.kind == PlanItemKind.jobStop &&
              onAction != null &&
              allowedActions.contains(PlanAction.markArrived))
            const PopupMenuItem(
              value: PlanAction.markArrived,
              child: Text('Mark arrived'),
            ),
          if (onAction != null &&
              allowedActions.contains(PlanAction.reschedule))
            const PopupMenuItem(
              value: PlanAction.reschedule,
              child: Text('Reschedule'),
            ),
          if (onAction != null &&
              allowedActions.contains(PlanAction.markComplete))
            PopupMenuItem(
              value: PlanAction.markComplete,
              child: Text(
                item.kind == PlanItemKind.jobStop
                    ? 'Mark completed'
                    : 'Mark task completed',
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusLabel(BuildContext context) => Text(
    item.status,
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );

  void _openDetails() => onOpen?.call(item);
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Nothing is scheduled for this day.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
