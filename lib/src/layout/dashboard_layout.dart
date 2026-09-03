import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum DashboardLaneCount { one, two, three }

@immutable
class DashboardLayout {
  const DashboardLayout({
    required this.lanes,
    required this.laneWidth,
    required this.workspaceWidth,
    required this.gap,
    required this.pageInsets,
    required this.useNavigationRail,
  });

  static const double laneMaximum = 400;
  static const double laneMinimum = 340;
  static const double gapValue = 14;
  static const double railWidth = 184;
  static const double railWindowThreshold = 1280;
  static const double twoLaneThreshold = 694;
  static const double threeLaneThreshold = 1048;

  final DashboardLaneCount lanes;
  final double laneWidth;
  final double workspaceWidth;
  final double gap;
  final EdgeInsets pageInsets;
  final bool useNavigationRail;

  int get columnCount => switch (lanes) {
    DashboardLaneCount.one => 1,
    DashboardLaneCount.two => 2,
    DashboardLaneCount.three => 3,
  };

  static DashboardLayout from(Size window, TextScaler textScaler) {
    final insets = _pageInsets(window.width);
    final rail = window.width >= railWindowThreshold && window.height >= 600;
    final localWidth = math.max(
      0,
      window.width - insets.horizontal - (rail ? railWidth : 0),
    );
    final scale = textScaler.scale(1).clamp(1.0, 2.0).toDouble();
    final threeRequired = threeLaneThreshold + (scale - 1) * 180;
    final twoRequired = twoLaneThreshold + (scale - 1) * 100;
    final columns = localWidth >= threeRequired
        ? 3
        : localWidth >= twoRequired
        ? 2
        : 1;
    final lane = math
        .min(
          laneMaximum,
          math.max(0.0, (localWidth - gapValue * (columns - 1)) / columns),
        )
        .toDouble();
    return DashboardLayout(
      lanes: switch (columns) {
        1 => DashboardLaneCount.one,
        2 => DashboardLaneCount.two,
        _ => DashboardLaneCount.three,
      },
      laneWidth: lane,
      workspaceWidth: lane * columns + gapValue * (columns - 1),
      gap: gapValue,
      pageInsets: insets,
      useNavigationRail: rail,
    );
  }

  static EdgeInsets _pageInsets(double width) {
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 10);
    if (width < 700) return const EdgeInsets.symmetric(horizontal: 12);
    return const EdgeInsets.symmetric(horizontal: 16);
  }
}
