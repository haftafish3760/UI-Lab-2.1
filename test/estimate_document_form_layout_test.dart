import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'support/load_material_test_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'estimate_service_price_test.dart' as fixtures;
import 'estimate_review_flow_test.dart' show reviewTheme;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadMaterialTestFont();
    final root = Platform.environment['FLUTTER_ROOT']!;
    for (final (family, file) in [
      ('Ahem', 'Roboto-Regular.ttf'),
      ('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(
            File(
              '$root/bin/cache/artifacts/material_fonts/$file',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  for (final (width, scale) in [
    (320.0, 1.0),
    (360.0, 2.0),
    (430.0, 1.0),
    (1280.0, 1.0),
  ]) {
    testWidgets(
      'single estimate form reflows at $width and text scale $scale',
      (tester) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PrototypeOperationsStore(
          workRecords: [],
          financialEntries: [],
        );
        final scope = OperationalScopeController();
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
        final record = buildConfirmedEstimate(
          fixtures.priceInput('245.50'),
          now: DateTime(2026, 9, 29),
        );
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: reviewTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: const ValueKey('render-form'),
                  child: EstimateEditorScreen(
                    initialDay: DateTime(2026, 9, 29),
                    initialRecord: record,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Client information'), findsOneWidget);
        expect(find.text('Dates and validity'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('estimate-price-summary')),
            matching: find.byKey(const ValueKey('estimate-items')),
          ),
          findsOneWidget,
        );
        expect(find.text('Proposed service dates and times'), findsOneWidget);
        expect(find.byKey(const ValueKey('estimate-review')), findsNothing);
        expect(
          tester
              .widget<Scaffold>(find.byType(Scaffold).first)
              .bottomNavigationBar,
          isNull,
        );
        expect(tester.takeException(), isNull);
        Future<void> render(String section) async {
          if (width != 430 || scale != 1) return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('render-form')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/estimate-form-$section.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await render('top');
        await tester.ensureVisible(
          find.byKey(const ValueKey('estimate-price-summary')),
        );
        await tester.pumpAndSettle();
        await render('pricing');
        await tester.ensureVisible(
          find.byKey(const ValueKey('estimate-editor-actions')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await render('bottom');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
