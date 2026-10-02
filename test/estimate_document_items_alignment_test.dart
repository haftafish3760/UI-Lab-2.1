import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_document_items.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_price_summary.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';

void main() {
  for (final width in [320.0, 800.0]) {
    testWidgets('estimate amounts share an end edge at $width LP', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const EstimateDocumentItems(
                    items: [
                      WorkLineItem(
                        id: 'a',
                        type: WorkLineItemType.material,
                        name: 'Replacement component',
                        quantity: 2,
                        unit: 'each',
                        customerPrice: 12.50,
                      ),
                      WorkLineItem(
                        id: 'b',
                        type: WorkLineItemType.service,
                        name: 'Installation',
                        quantity: 1,
                        unit: 'service',
                        customerPrice: 150.75,
                      ),
                    ],
                  ),
                  EstimatePriceSummary(
                    subtotal: '\$175.75',
                    discount: '\$5.00',
                    tax: '\$10.00',
                    total: '\$180.75',
                    onEdit: () {},
                    grouped: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester.getBottomRight(find.text('\$25.00')).dx;
      final second = tester.getBottomRight(find.text('\$150.75').last).dx;
      expect(first, closeTo(second, 0.1));
      final subtotal = tester.getBottomRight(find.text('\$175.75')).dx;
      expect(
        tester.getBottomRight(find.text('\$5.00')).dx,
        closeTo(subtotal, 0.1),
      );
      expect(
        tester.getBottomRight(find.text('\$180.75')).dx,
        closeTo(subtotal, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
