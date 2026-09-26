import 'package:flutter/material.dart';
import 'support/load_material_test_font.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMaterialTestFont);
  for (final width in [320.0, 390.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('estimate controls at width $width scale $scale', (
        tester,
      ) async {
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
                theme: AppTheme.light.copyWith(
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: AppTheme.light.outlinedButtonTheme.style!.copyWith(
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  filledButtonTheme: FilledButtonThemeData(
                    style: AppTheme.light.filledButtonTheme.style!.copyWith(
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: EstimateEditorScreen(initialDay: DateTime(2026, 9, 25)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final close = find.byKey(const ValueKey('estimate-close'));
        final preview = find.byKey(const ValueKey('estimate-live-pdf-preview'));
        final save = find.byKey(const ValueKey('save-estimate-draft'));
        for (final button in [close, preview, save]) {
          expect(button, findsOneWidget);
          expect(
            find.descendant(of: button, matching: find.byType(Icon)),
            findsNothing,
          );
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        if (scale == 1) {
          expect(tester.getTopLeft(close).dy, tester.getTopLeft(preview).dy);
          expect(tester.getTopLeft(preview).dy, tester.getTopLeft(save).dy);
        }
        if (width == 1440 && scale == 1) {
          expect(
            find.byKey(const ValueKey('operations-3-lane-grid')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('wide estimate review has three content lanes and prices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
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
            theme: AppTheme.light.copyWith(
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: AppTheme.light.outlinedButtonTheme.style!.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: AppTheme.light.filledButtonTheme.style!.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            home: EstimateDetailScreen(
              initialRecord: const WorkRecord(
                id: 'qa-review',
                pricing: WorkPricingModel.flatRate,
                kind: WorkRecordKind.estimate,
                number: 'QA',
                title: 'Test work',
                client: 'Test customer',
                detail: 'Description',
                total: 100,
                items: [
                  WorkLineItem(
                    id: 'qa-line',
                    type: WorkLineItemType.labor,
                    name: 'Work',
                    quantity: 1,
                    unit: 'job',
                    customerPrice: 100,
                  ),
                ],
              ),
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('operations-3-lane-grid')),
      findsOneWidget,
    );
    expect(find.text('Estimated total: \$100.00'), findsOneWidget);
    expect(find.text('Changes and sharing history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
