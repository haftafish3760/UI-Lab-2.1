part of 'app_layout_engine.dart';

enum AppNavigationMode { bottom, rail }

enum DashboardLaneMode { single, two, three }

@immutable
class AppTypography {
  const AppTypography({
    required this.control,
    required this.pageTitle,
    required this.sectionTitle,
    required this.rowTitle,
    required this.operationRowHeight,
    required this.bottomNavigationHeight,
  });

  final double control;
  final double pageTitle;
  final double sectionTitle;
  final double rowTitle;
  final double operationRowHeight;
  final double bottomNavigationHeight;
}

@immutable
class DashboardLayout {
  const DashboardLayout({
    required this.mode,
    required this.laneWidth,
    required this.gap,
    required this.workspaceWidth,
  });

  final DashboardLaneMode mode;
  final double laneWidth;
  final double gap;
  final double workspaceWidth;
}

@immutable
class HeaderLayout {
  const HeaderLayout({
    required this.singleRow,
    required this.actionsSideBySide,
    required this.padding,
    required this.startWidth,
    required this.viewWidth,
    required this.vehicleWidth,
    required this.controlHeight,
    required this.actionHeight,
    required this.stackStartLabel,
    required this.stackViewLabel,
  });

  final bool singleRow;
  final bool actionsSideBySide;
  final double padding;
  final double startWidth;
  final double viewWidth;
  final double vehicleWidth;
  final double controlHeight;
  final double actionHeight;
  final bool stackStartLabel;
  final bool stackViewLabel;
}

@immutable
class DetailWorkspaceLayout {
  const DetailWorkspaceLayout({
    required this.columns,
    required this.columnWidth,
    required this.gap,
    required this.workspaceWidth,
  });

  final int columns;
  final double columnWidth;
  final double gap;
  final double workspaceWidth;
}

@immutable
class OperationsWorkspaceLayout {
  const OperationsWorkspaceLayout({
    required this.columns,
    required this.laneWidth,
    required this.gap,
    required this.workspaceWidth,
  });

  final int columns;
  final double laneWidth;
  final double gap;
  final double workspaceWidth;

  /// Shared compact-FAB versus inline-action presentation for module homes.
  ///
  /// The decision follows the same local lane result as the content it acts
  /// on, so a large surrounding window cannot hide a compact action inside a
  /// narrow pane.
  bool get showsInlineModuleActions => columns >= 2;
}

@immutable
class WorkShortcutLayout {
  const WorkShortcutLayout({
    required this.columns,
    required this.tileWidth,
    required this.iconExtent,
    required this.gap,
  });

  final int columns;
  final double tileWidth;
  final double iconExtent;
  final double gap;
}
