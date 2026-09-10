import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/payments_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/recorded_entries_section.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
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
      final today = DateUtils.dateOnly(DateTime.now());
      final openInvoice = _invoice(
        id: 'invoice-open',
        number: 'INV-3000',
        status: WorkRecordStatus.due,
        total: 425,
      );
      final store = PrototypeOperationsStore(
        workRecords: [
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
        ],
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'partial-payment',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: today,
            amountCents: 15000,
            sourceId: 'INV-3000',
            paymentMethod: 'Check',
          ),
        ],
      );
      addTearDown(store.dispose);
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
      await tester.pumpAndSettle();

      final amount = tester.widget<TextField>(
        find.byKey(const ValueKey('invoice-payment-amount')),
      );
      expect(amount.controller!.text, '275.00');
      expect(find.text(r'Remaining balance: $275.00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
      await tester.pumpAndSettle();

      final savedInvoice = store.workRecords.singleWhere(
        (record) => record.id == 'invoice-open',
      );
      expect(savedInvoice.status, WorkRecordStatus.paid);
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
