part of 'app_layout_engine.dart';

/// Retains the existing equal-lane Start Workday form contract. Its sections
/// must not consume Dashboard's new asymmetric record/calendar geometry.
OperationsWorkspaceLayout _calculateStartWorkdayLayout({
  required double availableWidth,
  required double scalePenalty,
}) {
  final width = math.max(0.0, availableWidth);
  final columns = width >= 1248 + scalePenalty * 180
      ? 3
      : width >= 748 + scalePenalty * 100
      ? 2
      : 1;
  final lane = math.min(400.0, (width - (columns - 1) * 24) / columns);
  return OperationsWorkspaceLayout(
    columns: columns,
    laneWidth: lane,
    gap: 24,
    workspaceWidth: lane * columns + (columns - 1) * 24,
  );
}

/// Dashboard records get more reading room than their supporting calendar.
class DashboardWorkspaceLayout extends OperationsWorkspaceLayout {
  const DashboardWorkspaceLayout({
    required super.columns,
    required super.laneWidth,
    required super.gap,
    required super.workspaceWidth,
    required this.calendarWidth,
  });
  final double calendarWidth;
}

DashboardWorkspaceLayout _calculateDashboardOperationsLayout({
  required double availableWidth,
  required double scalePenalty,
  required bool hasEntries,
}) {
  final safeWidth = math.max(0.0, availableWidth);
  final threeRequired =
      AppLayoutEngine.dashboardThreeColumnMinimumWidth + scalePenalty * 240;
  final twoRequired =
      AppLayoutEngine.dashboardTwoColumnMinimumWidth + scalePenalty * 160;

  if (safeWidth >= threeRequired && hasEntries) {
    final workspace = math.min(safeWidth, 1432.0);
    final calendar = math.min(400.0, (workspace - 32) * .29);
    return DashboardWorkspaceLayout(
      columns: 3,
      laneWidth: (workspace - calendar - 32) / 2,
      calendarWidth: calendar,
      gap: AppLayoutEngine.dashboardGap,
      workspaceWidth: workspace,
    );
  }
  if (safeWidth >= twoRequired) {
    final workspace = math.min(safeWidth, 1016.0);
    final calendar = math.min(400.0, (workspace - 16) * .43);
    return DashboardWorkspaceLayout(
      columns: 2,
      laneWidth: workspace - calendar - 16,
      calendarWidth: calendar,
      gap: AppLayoutEngine.dashboardGap,
      workspaceWidth: workspace,
    );
  }
  final lane = math.min(AppLayoutEngine.dashboardLaneMaximum, safeWidth);
  return DashboardWorkspaceLayout(
    columns: 1,
    laneWidth: lane,
    calendarWidth: lane,
    gap: 24,
    workspaceWidth: lane,
  );
}
