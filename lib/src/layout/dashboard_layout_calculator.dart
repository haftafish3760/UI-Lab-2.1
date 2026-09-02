part of 'app_layout_engine.dart';

/// Calculates Dashboard geometry from local post-navigation constraints.
///
/// Dashboard has a stricter 400-LP lane maximum and a later third-lane
/// threshold than record-heavy module workspaces.
OperationsWorkspaceLayout _calculateDashboardOperationsLayout({
  required double availableWidth,
  required double scalePenalty,
}) {
  final safeWidth = math.max(0.0, availableWidth);
  final threeRequired =
      AppLayoutEngine.dashboardThreeColumnMinimumWidth + scalePenalty * 180;
  final twoRequired =
      AppLayoutEngine.dashboardTwoColumnMinimumWidth + scalePenalty * 100;

  if (safeWidth >= threeRequired) {
    return const OperationsWorkspaceLayout(
      columns: 3,
      laneWidth: AppLayoutEngine.dashboardLaneMaximum,
      gap: AppLayoutEngine.dashboardGap,
      workspaceWidth: AppLayoutEngine.dashboardThreeColumnMinimumWidth,
    );
  }
  if (safeWidth >= twoRequired) {
    final lane = math.min(
      AppLayoutEngine.dashboardLaneMaximum,
      (safeWidth - AppLayoutEngine.dashboardGap) / 2,
    );
    return OperationsWorkspaceLayout(
      columns: 2,
      laneWidth: lane,
      gap: AppLayoutEngine.dashboardGap,
      workspaceWidth: lane * 2 + AppLayoutEngine.dashboardGap,
    );
  }
  final lane = math.min(AppLayoutEngine.dashboardLaneMaximum, safeWidth);
  return OperationsWorkspaceLayout(
    columns: 1,
    laneWidth: lane,
    gap: AppLayoutEngine.dashboardGap,
    workspaceWidth: lane,
  );
}
