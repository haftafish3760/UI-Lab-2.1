part of 'app_layout_engine.dart';

WorkShortcutLayout _calculateMaterialsCatalog(
  double availableWidth,
  TextScaler scaler,
  double longestWordWidth,
) {
  final width = math.max(0.0, availableWidth);
  const gap = 8.0;
  final minimum = math.max(
    104.0 * math.max(1.0, scaler.scale(13) / 13),
    longestWordWidth + 26,
  );
  final columns = ((width + gap) / (minimum + gap)).floor().clamp(1, 6);
  return WorkShortcutLayout(
    columns: columns,
    tileWidth: math.min(
      math.max(240, minimum),
      math.max(0, (width - gap * (columns - 1)) / columns),
    ),
    iconExtent: 0,
    gap: gap,
  );
}
