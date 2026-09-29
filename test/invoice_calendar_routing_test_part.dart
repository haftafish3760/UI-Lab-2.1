part of 'invoice_workspace_test.dart';

void registerInvoiceCalendarRoutingTests() {
  for (final financialAccess in [true, false]) {
    testWidgets(
      'Payment-only invoice date activity respects financial access $financialAccess',
      (tester) async {
        final today = DateUtils.dateOnly(DateTime.now());
        final store = PrototypeOperationsStore(
          workRecords: [
            for (final id in ['payment-event', 'unrelated'])
              _invoice(
                id: id,
                number: 'INV-$id',
                detail: '',
                status: WorkRecordStatus.paid,
                createdOn: today.subtract(const Duration(days: 10)),
              ),
          ],
          financialEntries: [
            PrototypeFinancialEntry(
              id: 'received',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: today,
              amountCents: 40000,
              sourceId: 'payment-event',
            ),
            PrototypeFinancialEntry(
              id: 'applied',
              kind: PrototypeFinancialKind.paymentApplied,
              occurredOn: today,
              amountCents: 2500,
              sourceId: 'INV-payment-event',
            ),
            PrototypeFinancialEntry(
              id: 'wrong-kind',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: today,
              amountCents: 42500,
              sourceId: 'unrelated',
              paymentLinkKind: PaymentLinkKind.job,
            ),
          ],
        );
        await _pumpInvoices(
          tester,
          const Size(900, 1600),
          store: store,
          view: AppViewMode.admin,
          permissions: InvoicePermissions(
            canView: true,
            canViewFinancials: financialAccess,
            canCreate: false,
            canEditDraft: false,
            canPreviewCustomerCopy: false,
            canIssue: false,
            canRecordPayment: false,
          ),
        );
        final calendar = tester.widget<WorkMonthCalendar>(
          find.byType(WorkMonthCalendar),
        );
        expect(calendar.entryCountForDay!(today), financialAccess ? 1 : 0);
        expect(
          find.byKey(const ValueKey('invoice-row-payment-event')),
          financialAccess ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Payment received · Payment applied'),
          financialAccess ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('invoice-row-unrelated')),
          findsNothing,
        );
        expect(store.financialEntries, hasLength(3));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Invoice calendar selects the day in place and opens its Invoice',
    (tester) async {
      await _pumpInvoices(
        tester,
        const Size(390, 844),
        view: AppViewMode.admin,
      );
      final today = DateUtils.dateOnly(DateTime.now());
      final day = find.byKey(
        ValueKey('work-calendar-day-${today.year}-${today.month}-${today.day}'),
      );

      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      await tester.tap(day);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('work-invoice-workspace')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invoice-day-screen')), findsNothing);
      final invoice = find.byKey(const ValueKey('invoice-row-inv-2088'));
      await tester.ensureVisible(invoice);
      await tester.tap(
        find.ancestor(of: invoice, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('invoice-detail-inv-2088')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
