import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_balance.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  testWidgets(
    'invoice applies an earlier job payment without collecting again',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => openSeededTestWorkSession(database),
      ))!;
      final store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      final invoice = work.records.singleWhere(
        (record) => record.id == 'inv-2088',
      );
      final paidBefore = invoicePaidCents(invoice, work.financialEntries);
      final collectedBefore = work.financialEntries
          .where(
            (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
          )
          .fold(0, (sum, entry) => sum + entry.amountCents);
      expect(
        await tester.runAsync(
          () => work.save(
            financialEntries: [
              PrototypeFinancialEntry(
                id: 'prior-job-deposit',
                kind: PrototypeFinancialKind.paymentReceived,
                occurredOn: DateTime.now(),
                amountCents: 6000,
                sourceId: 'job-1026',
                paymentLinkKind: PaymentLinkKind.job,
                description: 'Faucet deposit',
                paymentMethod: 'Cash',
              ),
            ],
          ),
        ),
        isTrue,
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: InvoiceDetailScreen(record: invoice),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('invoice-apply-deposit')),
      );
      await tester.tap(find.byKey(const ValueKey('invoice-apply-deposit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Faucet deposit'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This does not record a new payment.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Apply deposit'));
      await waitForNativeSave(
        tester,
        () => work.financialEntries.any(
          (entry) => entry.kind == PrototypeFinancialKind.paymentApplied,
        ),
      );
      expect(
        invoicePaidCents(invoice, work.financialEntries),
        paidBefore + 6000,
      );
      final customerCopy = workCustomerDocument(
        invoice,
        store.companyProfile,
        store.customers.where((c) => c.name == invoice.client).firstOrNull,
        financialEntries: work.financialEntries,
      );
      expect(customerCopy.paidCents, paidBefore + 6000);
      expect(
        customerCopy.balanceCents,
        (invoice.total * 100).round() - paidBefore - 6000,
      );
      final pdf = await generateCustomerPdf(customerCopy);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      final masonryPdf = await generateCustomerPdf(
        customerCopy,
        templateId: 'masonry-v2',
      );
      expect(String.fromCharCodes(masonryPdf.take(5)), '%PDF-');
      expect(
        work.financialEntries
            .where(
              (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
            )
            .fold(0, (sum, entry) => sum + entry.amountCents),
        collectedBefore + 6000,
      );
    },
  );
}
