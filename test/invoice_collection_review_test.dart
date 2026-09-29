import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_collection_status.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  WorkRecord invoice({WorkRecordStatus status = WorkRecordStatus.due}) =>
      WorkRecord(
        id: 'invoice',
        kind: WorkRecordKind.invoice,
        number: 'INV-1',
        title: 'Kitchen repair',
        client: 'Customer',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        total: 100,
        status: status,
        dueOn: DateTime(2020, 1, 2),
      );
  PrototypeFinancialEntry payment(int cents) => PrototypeFinancialEntry(
    id: 'payment',
    kind: PrototypeFinancialKind.paymentReceived,
    occurredOn: DateTime(2020),
    amountCents: cents,
    sourceId: 'invoice',
  );

  test('due-day boundary, drafts and legacy paid state remain explicit', () {
    expect(
      invoiceCollectionStatus(invoice(), [], now: DateTime(2020, 1, 2, 23)),
      InvoiceCollectionStatus.unpaid,
    );
    expect(
      invoiceCollectionStatus(invoice(), [], now: DateTime(2020, 1, 3)),
      InvoiceCollectionStatus.overdue,
    );
    expect(
      invoiceCollectionStatus(invoice(status: WorkRecordStatus.draft), [
        payment(10000),
      ], now: DateTime(2026)),
      InvoiceCollectionStatus.draft,
    );
    expect(
      invoiceCollectionStatus(
        invoice(status: WorkRecordStatus.paid),
        [],
        now: DateTime(2026),
      ),
      InvoiceCollectionStatus.paid,
    );
  });

  for (final (cents, label, financials) in [
    (0, 'Overdue', true),
    (4000, 'Overdue · Partially paid', true),
    (10000, 'Paid in full', true),
    (10000, 'Due', false),
  ]) {
    testWidgets('review derives $label from saved payment projection', (
      tester,
    ) async {
      final record = invoice();
      final store = PrototypeOperationsStore(
        workRecords: [record],
        financialEntries: [if (cents > 0) payment(cents)],
      );
      addTearDown(store.dispose);
      final scope = OperationalScopeController();
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: InvoiceDetailScreen(
                record: record,
                permissions: financials
                    ? const InvoicePermissions.development()
                    : const InvoicePermissions(
                        canView: true,
                        canCreate: false,
                        canViewFinancials: false,
                        canEditDraft: false,
                        canPreviewCustomerCopy: false,
                        canIssue: false,
                        canRecordPayment: false,
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      if (financials) expect(find.text('Due'), findsNothing);
      if (!financials) {
        expect(find.text('Paid in full'), findsNothing);
        expect(find.text('Balance'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
