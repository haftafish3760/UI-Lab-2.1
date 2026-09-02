import 'package:flutter/widgets.dart';

import 'app_layout_engine.dart';

/// Compatibility names for older prototype code.
///
/// New screens must consume [AppLayoutEngine] directly so the application does
/// not grow a second set of breakpoint rules.
@Deprecated('Use AppLayoutEngine and local LayoutBuilder constraints.')
enum AppLayoutClass { phone, tablet, desktop }

@Deprecated('Use DashboardLayout from AppLayoutEngine.')
typedef DashboardLayoutSpec = DashboardLayout;

@Deprecated('Use AppLayoutEngine. These values only forward shared tokens.')
abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const desktop = AppLayoutEngine.railMinimumWindowWidth;
  static const dashboardTwoPane =
      AppLayoutEngine.twoMinimum * 2 + AppLayoutEngine.gap;
  static const dashboardThreePane =
      AppLayoutEngine.threeMinimum * 3 + AppLayoutEngine.gap * 2;
  static const dashboardGap = AppLayoutEngine.gap;
  static const dashboardContentMaxWidth =
      AppLayoutEngine.laneMaximum * 3 + AppLayoutEngine.maximumGap * 2;

  static AppLayoutClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return AppLayoutClass.desktop;
    if (width >= tablet) return AppLayoutClass.tablet;
    return AppLayoutClass.phone;
  }
}
