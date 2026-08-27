import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';
import 'dashboard_models.dart';
import 'plan_stop_details_screen.dart';

class TodayPlan extends StatelessWidget {
  const TodayPlan({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's Plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 19,
                      fontWeight: compact ? FontWeight.w700 : FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Show all'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '3 scheduled stops',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                for (var i = 0; i < demoPlan.length; i++) ...[
                  _PlanRow(item: demoPlan[i]),
                  if (i != demoPlan.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item});

  final PlanItem item;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(10),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFFBCD4CD);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return const Color(0xFFD2E2DD);
          }
          return null;
        }),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8F7),
            border: Border.all(color: AppColors.border, width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 74,
                    child: Text(
                      item.time,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(item.icon, color: item.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: PopupMenuButton<_PlanAction>(
                      tooltip: 'Stop actions',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == _PlanAction.viewDetails) {
                          _openDetails(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _PlanAction.viewDetails,
                          child: Text('View full details'),
                        ),
                        PopupMenuItem(
                          value: _PlanAction.reschedule,
                          child: Text('Reschedule'),
                        ),
                        PopupMenuItem(
                          value: _PlanAction.markComplete,
                          child: Text('Mark completed'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlanStopDetailsScreen(item: item),
      ),
    );
  }
}

enum _PlanAction { viewDetails, reschedule, markComplete }
