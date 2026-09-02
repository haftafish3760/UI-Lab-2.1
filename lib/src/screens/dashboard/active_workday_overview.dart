import 'dart:async';

import 'package:flutter/material.dart';

import 'dashboard_workday_models.dart';

class ActiveWorkdayOverview extends StatefulWidget {
  const ActiveWorkdayOverview({required this.session, super.key});

  final DashboardWorkdaySession session;

  @override
  State<ActiveWorkdayOverview> createState() => _ActiveWorkdayOverviewState();
}

class _ActiveWorkdayOverviewState extends State<ActiveWorkdayOverview> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final status = session.status == DashboardWorkdayStatus.paused
        ? 'Paused'
        : 'Active';
    final statusColor = session.status == DashboardWorkdayStatus.paused
        ? const Color(0xFFA55B00)
        : const Color(0xFF087A4A);
    return Container(
      key: const ValueKey('active-workday-overview'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
              final metrics = [
                _WorkdayMetric(
                  label: 'Active time',
                  value: _durationLabel(session.elapsedAt(DateTime.now())),
                  icon: Icons.timer_outlined,
                ),
                _WorkdayMetric(
                  label: 'Miles today',
                  value: '${(session.milesTenths / 10).toStringAsFixed(1)} mi',
                  icon: Icons.route_outlined,
                  alignEnd: true,
                ),
              ];
              if (constraints.maxWidth < 340 || largeText) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metrics.first,
                    const SizedBox(height: 10),
                    metrics.last,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: metrics.first),
                  const SizedBox(height: 44, child: VerticalDivider(width: 28)),
                  Expanded(child: metrics.last),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next job · 8:00 AM',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkdayMetric extends StatelessWidget {
  const _WorkdayMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 2,
      children: [
        if (!alignEnd) Icon(icon, color: colors.primary, size: 20),
        Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        if (alignEnd) Icon(icon, color: colors.primary, size: 20),
      ],
    );
  }
}

String _durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
