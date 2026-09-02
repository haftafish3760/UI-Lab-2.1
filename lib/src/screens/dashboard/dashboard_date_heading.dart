import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../layout/app_layout_engine.dart';
import 'dashboard_models.dart';

class DashboardDateHeading extends StatelessWidget {
  const DashboardDateHeading({
    required this.type,
    required this.date,
    required this.onReturnToToday,
    super.key,
  });

  final AppTypography type;
  final DateTime date;
  final VoidCallback onReturnToToday;

  @override
  Widget build(BuildContext context) {
    final isToday = sameDashboardDay(date, dashboardToday);
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppLayoutEngine.dateActionGapFor(constraints.maxWidth);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isToday) ...[
              IconButton(
                key: const ValueKey('return-to-today-button'),
                onPressed: onReturnToToday,
                tooltip: context.l10n.operationalReturnToToday,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              SizedBox(width: gap),
            ],
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                dateLabel,
                key: const ValueKey('dashboard-date-heading'),
                style: TextStyle(
                  fontSize: type.pageTitle,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
