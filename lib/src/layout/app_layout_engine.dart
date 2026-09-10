import 'dart:math' as math;

import 'package:flutter/widgets.dart';

part 'dashboard_layout_calculator.dart';
part 'work_landing_layout_calculator.dart';

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

/// The single responsive contract for every Maintainiac screen.
///
/// Inputs are post-navigation logical constraints plus the platform text
/// scaler. There are deliberately no device, orientation, platform, or
/// physical-pixel branches here.
abstract final class AppLayoutEngine {
  static const railWidth = 220.0;
  static const railMinimumWindowWidth = 1338.0;
  static const dashboardRailMinimumWindowWidth = 1000.0;
  static const gap = 18.0;
  static const maximumGap = 48.0;

  /// Dashboard lanes deliberately stay compact. The first transition leaves
  /// enough room for two useful 350-LP records after the shell page insets;
  /// the third lane appears only when all three lanes can reach 400 LP.
  static const dashboardTwoColumnMinimumWidth = 748.0;
  static const dashboardThreeColumnMinimumWidth = 1248.0;
  static const dashboardLaneMaximum = 400.0;
  static const dashboardGap = 24.0;
  static const summaryStripCardMinimumHeight = 120.0;
  static double summaryStripCardWidthFor(
    TextScaler scaler, {
    double valueWidth = 0,
  }) => math.max(96 * math.max(1, scaler.scale(14) / 14), valueWidth + 20);

  /// Three true desktop lanes may grow to 600 LP each. One- and two-lane
  /// layouts remain compact instead of becoming enlarged phone canvases.
  static const maximumOperationsWorkspaceWidth = 1896.0;

  static const singleMaximum = 400.0;
  static const twoMinimum = 350.0;
  static const threeMinimum = 350.0;
  static const compactLaneMaximum = 400.0;
  static const laneMaximum = 600.0;
  static const maximumFormWorkspaceWidth = 760.0;

  static const _controlExtent = 42.0;
  static const _headerGap = 8.0;
  static const _vehicleMinimum = 176.0;
  static const _vehicleMaximum = 240.0;

  static AppNavigationMode navigationFor(
    Size window, {
    bool dashboard = false,
    bool work = false,
  }) =>
      window.width >=
              (dashboard || work
                  ? dashboardRailMinimumWindowWidth
                  : railMinimumWindowWidth) &&
          (work || window.height >= 600)
      ? AppNavigationMode.rail
      : AppNavigationMode.bottom;

  static EdgeInsets pageInsetsFor(double width) {
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 8);
    if (width < 700) return const EdgeInsets.symmetric(horizontal: 12);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static AppTypography typographyFor(double width) {
    final t = ((width - 320) / 680).clamp(0.0, 1.0);
    return AppTypography(
      control: 12.5 + .5 * t,
      pageTitle: 18 + 3 * t,
      sectionTitle: 15 + 1.5 * t,
      rowTitle: 13 + t,
      operationRowHeight: 56 + 4 * t,
      bottomNavigationHeight: 62 + 4 * t,
    );
  }

  /// One shared reflow rule for ordinary two-field form rows.
  ///
  /// The caller supplies the local post-padding width. Text scaling raises the
  /// required width so fields stack before labels or values become crowded.
  static bool stackFormFieldsFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    const minimumFieldWidth = 250.0;
    const fieldGap = 12.0;
    final scaleAllowance = _layoutScalePenalty(textScaler) * 100;
    return availableWidth < minimumFieldWidth * 2 + fieldGap + scaleAllowance;
  }

  /// Bounded width for one cohesive data-entry form.
  ///
  /// Forms may use two internal field columns, but never stretch into a wide
  /// desktop document. The input is the local width after page insets.
  static double formWorkspaceWidthFor(double availableWidth) =>
      math.min(maximumFormWorkspaceWidth, math.max(0, availableWidth));

  /// Shared one/two/four-column rule for compact operational summary metrics.
  static int summaryMetricColumnsFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final scalePenalty = _layoutScalePenalty(textScaler);
    if (availableWidth >= 760 + scalePenalty * 200) return 4;
    if (availableWidth >= 268 + scalePenalty * 100) return 2;
    return 1;
  }

  /// One compact-row decision shared by plan and recorded-entry containers.
  static bool stackOperationalRecordFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final type = typographyFor(availableWidth);
    return availableWidth < 330 || textScaler.scale(type.rowTitle) > 18;
  }

  static DashboardLayout dashboardFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final operations = dashboardOperationsFor(
      availableWidth,
      textScaler: textScaler,
    );
    return DashboardLayout(
      mode: switch (operations.columns) {
        1 => DashboardLaneMode.single,
        2 => DashboardLaneMode.two,
        _ => DashboardLaneMode.three,
      },
      laneWidth: operations.laneWidth,
      gap: operations.gap,
      workspaceWidth: operations.workspaceWidth,
    );
  }

  /// Dashboard-specific composition returned through the shared layout
  /// engine. This is intentionally not a breakpoint hidden in the screen.
  static OperationsWorkspaceLayout dashboardOperationsFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => _calculateDashboardOperationsLayout(
    availableWidth: availableWidth,
    scalePenalty: _layoutScalePenalty(textScaler),
  );

  static double dateActionGapFor(double availableWidth) {
    final t = ((availableWidth - 320) / 880).clamp(0.0, 1.0);
    return 8 + 10 * t;
  }

  /// Shared owner-header reflow. Height remains content-driven; large text
  /// moves the reading below its context rather than clipping either value.
  static bool stackOwnerHeaderContextFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => availableWidth < 270 + _layoutScalePenalty(textScaler) * 180;

  static DetailWorkspaceLayout detailWorkspaceFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final safeWidth = math.max(0.0, availableWidth);
    final scalePenalty = _layoutScalePenalty(textScaler) * 120;
    final gap = (18 + ((safeWidth - 900) / 900).clamp(0.0, 1.0) * 14)
        .toDouble();
    const columnMaximum = 620.0;
    final twoRequired = 420 * 2 + gap + scalePenalty;
    if (safeWidth >= twoRequired) {
      final column = math.min(columnMaximum, (safeWidth - gap) / 2);
      return DetailWorkspaceLayout(
        columns: 2,
        columnWidth: column,
        gap: gap,
        workspaceWidth: column * 2 + gap,
      );
    }
    final column = math.min(columnMaximum, safeWidth);
    return DetailWorkspaceLayout(
      columns: 1,
      columnWidth: column,
      gap: gap,
      workspaceWidth: column,
    );
  }

  static OperationsWorkspaceLayout operationsFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final safeWidth = math.max(0.0, availableWidth);
    final scalePenalty = _layoutScalePenalty(textScaler);
    final threeRequired = threeMinimum * 3 + gap * 2 + scalePenalty * 120;
    final twoRequired = twoMinimum * 2 + gap + scalePenalty * 80;
    final boundedWidth = math.min(safeWidth, maximumOperationsWorkspaceWidth);
    if (safeWidth >= threeRequired) {
      final responsiveGap = _laneGapFor(boundedWidth, 3);
      final lane = math.min(
        laneMaximum,
        (boundedWidth - responsiveGap * 2) / 3,
      );
      return OperationsWorkspaceLayout(
        columns: 3,
        laneWidth: lane,
        gap: responsiveGap,
        workspaceWidth: lane * 3 + responsiveGap * 2,
      );
    }
    if (safeWidth >= twoRequired) {
      final responsiveGap = _laneGapFor(boundedWidth, 2);
      final lane = math.min(
        compactLaneMaximum,
        (boundedWidth - responsiveGap) / 2,
      );
      return OperationsWorkspaceLayout(
        columns: 2,
        laneWidth: lane,
        gap: responsiveGap,
        workspaceWidth: lane * 2 + responsiveGap,
      );
    }
    final lane = math.min(singleMaximum, boundedWidth);
    return OperationsWorkspaceLayout(
      columns: 1,
      laneWidth: lane,
      gap: gap,
      workspaceWidth: lane,
    );
  }

  /// Compatibility entry point for existing Work detail and report screens.
  /// Top-level Dashboard, Work, and Expenses call [operationsFor] directly.
  static OperationsWorkspaceLayout workFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => operationsFor(availableWidth, textScaler: textScaler);

  /// Month rows stay compact as the calendar widens. Width is deliberately
  /// absent: desktop gets more horizontal room, not taller calendar cells.
  static double monthCalendarRowHeightFor(TextScaler textScaler) {
    final scalePenalty = _layoutScalePenalty(textScaler);
    return 70 + scalePenalty * 20;
  }

  static double calendarDateNumberExtentFor(TextScaler textScaler) =>
      math.max(24, textScaler.scale(11) + 8);

  static WorkShortcutLayout workShortcutsFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
    double? minimumLabelWidth,
  }) => _calculateWorkShortcuts(availableWidth, textScaler, minimumLabelWidth);

  /// Work home groups dated records beside a readable calendar, never three
  /// unrelated slices of a phone stack. Other module layouts are unchanged.
  static OperationsWorkspaceLayout workLandingFor(
    double availableWidth, {
    TextScaler textScaler = TextScaler.noScaling,
  }) => _calculateWorkLanding(availableWidth, textScaler);

  static HeaderLayout headerFor({
    required double availableWidth,
    required TextScaler textScaler,
    bool hasStartAction = true,
  }) {
    final type = typographyFor(availableWidth);
    final scaledControl = textScaler.scale(type.control);
    final padding = availableWidth < 420 ? 8.0 : 12.0;

    // The split-label minimums preserve every word on a 320-LP phone without
    // forcing the two action controls onto separate rows at normal text scale.
    final startMinimum = math.max(
      124,
      _textWidth('workday', 11, textScaler) + 50,
    );
    final viewMinimum = math.max(
      152,
      _textWidth('Technician', 10, textScaler) + 50,
    );
    final startIdeal = math.max(
      startMinimum,
      _textWidth('Start workday', 13, textScaler) + 50,
    );
    final viewIdeal = math.max(
      viewMinimum,
      _textWidth('View: Technician', 13, textScaler) + 50,
    );

    final minimumActions = hasStartAction
        ? startMinimum + _headerGap + viewMinimum
        : viewMinimum;
    final actionsSideBySide =
        !hasStartAction || availableWidth - padding * 2 >= minimumActions;
    final minimumWideWidth =
        padding * 2 +
        _controlExtent * 2 +
        _headerGap * (hasStartAction ? 4 : 3) +
        (hasStartAction ? startMinimum : 0) +
        viewMinimum +
        _vehicleMinimum;
    final singleRow = availableWidth >= minimumWideWidth;

    var distributable = singleRow
        ? math.max(0, availableWidth - minimumWideWidth)
        : math.max(0, availableWidth - padding * 2 - minimumActions);
    final viewGrowth = math.min(
      math.max(0, viewIdeal - viewMinimum),
      distributable,
    );
    final viewWidth = (viewMinimum + viewGrowth).toDouble();
    distributable -= viewGrowth;
    final startGrowth = math.min(
      math.max(0, startIdeal - startMinimum),
      distributable,
    );
    final startWidth = (startMinimum + startGrowth).toDouble();
    distributable -= startGrowth;

    final compactVehicle =
        availableWidth - padding * 2 - _controlExtent * 2 - _headerGap * 2;
    final vehicleWidth = math
        .min(
          _vehicleMaximum,
          math.max(
            singleRow ? _vehicleMinimum : 0,
            singleRow ? _vehicleMinimum + distributable : compactVehicle,
          ),
        )
        .toDouble();

    return HeaderLayout(
      singleRow: singleRow,
      actionsSideBySide: actionsSideBySide,
      padding: padding,
      startWidth: startWidth,
      viewWidth: viewWidth,
      vehicleWidth: vehicleWidth,
      controlHeight: _headerContextHeight(textScaler),
      actionHeight: math.max(44, scaledControl * 1.3 + 18),
      stackStartLabel: startWidth + .1 < startIdeal,
      stackViewLabel: viewWidth + .1 < viewIdeal,
    );
  }

  static double _textWidth(String label, double fontSize, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static double _headerContextHeight(TextScaler scaler) {
    final ratio = scaler.scale(12) / 12;
    if (ratio <= 1.2) return 42;
    return scaler.scale(35) + 18;
  }

  static double _layoutScalePenalty(TextScaler scaler) {
    final ratio = scaler.scale(14) / 14;
    return (ratio - 1).clamp(0.0, 1.0);
  }

  static double _laneGapFor(double availableWidth, int columns) {
    final minimumWidth = switch (columns) {
      3 => threeMinimum * 3 + gap * 2,
      2 => twoMinimum * 2 + gap,
      _ => availableWidth,
    };
    final surplus = math.max(0, availableWidth - minimumWidth);
    return (gap + surplus * .12).clamp(gap, maximumGap);
  }
}
