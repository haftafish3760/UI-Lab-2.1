import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

part 'invoice_attention_workflow_test_part.dart';
part 'invoice_calendar_routing_test_part.dart';

Future<void> _pumpInvoices(
  WidgetTester tester,
  Size size, {
  PrototypeOperationsStore? store,
  AppViewMode view = AppViewMode.technician,
  double textScale = 1,
  InvoicePermissions permissions = const InvoicePermissions.development(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final operationsStore = store ?? PrototypeOperationsStore();
  final scope = OperationalScopeController(view: view);
  addTearDown(operationsStore.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: operationsStore,
      child: OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: InvoiceWorkspaceScreen(
              initialDay: DateTime.now(),
              permissions: permissions,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpInvoiceDetail(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = PrototypeOperationsStore();
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  final invoice = store.workRecords.firstWhere(
    (record) => record.id == 'inv-2088',
  );
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: InvoiceDetailScreen(record: invoice),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  registerInvoiceAttentionWorkflowTests();
  registerInvoiceCalendarRoutingTests();
  testWidgets('Invoice workspace enforces view permission at the route', (
    tester,
  ) async {
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      permissions: const InvoicePermissions(
        canView: false,
        canCreate: false,
        canViewFinancials: false,
        canEditDraft: false,
        canPreviewCustomerCopy: false,
        canIssue: false,
        canRecordPayment: false,
      ),
    );

    expect(
      find.text('You do not have permission to view invoices.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('new-invoice')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-search')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-row-inv-2088')), findsNothing);
  });

  testWidgets('Invoice financials and actions respect read-only permission', (
    tester,
  ) async {
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      permissions: const InvoicePermissions(
        canView: true,
        canCreate: false,
        canViewFinancials: false,
        canEditDraft: false,
        canPreviewCustomerCopy: false,
        canIssue: false,
        canRecordPayment: false,
      ),
    );

    final row = find.byKey(const ValueKey('invoice-row-inv-2088'));
    expect(row, findsOneWidget);
    expect(find.byKey(const ValueKey('new-invoice')), findsNothing);
    expect(find.text(r'$685.00'), findsNothing);
    await tester.tap(
      find.ancestor(of: row, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Invoice items'), findsOneWidget);
    expect(find.text('Balance'), findsNothing);
    expect(find.text('Payment history'), findsNothing);
    expect(find.byKey(const ValueKey('invoice-actions-fab')), findsNothing);
    expect(find.text(r'$685.00'), findsNothing);
  });

  testWidgets('Invoices use date activity, filing lanes, and separate rows', (
    tester,
  ) async {
    await _pumpInvoices(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('invoice-selected-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-date-records')), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-open-records')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-drafts')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-invoice')), findsOneWidget);
    expect(find.text('Selected date'), findsNothing);
    expect(find.text('All invoices'), findsNothing);

    final row = find.byKey(const ValueKey('invoice-row-inv-2088'));
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, lessThanOrEqualTo(72));
    await tester.tap(
      find.ancestor(of: row, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-detail-inv-2088')),
      findsOneWidget,
    );
    expect(find.text('Invoice items'), findsOneWidget);
    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('Invoice details'), findsOneWidget);
    expect(find.text('Tuesday, September 1, 2026'), findsOneWidget);
    expect(
      find.textContaining('installed the approved replacement'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('New invoice uses a dedicated job-aware draft editor', (
    tester,
  ) async {
    await _pumpInvoices(tester, const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('new-invoice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invoice-editor-screen')), findsOneWidget);
    expect(find.text('Direct invoice'), findsOneWidget);
    expect(find.text('Save invoice draft'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('invoice-source-job')));
    await tester.pumpAndSettle();
    expect(find.textContaining('JOB-1038'), findsNothing);
    await tester.tap(find.textContaining('JOB-1026').last);
    await tester.pumpAndSettle();

    final title = tester.widget<TextField>(
      find.byKey(const ValueKey('invoice-title')),
    );
    final summary = tester.widget<TextField>(
      find.byKey(const ValueKey('invoice-summary')),
    );
    expect(title.controller!.text, 'Replace kitchen faucet');
    expect(
      summary.controller!.text,
      contains('installed the approved replacement'),
    );
    expect(find.text(r'4 items · $685.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice draft validation keeps incomplete records out of file', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    final before = store.workRecords
        .where((record) => record.kind == WorkRecordKind.invoice)
        .length;
    await _pumpInvoices(tester, const Size(390, 844), store: store);

    await tester.tap(find.byKey(const ValueKey('new-invoice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-invoice-draft')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Choose a customer and enter the work completed with at least one invoice item.',
      ),
      findsOneWidget,
    );
    expect(
      store.workRecords
          .where((record) => record.kind == WorkRecordKind.invoice)
          .length,
      before,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Linked job becomes a saved invoice draft with stable ownership',
    (tester) async {
      final store = PrototypeOperationsStore();
      await _pumpInvoices(tester, const Size(390, 844), store: store);

      await tester.tap(find.byKey(const ValueKey('new-invoice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('invoice-source-job')));
      await tester.pumpAndSettle();
      expect(find.textContaining('JOB-1038'), findsNothing);
      await tester.tap(find.textContaining('JOB-1026').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-invoice-draft')));
      await tester.pumpAndSettle();

      final saved = store.workRecords.lastWhere(
        (record) =>
            record.kind == WorkRecordKind.invoice &&
            record.status == WorkRecordStatus.draft &&
            record.sourceId == 'job-1026',
      );
      expect(saved.client, 'Maya Thompson');
      expect(saved.items, hasLength(4));
      expect(saved.total, 685);
      expect(find.byKey(const ValueKey('invoice-drafts')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Invoice search covers the authorized invoice file', (
    tester,
  ) async {
    await _pumpInvoices(tester, const Size(390, 844));

    await tester.enterText(
      find.byKey(const ValueKey('invoice-search')),
      'JOB-1026',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('invoice-search-results')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('invoice-row-inv-2088')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice rows reflow accessibility text', (tester) async {
    await _pumpInvoices(tester, const Size(320, 844), textScale: 2);
    expect(find.text('Maya Thompson'), findsOneWidget);
    expect(find.text(r'$685.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice editor preserves content at large accessibility text', (
    tester,
  ) async {
    await _pumpInvoices(tester, const Size(320, 844), textScale: 2);
    await tester.tap(find.byKey(const ValueKey('new-invoice')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('invoice-editor-screen')), findsOneWidget);
    expect(find.text('Prepare an invoice'), findsOneWidget);
    expect(find.text('Save invoice draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Issuing a draft posts one invoice ledger event', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final draft = _invoice(
      id: 'draft-to-issue',
      number: 'INV-2300',
      detail: 'Completed service work',
      status: WorkRecordStatus.draft,
      createdOn: today,
    );
    final store = PrototypeOperationsStore(
      workRecords: [draft],
      financialEntries: const [],
    );
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      store: store,
      view: AppViewMode.admin,
    );

    final draftRow = find.byKey(const ValueKey('invoice-row-draft-to-issue'));
    await tester.dragUntilVisible(
      draftRow,
      find.byType(ListView).first,
      const Offset(0, -180),
    );
    await tester.tap(
      find.ancestor(of: draftRow, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invoice-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('issue-invoice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-issue-invoice')));
    await tester.pumpAndSettle();

    expect(store.workRecords.single.status, WorkRecordStatus.due);
    expect(
      store.financialEntries
          .where(
            (entry) =>
                entry.kind == PrototypeFinancialKind.invoiceIssued &&
                entry.sourceId == 'INV-2300',
          )
          .length,
      1,
    );
    expect(
      find.byKey(const ValueKey('invoice-detail-draft-to-issue')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice payment is applied to its exact invoice and closes it', (
    tester,
  ) async {
    final store = PrototypeOperationsStore(financialEntries: const []);
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      store: store,
      view: AppViewMode.admin,
    );

    final invoiceRow = find.byKey(const ValueKey('invoice-row-inv-2088'));
    await tester.dragUntilVisible(
      invoiceRow,
      find.byType(ListView).first,
      const Offset(0, -140),
    );
    await tester.tap(
      find.ancestor(of: invoiceRow, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invoice-actions-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-invoice-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
    await tester.pumpAndSettle();

    final invoice = store.workRecords.firstWhere(
      (record) => record.id == 'inv-2088',
    );
    expect(invoice.status, WorkRecordStatus.paid);
    expect(
      store.financialEntries
          .singleWhere(
            (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
          )
          .sourceId,
      'INV-2088',
    );
    expect(find.text('Paid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice detail reflows instead of clipping large text', (
    tester,
  ) async {
    await _pumpInvoiceDetail(tester, const Size(320, 844), textScale: 2);

    expect(
      find.byKey(const ValueKey('invoice-detail-inv-2088')),
      findsOneWidget,
    );
    expect(find.text('Invoice actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 412.0, 800.0, 1440.0]) {
    testWidgets('Invoice workspace reflows cleanly at ${width.toInt()} LP', (
      tester,
    ) async {
      await _pumpInvoices(tester, Size(width, 1000));

      expect(
        find.byKey(const ValueKey('invoice-selected-date')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('invoice-date-records')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('work-5-7-calendar')), findsOneWidget);
      if (width == 1440) {
        expect(
          tester.getSize(find.byKey(const ValueKey('work-5-7-calendar'))).width,
          lessThanOrEqualTo(AppLayoutEngine.maximumOperationsWorkspaceWidth),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}

WorkRecord _invoice({
  required String id,
  required String number,
  required String detail,
  required WorkRecordStatus status,
  required DateTime createdOn,
  DateTime? dueOn,
}) => WorkRecord(
  id: id,
  kind: WorkRecordKind.invoice,
  number: number,
  title: 'Replace damaged service valve',
  client: 'Taylor Brooks',
  detail: detail,
  pricing: WorkPricingModel.timeAndMaterials,
  sourceId: 'JOB-2199',
  createdOn: createdOn,
  dueOn: dueOn,
  status: status,
  total: 425,
);
