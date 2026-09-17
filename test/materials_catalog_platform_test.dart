import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/materials_catalog_route.dart';
import 'inventory_screen_test.dart' as harness;

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('catalog back navigation on $platform', (tester) async {
      await harness.pump(
        tester,
        InventoryCatalogScreen(catalog: harness.fixture),
        platform: platform,
      );
      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();
      expect(find.text('Fittings'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      if (platform == TargetPlatform.iOS) {
        await tester.dragFrom(const Offset(1, 250), const Offset(330, 0));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text('Choose a trade'), findsOneWidget);
    });
  }
  testWidgets('Spanish navigation and reduced motion follow shared settings', (
    tester,
  ) async {
    await harness.pump(
      tester,
      InventoryCatalogScreen(catalog: harness.fixture),
      locale: const Locale('es', 'US'),
      reducedMotion: true,
    );
    expect(find.text('Plomería'), findsOneWidget);
    await tester.tap(find.text('Plomería'));
    await tester.pumpAndSettle();
    expect(find.text('Conexiones'), findsOneWidget);
    final context = tester.element(find.text('Conexiones'));
    final route = ModalRoute.of(context)! as MaterialsCatalogRoute<void>;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Plomería'), findsOneWidget);
  });
}
