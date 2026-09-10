import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_payment_entry_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'payment draft survives reopen; failed ledger write retains input and balance',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      var store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      final invoice = work.records.firstWhere(
        (record) =>
            record.kind == WorkRecordKind.invoice &&
            record.status == WorkRecordStatus.due,
      );
      final revision = work.storageRevisionFor(invoice.id);
      final ledgerCount = work.financialEntries.length;
      Future<void> open() async {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => InvoicePaymentEntryScreen(
                            invoice: invoice,
                            balanceCents: (invoice.total * 100).round(),
                            initialDay: DateTime(2026, 9, 9),
                          ),
                        ),
                      ),
                      child: const Text('Record payment'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Record payment'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('invoice-payment-amount'))
              .evaluate()
              .isNotEmpty,
        );
      }

      await open();
      await tester.enterText(
        find.byKey(const ValueKey('invoice-payment-amount')),
        '12.',
      );
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(InvoicePaymentEntryScreen).evaluate().isEmpty,
      );
      expect(work.financialEntries, hasLength(ledgerCount));
      expect(work.storageRevisionFor(invoice.id), revision);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      work.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      store = PrototypeOperationsStore(workSession: work);
      await tester.runAsync(
        () => database.customStatement("""
      CREATE TRIGGER fail_recovered_payment BEFORE INSERT ON local_records
      WHEN NEW.domain = 'work/ledger'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await open();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('invoice-payment-amount')),
            )
            .controller!
            .text,
        '12.',
      );
      await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid amount with no more than two decimal places.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('invoice-payment-amount')),
        '12.00',
      );
      await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(InvoicePaymentEntryScreen), findsOneWidget);
      expect(work.financialEntries, hasLength(ledgerCount));
      expect(work.storageRevisionFor(invoice.id), revision);
      final drafts = LocalDraftStore(database);
      final retained = (await tester.runAsync(
        () => drafts.list(
          organizationId: work.permissions.organizationId,
          domain: 'work/payment-editor',
          ownerId: work.permissions.actorEmployeeId,
        ),
      ))!;
      expect(retained, hasLength(1));
      final paymentId = drafts.decode(retained.single)['paymentId'];
      await tester.runAsync(
        () => database.customStatement('DROP TRIGGER fail_recovered_payment'),
      );
      await tester.tap(find.byKey(const ValueKey('save-invoice-payment')));
      await waitForNativeSave(
        tester,
        () => find.byType(InvoicePaymentEntryScreen).evaluate().isEmpty,
      );
      final payment = work.financialEntries.singleWhere(
        (entry) => entry.id == paymentId,
      );
      expect(payment.amountCents, 1200);
      expect(payment.sourceId, invoice.number);
      expect(work.storageRevisionFor(invoice.id), revision + 1);
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: work.permissions.organizationId,
            domain: 'work/payment-editor',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
