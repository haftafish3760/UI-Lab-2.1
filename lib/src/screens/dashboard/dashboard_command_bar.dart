part of 'dashboard_screen.dart';

/// Wide-screen command row: date and the existing context-appropriate actions.
/// Uses Wrap so translated and accessibility labels keep their complete text.
class _DashboardCommandBar extends StatelessWidget {
  const _DashboardCommandBar({required this.body, required this.layout});
  final _DashboardBody body;
  final DashboardWorkspaceLayout layout;

  @override
  Widget build(BuildContext context) => Wrap(
    key: const ValueKey('dashboard-command-bar'),
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: WrapAlignment.spaceBetween,
    children: [
      SizedBox(
        width: layout.laneWidth,
        child: DashboardDateHeading(
          type: AppLayoutEngine.typographyFor(layout.workspaceWidth),
          date: body.selectedDate,
          onReturnToToday: body.onReturnToToday,
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (body.view == AppViewMode.technician &&
              body.workday == null &&
              sameDashboardDay(body.selectedDate, dashboardToday))
            FilledButton.icon(
              key: const ValueKey('start-workday-button'),
              onPressed: body.onStartWorkday,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(context.l10n.dashboardStartWorkday),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.startWorkday,
                foregroundColor: AppColors.ink,
                minimumSize: const Size(0, 48),
              ),
            ),
          if (body.onOpenActions != null)
            FilledButton.icon(
              key: const ValueKey('dashboard-inline-actions'),
              onPressed: body.onOpenActions,
              icon: Icon(
                body.workday == null ? Icons.add : Icons.grid_view_rounded,
              ),
              label: Text(body.workday == null ? 'Add' : 'Workday actions'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          if (body.workday != null)
            OutlinedButton.icon(
              key: const ValueKey('dashboard-end-workday'),
              onPressed: body.onEndWorkday,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End workday'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
        ],
      ),
    ],
  );
}
