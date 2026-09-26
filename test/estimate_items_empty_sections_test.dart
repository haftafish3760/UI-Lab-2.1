import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  Future<void> showItems(WidgetTester tester, List<WorkLineItem> items) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: EstimateItemsScreen(
            initialItems: items,
            pricing: WorkPricingModel.timeAndMaterials,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Empty estimate shows add actions without empty item boxes', (
    tester,
  ) async {
    await showItems(tester, const []);
    expect(find.byKey(const ValueKey('add-estimate-labor')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-estimate-material')), findsOneWidget);
    expect(find.text('No labor has been added.'), findsNothing);
    expect(find.text('No materials have been added.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only populated item sections appear', (tester) async {
    await showItems(tester, const [
      WorkLineItem(
        id: 'labor-1',
        type: WorkLineItemType.labor,
        name: 'Install faucet',
        quantity: 1,
        unit: 'job',
        customerPrice: 90,
      ),
    ]);
    expect(find.text('Install faucet'), findsOneWidget);
    expect(find.text('Materials'), findsNothing);
    expect(find.text('No materials have been added.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
