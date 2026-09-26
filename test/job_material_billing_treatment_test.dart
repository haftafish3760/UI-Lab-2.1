import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

const _quoted = WorkLineItem(
  id: 'quoted',
  type: WorkLineItemType.material,
  name: 'Quoted material',
  quantity: 1,
  unit: 'item',
  customerPrice: 100,
);

const _notBilled = WorkLineItem(
  id: 'not-billed',
  type: WorkLineItemType.material,
  name: 'Not billed material',
  quantity: 2,
  unit: 'item',
  customerPrice: 0,
  internalUnitCost: 8,
  isJobAddition: true,
  jobMaterialBillingTreatment: JobMaterialBillingTreatment.nonBillable,
);

const _invoiceCandidate = WorkLineItem(
  id: 'invoice-candidate',
  type: WorkLineItemType.material,
  name: 'Invoice candidate material',
  quantity: 1,
  unit: 'item',
  customerPrice: 25,
  isJobAddition: true,
  jobMaterialBillingTreatment: JobMaterialBillingTreatment.invoiceCandidate,
);

const _approvalRequired = WorkLineItem(
  id: 'approval-required',
  type: WorkLineItemType.material,
  name: 'Approval-required material',
  quantity: 1,
  unit: 'item',
  customerPrice: 50,
  isJobAddition: true,
  jobMaterialBillingTreatment:
      JobMaterialBillingTreatment.customerApprovalRequired,
);

WorkRecord _completedJob({bool approveAddedMaterial = false}) => WorkRecord(
  id: 'job-billing-test',
  kind: WorkRecordKind.job,
  number: 'JOB-9001',
  title: 'Billing treatment test',
  client: 'Maya Thompson',
  detail: 'Verify explicit material billing treatment.',
  pricing: WorkPricingModel.flatRate,
  serviceLocation: '212 Oak Street',
  createdOn: DateTime(2026, 8, 30),
  scheduledStart: DateTime(2026, 8, 30, 9),
  completedOn: DateTime(2026, 8, 30, 11),
  status: WorkRecordStatus.completed,
  items: [
    _quoted,
    _notBilled,
    if (approveAddedMaterial)
      WorkLineItem(
        id: _invoiceCandidate.id,
        type: _invoiceCandidate.type,
        name: _invoiceCandidate.name,
        quantity: _invoiceCandidate.quantity,
        unit: _invoiceCandidate.unit,
        customerPrice: _invoiceCandidate.customerPrice,
        isJobAddition: true,
        jobMaterialBillingTreatment:
            JobMaterialBillingTreatment.invoiceCandidate,
        changeApproval: WorkCustomerApproval(
          method: CustomerApprovalMethod.verbal,
          customerName: 'Maya Thompson',
          recordedByEmployeeId: 'alex',
          recordedOn: DateTime(2026, 8, 30),
          revision: 1,
        ),
      )
    else
      _invoiceCandidate,
    _approvalRequired,
  ],
  total: 175,
);

Future<void> _pumpJob(
  WidgetTester tester, {
  required PrototypeOperationsStore store,
  required JobWorkspacePermissions permissions,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  final job = store.workRecords.firstWhere((item) => item.id == 'job-1038');
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

Future<void> _openMaterials(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
  await tester.pumpAndSettle();
}

void main() {
  test('job totals keep quoted and post-estimate treatments separate', () {
    final active = activeJobForRecord(
      _completedJob(),
      scheduledTime: 'August 30, 2026 · 9:00 AM',
    );

    expect(active.quotedTotal, 100);
    expect(active.invoiceCandidateTotal, 0);
    expect(active.approvalRequiredTotal, 75);
    final approved = activeJobForRecord(
      _completedJob(approveAddedMaterial: true),
      scheduledTime: 'August 30, 2026 · 9:00 AM',
    );
    expect(approved.invoiceCandidateTotal, 25);
    expect(approved.approvalRequiredTotal, 50);
  });

  test('billing treatment alone creates a meaningful item revision', () {
    final job = _completedJob();
    final revised = job.reviseItems([
      _quoted,
      _notBilled,
      const WorkLineItem(
        id: 'invoice-candidate',
        type: WorkLineItemType.material,
        name: 'Invoice candidate material',
        quantity: 1,
        unit: 'item',
        customerPrice: 25,
        isJobAddition: true,
        jobMaterialBillingTreatment:
            JobMaterialBillingTreatment.customerApprovalRequired,
      ),
      _approvalRequired,
    ], changedOn: DateTime(2026, 8, 31));

    expect(revised.revision, job.revision + 1);
  });

  testWidgets('invoice draft imports only quoted and invoice-candidate items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = _completedJob(approveAddedMaterial: true);
    final store = PrototypeOperationsStore(workRecords: [source]);
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
            home: InvoiceEditorScreen(
              initialDay: DateTime(2026, 8, 30),
              sourceJob: source,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'2 items · $125.00'), findsOneWidget);
    final invoiceItems = find.byKey(const ValueKey('invoice-items'));
    tester.widget<ListTile>(invoiceItems).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Quoted material'), findsOneWidget);
    expect(find.text('Invoice candidate material'), findsOneWidget);
    expect(find.text('Not billed material'), findsNothing);
    expect(find.text('Approval-required material'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restricted material editor preserves protected billing items', (
    tester,
  ) async {
    final base = prototypeDemoWorkRecords().firstWhere(
      (record) => record.id == 'job-1038',
    );
    final job = base.reviseItems([
      ...base.items,
      _invoiceCandidate,
    ], changedOn: DateTime(2026, 8, 30));
    final store = PrototypeOperationsStore(workRecords: [job]);
    addTearDown(store.dispose);
    const permissions = JobWorkspacePermissions(
      canEditJob: false,
      canViewEstimate: true,
      canAddMaterials: true,
      canAttachReceipts: false,
      canChangeStatus: false,
      canContactCustomer: false,
    );
    await _pumpJob(tester, store: store, permissions: permissions);
    await _openMaterials(tester);

    expect(find.text('Invoice candidate material'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('add-estimate-line-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Labor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Material').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Material name'),
      'Extra fitting used',
    );
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save items'));
    await tester.pumpAndSettle();

    final saved = store.workRecords.single;
    final protected = saved.items.singleWhere(
      (item) => item.id == 'invoice-candidate',
    );
    expect(protected.customerPrice, _invoiceCandidate.customerPrice);
    expect(
      protected.jobMaterialBillingTreatment,
      _invoiceCandidate.jobMaterialBillingTreatment,
    );
    final nonBillable = saved.items.singleWhere(
      (item) => item.name == 'Extra fitting used',
    );
    expect(nonBillable.customerPrice, 0);
    expect(
      nonBillable.resolvedJobMaterialBillingTreatment,
      JobMaterialBillingTreatment.nonBillable,
    );
    expect(tester.takeException(), isNull);
  });
}
