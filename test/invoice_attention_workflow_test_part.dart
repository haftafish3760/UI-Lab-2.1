part of 'invoice_workspace_test.dart';

void registerInvoiceAttentionWorkflowTests() {
  testWidgets('Overdue invoices and drafts stay out of ordinary date records', (
    tester,
  ) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final store = PrototypeOperationsStore(
      workRecords: [
        _invoice(
          id: 'overdue-invoice',
          number: 'INV-2200',
          detail: 'Awaiting customer payment',
          status: WorkRecordStatus.due,
          createdOn: now,
          dueOn: now.subtract(const Duration(days: 5)),
        ),
        _invoice(
          id: 'draft-invoice',
          number: 'INV-2201',
          detail: 'Draft invoice',
          status: WorkRecordStatus.draft,
          createdOn: now,
        ),
      ],
    );
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      store: store,
      view: AppViewMode.admin,
    );

    final overdue = find.byKey(
      const ValueKey('invoice-attention-row-overdue-invoice'),
    );
    expect(find.byKey(const ValueKey('invoice-attention')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('invoice-attention')),
        matching: overdue,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('invoice-date-records')),
        matching: find.byKey(const ValueKey('invoice-row-overdue-invoice')),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('invoice-drafts')), findsNothing);
    expect(find.byKey(const ValueKey('open-work-drafts')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invoice attention opens its exact invoice through shared list', (
    tester,
  ) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final store = PrototypeOperationsStore(
      workRecords: [
        _invoice(
          id: 'overdue-invoice',
          number: 'INV-2200',
          detail: 'Awaiting customer payment',
          status: WorkRecordStatus.due,
          createdOn: now,
          dueOn: now.subtract(const Duration(days: 5)),
        ),
      ],
    );
    await _pumpInvoices(
      tester,
      const Size(390, 844),
      store: store,
      view: AppViewMode.admin,
    );

    expect(find.text('Show all 1'), findsOneWidget);
    expect(find.byTooltip('Dismiss Needs attention'), findsOneWidget);
    await tester.tap(find.text('Show all 1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-attention-list')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('invoice-attention-list-overdue-invoice')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-detail-overdue-invoice')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
