import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

WorkRecord _demoJob() =>
    prototypeDemoWorkRecords().firstWhere((record) => record.id == 'job-1038');

void main() {
  testWidgets('dashboard plan opens the responsive job details workspace', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await tester.pumpAndSettle();

    expect(find.text('Job details'), findsOneWidget);
    expect(find.text('Active Job'), findsNothing);
    expect(find.text('Active Job for the selected date.'), findsNothing);
    expect(find.byKey(const ValueKey('work-date-heading')), findsOneWidget);
    expect(find.text('Customer and job location'), findsOneWidget);
    expect(find.text('What needs to be done'), findsOneWidget);
    expect(find.text('Materials and labor for this job'), findsOneWidget);
    expect(find.text('Job photos and receipts'), findsOneWidget);
    expect(find.byKey(const ValueKey('job-actions-fab')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-attach-receipt')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-attach-photo')), findsOneWidget);
    expect(find.text('Materials list'), findsOneWidget);
    expect(find.text('Labor included'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('job-actions-screen')), findsOneWidget);
    expect(find.text('Mark arrived'), findsOneWidget);
    expect(find.text('Add materials'), findsOneWidget);
    expect(find.text('Add items to job'), findsNothing);
    expect(find.text('Link existing expense'), findsOneWidget);
    expect(find.text('Reschedule job'), findsOneWidget);
    expect(find.text('Reassign job'), findsOneWidget);
    final startTravel = tester.getTopLeft(
      find.byKey(const ValueKey('job-action-startTravel')),
    );
    final markArrived = tester.getTopLeft(
      find.byKey(const ValueKey('job-action-markArrived')),
    );
    expect((startTravel.dy - markArrived.dy).abs(), lessThan(1));
    expect(markArrived.dx, greaterThan(startTravel.dx));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call customer'));
    await tester.pumpAndSettle();
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Copy phone number'), findsOneWidget);
    expect(find.text('Copy email address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active job links an existing expense as a reviewed item', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await tester.pumpAndSettle();
    expect(find.text('Job materials'), findsWidgets);
    expect(find.byKey(const ValueKey('use-truck-stock')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Central Supply'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-line-EXP-1048-L1')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('job-material-billing-treatment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to invoice later').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Customer price per unit'),
      '250',
    );
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save materials'));
    await tester.pumpAndSettle();

    expect(find.text('Single-handle pull-down kitchen faucet'), findsOneWidget);
    expect(find.text('Linked to a recorded expense or receipt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone job actions advance through arrived and start work', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    final arrived = find.byKey(const ValueKey('job-action-markArrived'));
    await tester.ensureVisible(arrived);
    await tester.tap(arrived);
    await tester.pumpAndSettle();
    expect(find.text('Arrived'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Start work'), findsOneWidget);
    expect(find.text('Mark arrived'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('job-action-startWork')));
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing expense links to the job without creating a charge', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-action-linkExpense')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QuickFuel'));
    await tester.pumpAndSettle();

    expect(find.text('QuickFuel · \$64.72'), findsOneWidget);
    expect(find.text('QuickFuel material purchase'), findsNothing);
    expect(find.text('Receipts and linked expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrived status writes back to the owning job record', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    WorkRecord? updated;
    final record = WorkRecord(
      id: 'job-status-test',
      kind: WorkRecordKind.job,
      number: 'JOB-STATUS',
      title: 'Replace kitchen faucet',
      client: 'Maya Thompson',
      detail: 'Today · 10:30 AM',
      pricing: WorkPricingModel.flatRate,
      scheduledStart: DateTime(2026, 8, 31, 10, 30),
      status: WorkRecordStatus.scheduled,
    );
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: (value) => updated = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    final arrivedAction = find.byKey(const ValueKey('job-action-markArrived'));
    await tester.dragUntilVisible(
      arrivedAction,
      find.byType(ListView).last,
      const Offset(0, -100),
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(arrivedAction);
    await tester.pumpAndSettle();

    expect(updated?.status, WorkRecordStatus.arrived);
    expect(find.text('Arrived'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in-progress job can be marked for a return visit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    WorkRecord? updated;
    final record = WorkRecord(
      id: 'job-return-test',
      kind: WorkRecordKind.job,
      number: 'JOB-RETURN',
      title: 'Finish valve replacement',
      client: 'Casey Green',
      detail: 'Complete the remaining replacement work.',
      pricing: WorkPricingModel.timeAndMaterials,
      scheduledStart: DateTime(2026, 8, 31, 10, 30),
      status: WorkRecordStatus.inProgress,
    );
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: (value) => updated = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-action-needsReturnVisit')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('job-action-needsReturnVisit')));
    await tester.pumpAndSettle();

    expect(updated?.status, WorkRecordStatus.needsReturnVisit);
    expect(find.text('Needs return visit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Reschedule job'), findsOneWidget);
    expect(find.text('Start work'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job permissions remove unauthorized actions and routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
          home: JobWorkspaceScreen(
            workRecord: _demoJob(),
            permissions: const JobWorkspacePermissions(
              canEditJob: false,
              canViewEstimate: true,
              canAddMaterials: false,
              canAttachReceipts: false,
              canChangeStatus: false,
              canContactCustomer: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-actions-fab')), findsNothing);
    expect(find.byKey(const ValueKey('job-link-expense')), findsNothing);
    expect(find.byKey(const ValueKey('job-attach-receipt')), findsNothing);
    expect(find.byKey(const ValueKey('job-attach-photo')), findsNothing);
    expect(find.text('Call customer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job additions can be reopened and edited', (tester) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Central Supply'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-line-EXP-1048-L2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('job-material-billing-treatment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to invoice later').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Customer price per unit'),
      '250',
    );
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save materials'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Line item actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Item name'),
      'Central Supply fittings',
    );
    await tester.tap(find.text('Save item changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save materials'));
    await tester.pumpAndSettle();

    expect(find.text('Central Supply fittings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active job uses confirmed truck stock and reduces its quantity',
    (tester) async {
      await _pumpApp(tester, const Size(412, 915));
      final store = PrototypeOperationsScope.of(
        tester.element(find.text('Replace kitchen faucet').first),
      );
      expect(store.inventoryStock.first.quantity, 2);
      await tester.tap(find.text('Replace kitchen faucet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('use-truck-stock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Braided faucet supply line').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('job-material-billing-treatment')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to invoice later').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Customer price per unit'),
        '25',
      );
      await tester.tap(find.text('Add material'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save materials'));
      await tester.pumpAndSettle();

      expect(find.text('Braided faucet supply line'), findsWidgets);
      expect(find.text('Used from recorded truck stock'), findsOneWidget);
      expect(store.inventoryStock.first.quantity, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('active job reflows from one column to two bounded columns', (
    tester,
  ) async {
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    for (final size in [const Size(390, 844), const Size(1400, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: JobWorkspaceScreen(workRecord: _demoJob()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customer = tester.getTopLeft(
        find.text('Customer and job location'),
      );
      final estimate = tester.getTopLeft(
        find.text('Materials and labor for this job'),
      );
      if (size.width < 800) {
        expect(estimate.dy, greaterThan(customer.dy));
      } else {
        expect(estimate.dx, greaterThan(customer.dx));
      }
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('job actions follow the local pane width on a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
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
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 700,
              height: 900,
              child: JobWorkspaceScreen(workRecord: _demoJob()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-actions-fab')), findsOneWidget);
    expect(find.text('Materials and labor for this job'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active job preserves content at large system text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: JobWorkspaceScreen(workRecord: _demoJob()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer and job location'), findsOneWidget);
    expect(find.text('Materials and labor for this job'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
