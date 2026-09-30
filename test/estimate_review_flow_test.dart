import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'support/load_material_test_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/document_form_navigation.dart';

WorkRecord estimateFixture() => WorkRecord(
  id: 'review-fixture',
  kind: WorkRecordKind.estimate,
  number: 'Estimate 42',
  title: 'Replace kitchen faucet',
  client: 'Avery Wilson',
  detail:
      'Remove the leaking faucet, install the replacement, and test the connections for leaks.',
  pricing: WorkPricingModel.timeAndMaterials,
  createdOn: DateTime(2026, 9, 27, 10, 35),
  terms: 'Additional work requires customer approval.',
  total: 250,
  requiredDepositCents: 5000,
  items: const [
    WorkLineItem(
      id: 'labor',
      type: WorkLineItemType.labor,
      name: 'Faucet installation',
      description: 'Remove and replace the existing faucet.',
      quantity: 2,
      unit: 'hours',
      customerPrice: 75,
    ),
    WorkLineItem(
      id: 'material',
      type: WorkLineItemType.material,
      name: 'Kitchen faucet',
      quantity: 1,
      unit: 'each',
      customerPrice: 100,
    ),
  ],
);

ThemeData reviewTheme() {
  final theme = AppTheme.light;
  const text = WidgetStatePropertyAll(
    TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600),
  );
  return theme.copyWith(
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style!.copyWith(textStyle: text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style!.copyWith(textStyle: text),
    ),
    textButtonTheme: TextButtonThemeData(
      style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: text,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadMaterialTestFont();
    final root = Platform.environment['FLUTTER_ROOT']!;
    // Explicit button styles inherit the test fallback font. Render them with
    // the same readable Material font used by the rest of this capture.
    await (FontLoader('Ahem')..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });
  testWidgets(
    'single document shows edits before save and preserves them across terms editing',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PrototypeOperationsStore();
      final scope = OperationalScopeController();
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      final before = store.workRecords.map((r) => r.id).toList();
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: reviewTheme(),
              home: EstimateEditorScreen(
                initialDay: DateTime(2026, 9, 27),
                initialRecord: estimateFixture(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'estimate-information');
      await tester.enterText(
        find.byKey(const ValueKey('estimate-title')),
        'Updated faucet work',
      );
      await closeDocumentSection(tester);
      await openDocumentSection(tester, 'estimate-terms');
      final depositField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Required deposit amount',
      );
      await tester.enterText(depositField, '75.00');
      await closeDocumentSection(tester);
      expect(find.byKey(const ValueKey('estimate-review')), findsNothing);
      expect(find.text('Updated faucet work'), findsOneWidget);
      expect(find.textContaining('75.00'), findsWidgets);
      expect(store.workRecords.map((r) => r.id).toList(), before);
      await openDocumentSection(tester, 'estimate-information');
      final title = find.byKey(const ValueKey('estimate-title'));
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      await tester.enterText(title, 'Revised on the same form');
      await openDocumentSection(tester, 'estimate-terms');
      await tester.enterText(depositField, '60');
      await closeDocumentSection(tester);
      expect(find.textContaining('60.00'), findsWidgets);
      expect(find.text('Revised on the same form'), findsOneWidget);
      expect(store.workRecords.map((r) => r.id).toList(), before);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (width, scale, reviewing) in [
    (320.0, 1.0, false),
    (320.0, 1.0, true),
    (430.0, 1.0, false),
    (430.0, 1.0, true),
    (430.0, 2.0, false),
    (430.0, 2.0, true),
    (1280.0, 1.0, false),
    (1280.0, 1.0, true),
  ]) {
    testWidgets(
      'estimate review readable at $width with text scale $scale reviewing $reviewing',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PrototypeOperationsStore();
        final scope = OperationalScopeController();
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
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
                  key: const ValueKey('capture-estimate'),
                  child: EstimateDetailScreen(
                    reviewBeforeSave: reviewing,
                    initialRecord: estimateFixture(),
                    onUpdated: (_) {},
                    onCreateJob: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (reviewing) {
          expect(find.text('Continue editing'), findsNWidgets(2));
          expect(find.text('Save estimate'), findsOneWidget);
          expect(
            tester
                .widget<Scaffold>(find.byType(Scaffold).first)
                .bottomNavigationBar,
            isNull,
          );
          expect(
            find.byKey(const ValueKey('continue-editing-top')).hitTestable(),
            findsOneWidget,
          );
          if (width < 600) {
            expect(
              find
                  .byKey(const ValueKey('confirm-estimate-review'))
                  .hitTestable(),
              findsNothing,
            );
          }
        }
        expect(find.text('Manage this estimate'), findsNothing);
        expect(find.text('Labor and materials'), findsOneWidget);
        expect(find.text('Service terms and deposit'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (scale == 1 && (width == 430 || width == 1280)) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture-estimate')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/estimate-review-${width.toInt()}-$reviewing.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(
          find.byKey(
            ValueKey(
              reviewing ? 'confirm-estimate-review' : 'estimate-primary-send',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
