import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/native_widget_pump.dart';

Future<void> _pumpJob(
  WidgetTester tester, {
  required PrototypeOperationsStore store,
  JobWorkspacePermissions permissions =
      const JobWorkspacePermissions.development(),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  final job = store.workRecords.firstWhere((record) => record.id == 'job-1038');
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: job,
            permissions: permissions,
            onWorkRecordUpdated: store.updateWorkRecord,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openJobMaterials(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
  await waitForNativeSave(
    tester,
    () => find.byType(WorkItemsEditor).evaluate().isNotEmpty,
  );
}

void main() {
  testWidgets('receipt source copies one reviewed line with exact provenance', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final store = PrototypeOperationsStore(workSession: work);
    addTearDown(work.dispose);
    addTearDown(harness.dispose);
    addTearDown(store.dispose);
    final estimateBefore = store.workRecords.firstWhere(
      (record) => record.id == 'est-1042',
    );
    await _pumpJob(tester, store: store);
    await _openJobMaterials(tester);

    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await tester.pumpAndSettle();
    expect(find.text('QuickFuel'), findsNothing);
    expect(find.text('Local Hardware'), findsNothing);
    await tester.tap(find.text('Central Supply'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-line-EXP-1048-L2')));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextField, 'Your cost per each (optional)'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('job-material-billing-treatment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to invoice later').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Price per each'),
      '25',
    );
    await tester.ensureVisible(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await waitForNativeSave(
      tester,
      () => find.byType(WorkLineItemEditor).evaluate().isEmpty,
    );
    await tester.tap(find.text('Save items'));
    await tester.pumpAndSettle();
    expect(find.text('Record customer approval'), findsOneWidget);
    await tester.tap(find.text('Approval method'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verbal approval').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record approval'));
    await waitForNativeSave(
      tester,
      () => find.byType(WorkItemsEditor).evaluate().isEmpty,
    );

    expect(find.text('Quoted or planned total'), findsOneWidget);
    expect(find.text('For invoice review'), findsOneWidget);
    expect(find.text('Customer approval required'), findsNothing);

    final saved = store.workRecords.firstWhere(
      (record) => record.id == 'job-1038',
    );
    final addition = saved.items.singleWhere(
      (item) => item.isJobAddition && item.sourceExpenseId == 'EXP-1048',
    );
    expect(addition.name, '20-in braided stainless faucet connector');
    expect(addition.quantity, 2);
    expect(addition.unit, 'each');
    expect(addition.internalUnitCost, 12.49);
    expect(addition.customerPrice, 25);
    expect(
      addition.jobMaterialBillingTreatment,
      JobMaterialBillingTreatment.invoiceCandidate,
    );
    expect(addition.sourceExpenseLineId, 'EXP-1048-L2');
    expect(addition.sourceReceiptId, isNull);
    final estimateAfter = store.workRecords.firstWhere(
      (record) => record.id == 'est-1042',
    );
    expect(estimateAfter.revision, estimateBefore.revision);
    expect(estimateAfter.items, same(estimateBefore.items));
    expect(
      estimateAfter.customerSignature,
      same(estimateBefore.customerSignature),
    );
    expect(estimateAfter.hasCurrentCustomerSignature, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unitemized expense cannot become a fabricated material line', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    await _pumpJob(tester, store: store);
    await _openJobMaterials(tester);

    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Regional Materials Order'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regional Materials Order'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No reviewed material lines are available'),
      findsOneWidget,
    );
    expect(find.text('Add material'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('technician can use truck stock without seeing private costs', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    const permissions = JobWorkspacePermissions(
      canEditJob: false,
      canViewEstimate: true,
      canAddMaterials: true,
      canAttachReceipts: false,
      canChangeStatus: false,
      canContactCustomer: false,
      canUseTruckStock: true,
    );
    await _pumpJob(tester, store: store, permissions: permissions);
    await _openJobMaterials(tester);

    expect(find.text('Use recent material cost'), findsNothing);
    expect(find.byKey(const ValueKey('link-receipt-expense')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('use-truck-stock')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Braided faucet supply line').last);
    await tester.pumpAndSettle();

    expect(find.text('Customer price per unit'), findsNothing);
    expect(find.text('Internal cost per unit (optional)'), findsNothing);
    expect(
      find.textContaining('No customer charge will be added'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save items'));
    await tester.pumpAndSettle();

    final saved = store.workRecords.firstWhere(
      (record) => record.id == 'job-1038',
    );
    final addition = saved.items.singleWhere(
      (item) => item.isJobAddition && item.sourceStockId == 'stock-1001',
    );
    expect(addition.customerPrice, 0);
    expect(addition.internalUnitCost, 18.75);
    expect(
      addition.resolvedJobMaterialBillingTreatment,
      JobMaterialBillingTreatment.nonBillable,
    );
    expect(store.inventoryStock.first.quantity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense linking is independent from material editing', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    const permissions = JobWorkspacePermissions(
      canEditJob: false,
      canViewEstimate: true,
      canAddMaterials: false,
      canAttachReceipts: false,
      canChangeStatus: false,
      canContactCustomer: false,
      canLinkExpenses: true,
    );
    await _pumpJob(tester, store: store, permissions: permissions);

    expect(find.byKey(const ValueKey('job-link-expense')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-actions-fab')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-action-linkExpense')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('job-action-addMaterials')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing saved stock source blocks mutation without crashing', (
    tester,
  ) async {
    final base = prototypeDemoWorkRecords().firstWhere(
      (record) => record.id == 'job-1038',
    );
    const stale = WorkLineItem(
      id: 'stale-stock-line',
      type: WorkLineItemType.material,
      name: 'Previously used fitting',
      quantity: 1,
      unit: 'each',
      customerPrice: 0,
      sourceStockId: 'missing-stock-record',
      isJobAddition: true,
    );
    final record = base.reviseItems([
      ...base.items,
      stale,
    ], changedOn: DateTime(2026, 8, 30));
    final store = PrototypeOperationsStore(workRecords: [record]);
    addTearDown(store.dispose);
    await _pumpJob(tester, store: store);
    await _openJobMaterials(tester);

    await tester.tap(find.text('Save items'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('is no longer available. No stock was changed.'),
      findsOneWidget,
    );
    expect(find.byType(WorkItemsEditor), findsOneWidget);
    expect(
      store.workRecords
          .firstWhere((item) => item.id == 'job-1038')
          .items
          .where((item) => item.sourceStockId == 'missing-stock-record'),
      hasLength(1),
    );
    expect(store.inventoryStock.first.quantity, 2);
    expect(tester.takeException(), isNull);
  });
}
