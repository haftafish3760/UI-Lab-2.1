import 'package:ui_lab_2_1/src/screens/inventory/inventory_models.dart'
    show demoInventoryStock;
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';
import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var cycle = 0; cycle < 40; cycle++) {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    final saving = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data?.startsWith('Saving on this device') ?? false),
    );
    if (cycle >= 3 && saving.evaluate().isEmpty) break;
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  Size size, {
  bool durableJob = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (!durableJob) {
    await tester.pumpWidget(const UiLabApp());
    await _settle(tester);
    return;
  }
  final work = await tester.runAsync(() async {
    final database = await DatabaseHarness.create();
    addTearDown(database.dispose);
    final db = await database.open();
    await SqliteWorkRepository(db).commit(
      organizationId: expenseUiLabOrganizationId,
      commandId: 'job-widget-fixtures',
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: 'test',
      occurredAt: DateTime.now(),
      mutations: [
        for (final record in prototypeDemoWorkRecords())
          WorkRecordMutation(record: record, expectedStorageRevision: 0),
      ],
    );
    final session = await openUiLabWorkSession(db);
    addTearDown(session.dispose);
    return session;
  });
  final store = PrototypeOperationsStore(
    workSession: work,
    inventoryStock: demoInventoryStock,
  );
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(workRecord: _demoJob()),
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 60 && !ready(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }
  expect(
    ready(),
    isTrue,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .join(' | '),
  );
}

Future<void> _saveApprovedItems(WidgetTester tester) async {
  await _waitFor(tester, () => find.text('Save items').evaluate().isNotEmpty);
  await tester.ensureVisible(find.text('Save items'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save items'));
  await tester.pumpAndSettle();
  await _waitFor(
    tester,
    () =>
        find.text('Record customer approval').evaluate().isNotEmpty ||
        find.byType(JobWorkspaceScreen).evaluate().isNotEmpty,
  );
  if (find.text('Record customer approval').evaluate().isNotEmpty) {
    await tester.tap(
      find.byType(DropdownButtonFormField<CustomerApprovalMethod>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(CustomerApprovalMethod.verbal.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record approval'));
    await tester.pumpAndSettle();
  }
  await _waitFor(
    tester,
    () => find.byType(JobWorkspaceScreen).evaluate().isNotEmpty,
  );
}

Widget _scopedJobApp({
  ThemeData? theme,
  required Widget home,
  TransitionBuilder? builder,
}) {
  final store = PrototypeOperationsStore();
  addTearDown(store.dispose);
  return PrototypeOperationsScope(
    store: store,
    child: MaterialApp(theme: theme, home: home, builder: builder),
  );
}

WorkRecord _demoJob() =>
    prototypeDemoWorkRecords().firstWhere((record) => record.id == 'job-1038');

void main() {
  testWidgets('completing a job offers and opens its invoice', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    final job = _demoJob().copyWith(status: WorkRecordStatus.inProgress);
    WorkRecord? updated;
    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: _scopedJobApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: job,
            onWorkRecordUpdated: (record) => updated = record,
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    final complete = find.byKey(const ValueKey('job-action-completeJob'));
    await tester.ensureVisible(complete);
    await tester.tap(complete);
    await _settle(tester);
    expect(updated?.status, WorkRecordStatus.completed);
    expect(find.text('Job completed'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Create invoice'),
      ),
    );
    await _settle(tester);
    expect(find.byType(InvoiceEditorScreen), findsOneWidget);
    expect(
      tester
          .widget<InvoiceEditorScreen>(find.byType(InvoiceEditorScreen))
          .sourceJob
          ?.id,
      job.id,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard plan opens the responsive job details workspace', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await _settle(tester);

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
    // This legacy layout fixture has no durable Work photo authority.
    expect(find.byKey(const ValueKey('job-attach-photo')), findsNothing);
    expect(find.text('Materials list'), findsOneWidget);
    expect(find.text('Labor included'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
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
    await _settle(tester);

    await tester.ensureVisible(find.text('Call customer'));
    await _settle(tester);
    await tester.tap(find.text('Call customer'));
    await _settle(tester);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Copy phone number'), findsOneWidget);
    expect(find.text('Copy email address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active job links an existing expense as a reviewed item', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915), durableJob: true);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await _settle(tester);
    expect(find.text('Job items'), findsWidgets);
    expect(find.byKey(const ValueKey('use-truck-stock')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await _settle(tester);
    await tester.tap(find.text('Central Supply'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('expense-line-EXP-1048-L1')));
    await _settle(tester);

    await tester.tap(
      find.byKey(const ValueKey('job-material-billing-treatment')),
    );
    await _settle(tester);
    await tester.tap(find.text('Add to invoice later').last);
    await _settle(tester);
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.labelText?.startsWith('Price per ') ?? false),
      ),
      '250',
    );
    await tester.ensureVisible(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await _settle(tester);
    await _saveApprovedItems(tester);

    expect(find.text('Single-handle pull-down kitchen faucet'), findsOneWidget);
    final saved = PrototypeOperationsScope.of(
      tester.element(find.byType(JobWorkspaceScreen)),
    ).workSession!.records.singleWhere((record) => record.id == _demoJob().id);
    final addition = saved.items.singleWhere(
      (item) => item.sourceExpenseLineId == 'EXP-1048-L1',
    );
    expect(addition.sourceExpenseId, 'EXP-1048');
    expect(addition.changeApproval?.method, CustomerApprovalMethod.verbal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone job actions advance through arrived and start work', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    final arrived = find.byKey(const ValueKey('job-action-markArrived'));
    await tester.ensureVisible(arrived);
    await tester.tap(arrived);
    await _settle(tester);
    expect(
      find.text('Arrived'),
      findsOneWidget,
      reason: PrototypeOperationsScope.maybeOf(
        tester.element(find.byType(JobWorkspaceScreen)),
      )?.workSession?.failureMessage,
    );

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    expect(find.text('Start work'), findsOneWidget);
    expect(find.text('Mark arrived'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('job-action-startWork')));
    await _settle(tester);
    expect(find.text('In progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing expense links to the job without creating a charge', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(412, 915));
    await tester.tap(find.text('Replace kitchen faucet'));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('job-action-linkExpense')));
    await _settle(tester);
    await tester.tap(find.text('QuickFuel'));
    await _settle(tester);

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
        child: _scopedJobApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: (value) => updated = value,
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    final arrivedAction = find.byKey(const ValueKey('job-action-markArrived'));
    await tester.dragUntilVisible(
      arrivedAction,
      find.byType(ListView).last,
      const Offset(0, -100),
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -80));
    await _settle(tester);
    await tester.tap(arrivedAction);
    await _settle(tester);

    expect(updated?.status, WorkRecordStatus.arrived);
    expect(
      find.text('Arrived'),
      findsOneWidget,
      reason: PrototypeOperationsScope.maybeOf(
        tester.element(find.byType(JobWorkspaceScreen)),
      )?.workSession?.failureMessage,
    );
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
        child: _scopedJobApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: (value) => updated = value,
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    expect(
      find.byKey(const ValueKey('job-action-needsReturnVisit')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('job-action-needsReturnVisit')));
    await _settle(tester);

    expect(updated?.status, WorkRecordStatus.needsReturnVisit);
    expect(find.text('Needs return visit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
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
        child: _scopedJobApp(
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
    await _settle(tester);

    expect(find.byKey(const ValueKey('job-actions-fab')), findsNothing);
    expect(find.byKey(const ValueKey('job-link-expense')), findsNothing);
    expect(find.byKey(const ValueKey('job-attach-receipt')), findsNothing);
    expect(find.byKey(const ValueKey('job-attach-photo')), findsNothing);
    expect(find.text('Call customer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job additions can be reopened and edited', (tester) async {
    await _pumpApp(tester, const Size(412, 915), durableJob: true);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await _settle(tester);
    await tester.tap(find.text('Central Supply'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('expense-line-EXP-1048-L2')));
    await _settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('job-material-billing-treatment')),
    );
    await _settle(tester);
    await tester.tap(find.text('Add to invoice later').last);
    await _settle(tester);
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.labelText?.startsWith('Price per ') ?? false),
      ),
      '250',
    );
    await tester.ensureVisible(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await _settle(tester);
    await _saveApprovedItems(tester);

    await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
    await _settle(tester);
    await tester.tap(find.byTooltip('Line item actions'));
    await _settle(tester);
    await tester.tap(find.text('Edit item'));
    await _settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Material name'),
      'Central Supply fittings',
    );
    await tester.ensureVisible(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await _settle(tester);
    await _saveApprovedItems(tester);

    expect(find.text('Central Supply fittings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active job uses confirmed truck stock and reduces its quantity',
    (tester) async {
      await _pumpApp(tester, const Size(412, 915), durableJob: true);
      final store = PrototypeOperationsScope.of(
        tester.element(find.byType(JobWorkspaceScreen)),
      );
      expect(store.inventoryStock.first.quantity, 2);

      await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('use-truck-stock')));
      await _settle(tester);
      await tester.tap(find.text('Braided faucet supply line').last);
      await _settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('job-material-billing-treatment')),
      );
      await _settle(tester);
      await tester.tap(find.text('Add to invoice later').last);
      await _settle(tester);
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              (widget.decoration?.labelText?.startsWith('Price per ') ?? false),
        ),
        '25',
      );
      await tester.ensureVisible(find.text('Save item'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save item'));
      await _settle(tester);
      await _saveApprovedItems(tester);

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
          child: _scopedJobApp(
            theme: AppTheme.light,
            home: JobWorkspaceScreen(workRecord: _demoJob()),
          ),
        ),
      );
      await _settle(tester);

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
        child: _scopedJobApp(
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
    await _settle(tester);

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
          child: _scopedJobApp(
            theme: AppTheme.light,
            home: JobWorkspaceScreen(workRecord: _demoJob()),
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Customer and job location'), findsOneWidget);
    expect(find.text('Materials and labor for this job'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
