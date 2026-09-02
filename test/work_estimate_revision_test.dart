import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpWork(WidgetTester tester) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  final store = PrototypeOperationsStore();
  addTearDown(scope.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(theme: AppTheme.light, home: const WorkScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEstimates(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('open-estimates'));
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  test('changing only the source line identity creates a new revision', () {
    final estimate = prototypeDemoWorkRecords().firstWhere(
      (record) => record.id == 'est-1042',
    );
    final original = estimate.items.first;
    final sourced = WorkLineItem(
      id: original.id,
      type: original.type,
      name: original.name,
      description: original.description,
      quantity: original.quantity,
      unit: original.unit,
      customerPrice: original.customerPrice,
      internalUnitCost: original.internalUnitCost,
      sourceExpenseId: 'EXP-1048',
      sourceExpenseLineId: 'EXP-1048-L1',
      sourceReceiptId: original.sourceReceiptId,
      sourceStockId: original.sourceStockId,
      isJobAddition: original.isJobAddition,
    );

    final revised = estimate.reviseItems([
      sourced,
      ...estimate.items.skip(1),
    ], changedOn: DateTime(2026, 8, 30));

    expect(revised.revision, estimate.revision + 1);
    expect(revised.items.first.sourceExpenseLineId, 'EXP-1048-L1');
  });

  testWidgets('editing a signed estimate removes current customer approval', (
    tester,
  ) async {
    await _pumpWork(tester);
    await _openEstimates(tester);
    final record = find.byKey(const ValueKey('estimate-row-est-1042'));
    await tester.tap(record);
    await tester.pumpAndSettle();

    final editItems = find.byKey(const ValueKey('edit-estimate-items'));
    await tester.dragUntilVisible(
      editItems,
      find.byType(ListView).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(editItems);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-estimate-material')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Item name'),
      'Additional washer',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Customer price per unit'),
      '1',
    );
    await tester.tap(find.text('Add line item'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-estimate-items')));
    await tester.pumpAndSettle();

    expect(find.text('Customer approval required again'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('estimate-actions-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-create-job')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing estimate items reopen and save as a new revision', (
    tester,
  ) async {
    await _pumpWork(tester);
    await _openEstimates(tester);
    await tester.tap(find.byKey(const ValueKey('estimate-row-est-1042')));
    await tester.pumpAndSettle();

    final editItems = find.byKey(const ValueKey('edit-estimate-items'));
    await tester.dragUntilVisible(
      editItems,
      find.byType(ListView).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(editItems);
    await tester.pumpAndSettle();

    final existing = find.byKey(
      const ValueKey('edit-estimate-item-line-faucet'),
    );
    await tester.dragUntilVisible(
      existing,
      find.byType(ListView).last,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    await tester.tap(existing);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Item name'),
      'Customer-selected kitchen faucet',
    );
    await tester.tap(find.text('Save item changes'));
    await tester.pumpAndSettle();
    expect(find.text('Customer-selected kitchen faucet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-estimate-items')));
    await tester.pumpAndSettle();
    expect(find.text('Customer approval required again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
