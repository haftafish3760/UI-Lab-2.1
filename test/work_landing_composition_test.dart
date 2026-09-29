import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/shared/operations_workspace.dart';

void main() {
  test(
    'Work gives records more space while bounding the supporting calendar',
    () {
      final wide = AppLayoutEngine.workLandingFor(1800);
      expect(wide.columns, 2);
      expect(wide.laneWidth, 760);
      expect(wide.supportingLaneWidth, 400);
      expect(wide.workspaceWidth, 1184);
      expect(AppLayoutEngine.workLandingFor(800).columns, 1);
    },
  );

  test('width and text scaling never overrun local constraints', () {
    for (final width in [0.0, 320.0, 600.0, 883.0, 884.0, 1100.0, 1800.0]) {
      for (final scale in [1.0, 1.5, 2.0, 3.0]) {
        final layout = AppLayoutEngine.workLandingFor(
          width,
          textScaler: TextScaler.linear(scale),
        );
        expect(layout.workspaceWidth, lessThanOrEqualTo(width));
        expect(layout.laneWidth, greaterThanOrEqualTo(0));
        if (layout.columns == 2) {
          expect(layout.supportingLaneWidth, lessThanOrEqualTo(400));
          expect(layout.laneWidth, greaterThan(layout.supportingLaneWidth!));
        }
      }
    }
    expect(
      AppLayoutEngine.workLandingFor(
        1000,
        textScaler: const TextScaler.linear(2),
      ).columns,
      1,
    );
  });

  testWidgets('shared lane assembly honors primary/supporting widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OperationsWorkspaceFrame(
            layout: AppLayoutEngine.workLandingFor(1300),
            primaryContent: OperationsLaneGrid(
              layout: AppLayoutEngine.workLandingFor(1300),
              children: const [
                SizedBox(key: ValueKey('primary'), height: 100),
                SizedBox(key: ValueKey('calendar'), height: 100),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('primary'))).width, 760);
    expect(tester.getSize(find.byKey(const ValueKey('calendar'))).width, 400);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('calendar'))).dx -
          tester.getTopRight(find.byKey(const ValueKey('primary'))).dx,
      24,
    );
    expect(tester.takeException(), isNull);
  });

  test('other shared layouts retain equal lane widths unless opted in', () {
    for (final width in [800.0, 1400.0]) {
      final layout = AppLayoutEngine.operationsFor(width);
      for (var i = 0; i < layout.columns; i++) {
        expect(layout.widthForLane(i), layout.laneWidth);
      }
    }
  });
}
