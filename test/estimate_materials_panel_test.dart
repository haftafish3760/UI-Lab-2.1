import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_materials_panel.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('long materials list scrolls independently at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EstimateMaterialsPanel(
                items: List.generate(
                  50,
                  (i) => WorkLineItem(
                    id: '$i',
                    type: WorkLineItemType.material,
                    name: 'Material $i',
                    quantity: 2,
                    unit: 'each',
                    customerPrice: 10,
                  ),
                ),
                onEdit: () => opened = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final list = find.byKey(const ValueKey('estimate-materials-scroll'));
      expect(tester.getSize(list).height, lessThanOrEqualTo(size.height * .5));
      final before = tester.getTopLeft(
        find.byKey(const ValueKey('estimate-materials-subtotal')),
      );
      await tester.drag(list, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(
          find.byKey(const ValueKey('estimate-materials-subtotal')),
        ),
        before,
      );
      await tester.tap(find.byKey(const ValueKey('estimate-materials-edit')));
      expect(opened, isTrue);
      expect(find.text('\$1000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
