part of 'app_layout_engine.dart';

OperationsWorkspaceLayout _calculateWorkLanding(
  double availableWidth,
  TextScaler scaler,
) {
  final width = math.max(0.0, availableWidth);
  const gap = 24.0;
  final penalty = AppLayoutEngine._layoutScalePenalty(scaler);
  final primaryMinimum = 520 + penalty * 160;
  final supportingMinimum = 340 + penalty * 100;
  final columns = width >= primaryMinimum + supportingMinimum + gap ? 2 : 1;
  final supporting = columns == 2
      ? math.min(400.0, math.max(supportingMinimum, width * .32))
      : null;
  final lane = columns == 2
      ? math.min(760.0, width - supporting! - gap)
      : math.min(760.0, width);
  return OperationsWorkspaceLayout(
    columns: columns,
    laneWidth: lane,
    gap: gap,
    supportingLaneWidth: supporting,
    workspaceWidth: lane + (supporting == null ? 0 : supporting + gap),
  );
}

WorkShortcutLayout _calculateWorkShortcuts(
  double availableWidth,
  TextScaler scaler,
  double? minimumLabelWidth,
) {
  final width = math.max(0.0, availableWidth);
  const gap = 8.0;
  if (minimumLabelWidth == null) {
    // Existing action directories retain their accepted arrangement.
    final scalePenalty = AppLayoutEngine._layoutScalePenalty(scaler);
    final columns = scalePenalty > .35
        ? (width >= 420 ? 3 : 2)
        : width >= 660
        ? 6
        : width >= 276
        ? 3
        : 2;
    return WorkShortcutLayout(
      columns: columns,
      tileWidth: math.max(
        0,
        math.min(110, (width - gap * (columns - 1)) / columns),
      ),
      iconExtent: 62,
      gap: gap,
    );
  }
  final minimum = math.max(72.0, minimumLabelWidth);
  final fitting = ((width + gap) / (minimum + gap)).floor().clamp(1, 6);
  // Six destinations form a single wide row or a four-plus-two phone grid.
  final columns = fitting == 5 ? 4 : fitting;
  final tile = math.min(
    math.max(110.0, minimumLabelWidth),
    math.max(0.0, (width - gap * (columns - 1)) / columns),
  );
  return WorkShortcutLayout(
    columns: columns,
    tileWidth: tile,
    iconExtent: math.min(62, tile),
    gap: gap,
  );
}
