import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/layout/dashboard_layout.dart';

void main() {
  test('Dashboard changes lanes at compact professional thresholds', () {
    expect(
      DashboardLayout.from(const Size(700, 900), TextScaler.noScaling).lanes,
      DashboardLaneCount.one,
    );
    expect(
      DashboardLayout.from(const Size(748, 900), TextScaler.noScaling).lanes,
      DashboardLaneCount.two,
    );
    expect(
      DashboardLayout.from(const Size(1180, 900), TextScaler.noScaling).lanes,
      DashboardLaneCount.three,
    );
  });

  test('13-inch-class logical window keeps three useful bounded lanes', () {
    final layout = DashboardLayout.from(
      const Size(1366, 768),
      TextScaler.noScaling,
    );

    expect(layout.useNavigationRail, isTrue);
    expect(layout.lanes, DashboardLaneCount.three);
    expect(layout.laneWidth, inInclusiveRange(340, 400));
    expect(layout.workspaceWidth, lessThanOrEqualTo(1228));
  });

  test('phone landscape uses two lanes without device-name branches', () {
    final layout = DashboardLayout.from(
      const Size(915, 412),
      TextScaler.noScaling,
    );

    expect(layout.useNavigationRail, isFalse);
    expect(layout.lanes, DashboardLaneCount.two);
    expect(layout.laneWidth, lessThanOrEqualTo(400));
  });

  test('text scaling collapses before lanes become crowded', () {
    final normal = DashboardLayout.from(
      const Size(1180, 900),
      TextScaler.noScaling,
    );
    final enlarged = DashboardLayout.from(
      const Size(1180, 900),
      const TextScaler.linear(2),
    );

    expect(normal.lanes, DashboardLaneCount.three);
    expect(enlarged.lanes, DashboardLaneCount.two);
  });
}
