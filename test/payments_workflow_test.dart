import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/payments_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/recorded_entries_section.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  testWidgets('Payments day arrows update the selected date in place', (
    tester,
  ) async {
    final store = PrototypeOperationsStore(
      workRecords: const [],
      financialEntries: const [],
    );
    addTearDown(store.dispose);
    final firstDay = DateTime(2026, 9, 26);
    await _pumpPayments(tester, store, firstDay);
    final bar = find.byKey(const ValueKey('payment-selected-date'));
    expect(bar, findsOneWidget);
    String shownDate() => tester
        .widget<Text>(find.descendant(of: bar, matching: find.byType(Text)))
        .data!;
    final localizations = MaterialLocalizations.of(tester.element(bar));
    expect(shownDate(), localizations.formatFullDate(firstDay));
    await tester.tap(
      find.descendant(
        of: bar,
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownDate(), localizations.formatFullDate(DateTime(2026, 9, 27)));
    await tester.tap(
      find.descendant(
        of: bar,
        matching: find.byIcon(Icons.chevron_left_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownDate(), localizations.formatFullDate(firstDay));
  });

  testWidgets('owner payment grant shows Record payment in Technician view', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final store = PrototypeOperationsStore(workSession: work);
    addTearDown(() async {
      store.dispose();
      work.dispose();
      await harness.dispose();
    });
    WorkSessionPermissions grants({
      required bool companyWide,
      required bool canRecord,
    }) => WorkSessionPermissions(
      organizationId: 'business',
      actorEmployeeId: 'owner',
      permissionRevision: 'owner-1',
      visibleCreatorIds: {'owner'},
      editableKinds: {WorkRecordKind.invoice},
      canManageOtherCreators: companyWide,
      canRecordPayments: canRecord,
    );

    final allowed = invoicePermissionsForWorkSession(
      AppViewMode.technician,
      grants(companyWide: true, canRecord: true),
    );
    await _pumpPayments(
      tester,
      store,
      DateTime(2026, 9, 26),
      permissions: allowed,
    );
    expect(find.byKey(const ValueKey('record-payment-fab')), findsOneWidget);

    final denied = invoicePermissionsForWorkSession(
      AppViewMode.technician,
      grants(companyWide: true, canRecord: false),
    );
    expect(denied.canRecordPayment, isFalse);
    expect(
      invoicePermissionsForWorkSession(
        AppViewMode.technician,
        grants(companyWide: false, canRecord: true),
      ).canRecordPayment,
      isFalse,
    );
  });

  test('paid invoices stop projecting their former due date', () {
    final issuedOn = DateTime(2026, 8, 5);
    final invoice = _invoice(
      id: 'invoice-paid-calendar',
      number: 'INV-PAID-CALENDAR',
      status: WorkRecordStatus.paid,
      total: 225,
    ).copyWith(issuedOn: issuedOn, dueOn: DateTime(2026, 9, 5));

    expect(invoice.occursOn(issuedOn), isTrue);
    expect(invoice.occursOn(DateTime(2026, 9, 5)), isFalse);
  });

  testWidgets(
    'payment picker uses remaining balance and opens the owning invoice',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final repository = SqliteWorkRepository(database);
      final today = DateUtils.dateOnly(DateTime.now());
      final openInvoice = _invoice(
        id: 'invoice-open',
        number: 'INV-3000',
        status: WorkRecordStatus.due,
        total: 425,
      );
      final invoices = [
        openInvoice,
        _invoice(
          id: 'invoice-draft',
          number: 'INV-DRAFT',
          status: WorkRecordStatus.draft,
          total: 300,
        ),
        _invoice(
          id: 'invoice-paid',
          number: 'INV-PAID',
          status: WorkRecordStatus.paid,
          total: 225,
        ),
      ];
      final payments = [
        PrototypeFinancialEntry(
          id: 'partial-payment',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: today,
          amountCents: 15000,
          sourceId: 'INV-3000',
          paymentMethod: 'Check',
        ),
        PrototypeFinancialEntry(
          id: 'paid-invoice-payment',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: today,
          amountCents: 22500,
          sourceId: 'invoice-paid',
          paymentMethod: 'Cash',
        ),
      ];
      await tester.runAsync(
        () => repository.commit(
          organizationId: 'business',
          commandId: 'payment-picker-fixture',
          actorEmployeeId: 'owner',
          permissionRevision: 'owner-1',
          occurredAt: DateTime.now().toUtc(),
          mutations: [
            for (final invoice in invoices)
              WorkRecordMutation(record: invoice, expectedStorageRevision: 0),
          ],
          financialEntries: payments,
        ),
      );
      final work = (await tester.runAsync(
        () => WorkPersistenceSession.open(
          repository,
          WorkSessionPermissions(
            organizationId: 'business',
            actorEmployeeId: 'owner',
            permissionRevision: 'owner-1',
            visibleCreatorIds: {'owner'},
            editableKinds: WorkRecordKind.values.toSet(),
            canManageOtherCreators: true,
            canIssueInvoices: true,
            canRecordPayments: true,
          ),
        ),
      ))!;
      final store = PrototypeOperationsStore(workSession: work);
      addTearDown(() async {
        store.dispose();
        work.dispose();
        await harness.dispose();
      });
      await _pumpPayments(tester, store, today);
      expect(
        find.ancestor(
          of: find.text('Payment entries'),
          matching: find.byType(RecordedEntriesSection),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Record payment').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment for an invoice'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('invoice-payment-picker-screen')),
        findsOneWidget,
      );
      expect(find.textContaining('INV-3000'), findsOneWidget);
      expect(find.textContaining('INV-DRAFT'), findsNothing);
      expect(find.textContaining('INV-PAID'), findsNothing);
      expect(find.text(r'$275.00'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('payment-invoice-invoice-open')),
      );
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('invoice-payment-amount'))
            .evaluate()
            .isNotEmpty,
      );

      final amount = tester.widget<TextField>(
        find.byKey(const ValueKey('invoice-payment-amount')),
      );
      expect(amount.controller!.text, '275.00');
      expect(find.text(r'Remaining balance: $275.00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
      await waitForNativeSave(
        tester,
        () =>
            store.workRecords.any(
              (record) =>
                  record.id == 'invoice-open' &&
                  record.status == WorkRecordStatus.paid,
            ) ||
            work.failureMessage != null,
      );

      final savedInvoice = store.workRecords.singleWhere(
        (record) => record.id == 'invoice-open',
      );
      expect(
        savedInvoice.status,
        WorkRecordStatus.paid,
        reason: work.failureMessage,
      );
      expect(
        store.financialEntries
            .where(
              (entry) =>
                  entry.kind == PrototypeFinancialKind.paymentReceived &&
                  entry.sourceId == 'INV-3000',
            )
            .fold(0, (sum, entry) => sum + entry.amountCents),
        42500,
      );

      await tester.tap(find.text('INV-3000').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('payment-detail-screen')),
        findsOneWidget,
      );
      await tester.tap(find.text('Open invoice INV-3000'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('invoice-detail-invoice-open')),
        findsOneWidget,
      );
      expect(find.text('Invoice details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Payments enforce financial view and record grants', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    final today = DateUtils.dateOnly(DateTime.now());
    await _pumpPayments(
      tester,
      store,
      today,
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

    expect(
      find.text('You do not have permission to view payments.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('record-payment-fab')), findsNothing);

    await _pumpPayments(
      tester,
      store,
      today,
      permissions: const InvoicePermissions.technicianDevelopment(),
    );
    expect(find.text('Payments received'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-payment-fab')), findsNothing);
  });

  test(
    'a stale invoice status cannot hide a balance or allow overpayment',
    () async {
      final invoice = _invoice(
        id: 'invoice-stale',
        number: 'INV-STALE',
        status: WorkRecordStatus.paid,
        total: 100,
      );
      final store = PrototypeOperationsStore(workRecords: [invoice]);
      addTearDown(store.dispose);
      final today = DateUtils.dateOnly(DateTime.now());
      final excessive = PrototypeFinancialEntry(
        id: 'too-much',
        kind: PrototypeFinancialKind.paymentReceived,
        occurredOn: today,
        amountCents: 10001,
        sourceId: invoice.id,
        paymentMethod: 'Cash',
      );
      expect(await store.recordInvoicePayment(invoice, excessive), isFalse);
      expect(
        store.financialEntries.where((entry) => entry.id == excessive.id),
        isEmpty,
      );
    },
  );
}

Future<void> _pumpPayments(
  WidgetTester tester,
  PrototypeOperationsStore store,
  DateTime today, {
  InvoicePermissions permissions = const InvoicePermissions.development(),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: PaymentsScreen(initialDay: today, permissions: permissions),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

WorkRecord _invoice({
  required String id,
  required String number,
  required WorkRecordStatus status,
  required double total,
}) => WorkRecord(
  id: id,
  kind: WorkRecordKind.invoice,
  number: number,
  title: 'Replace damaged service valve',
  createdByEmployeeId: 'owner',
  client: 'Taylor Brooks',
  detail: 'Completed service work and verified operation.',
  pricing: WorkPricingModel.timeAndMaterials,
  createdOn: DateTime.now(),
  issuedOn: DateTime.now(),
  dueOn: DateTime.now().add(const Duration(days: 14)),
  status: status,
  items: const [
    WorkLineItem(
      id: 'service-valve-labor',
      type: WorkLineItemType.labor,
      name: 'Service valve replacement labor',
      quantity: 2,
      unit: 'hours',
      customerPrice: 150,
    ),
    WorkLineItem(
      id: 'service-valve-material',
      type: WorkLineItemType.material,
      name: 'Service valve and fittings',
      quantity: 1,
      unit: 'set',
      customerPrice: 125,
    ),
  ],
  total: total,
);
