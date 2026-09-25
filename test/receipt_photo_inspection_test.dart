import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_photo_preview.dart';

void main() {
  for (final width in [320.0, 1400.0]) {
    testWidgets('photo inspection zoom, fit and return at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ReceiptPhotoPreview(
                path: 'missing-test-photo.jpg',
                name: 'Test receipt',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      await tester.tap(find.text('Zoom in'));
      await tester.pump();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1.5);
      await tester.tap(find.text('Fit receipt'));
      await tester.pump();
      expect(viewer.transformationController!.value, Matrix4.identity());
      await tester.tap(find.text('Full screen'));
      await tester.pumpAndSettle();
      expect(find.text('Back to receipt'), findsOneWidget);
      expect(
        tester.getSize(find.byType(InteractiveViewer)).height,
        greaterThan(600),
      );
      await tester.tap(find.text('Back to receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Full screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
