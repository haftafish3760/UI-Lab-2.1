part of 'invoice_workspace_test.dart';

void registerInvoiceAttentionWorkflowTests() {
  testWidgets(
    'Date activity derives paid grouping and search status from payments',
    (tester) async {
      final now = DateUtils.dateOnly(DateTime.now());
      final store = PrototypeOperationsStore(
        workRecords: [
          for (final id in ['settled', 'partial'])
            _invoice(
              id: id,
              number: 'INV-$id',
              detail: '',
              status: WorkRecordStatus.due,
              createdOn: now.subtract(const Duration(days: 4)),
              dueOn: now.add(const Duration(days: 4)),
            ),
        ],
        financialEntries: [
          for (final id in ['settled', 'partial'])
            PrototypeFinancialEntry(
              id: 'payment-$id',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: now.subtract(const Duration(days: 1)),
              amountCents: id == 'settled' ? 42500 : 10000,
              sourceId: id,
            ),
        ],
      );
      await _pumpInvoices(
        tester,
        const Size(900, 1400),
        store: store,
        view: AppViewMode.admin,
      );
      expect(find.byKey(const ValueKey('invoice-row-settled')), findsNothing);
      expect(find.byKey(const ValueKey('invoice-row-partial')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('invoice-row-partial')),
          matching: find.text('Partially paid'),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, 'INV-settled');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invoice-row-settled')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('invoice-row-settled')),
          matching: find.text('Paid in full'),
        ),
        findsOneWidget,
      );
      expect(find.text('Due'), findsNothing);
      expect(store.workRecords.first.status, WorkRecordStatus.due);
      expect(store.financialEntries, hasLength(2));
    },
  );

  testWidgets('Date activity hides financial attention, state and semantics', (
    tester,
  ) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final store = PrototypeOperationsStore(
      workRecords: [
        _invoice(
          id: 'private-due',
          number: 'INV-PRIVATE-DUE',
          detail: '',
          status: WorkRecordStatus.due,
          createdOn: now,
          dueOn: now.subtract(const Duration(days: 3)),
        ),
        _invoice(
          id: 'private-paid',
          number: 'INV-PRIVATE-PAID',
          detail: '',
          status: WorkRecordStatus.paid,
          createdOn: now,
        ),
        _invoice(
          id: 'private-other-date',
          number: 'INV-PRIVATE-OTHER',
          detail: '',
          status: WorkRecordStatus.due,
          createdOn: now.subtract(const Duration(days: 4)),
        ),
      ],
    );
    final semantics = tester.ensureSemantics();
    await _pumpInvoices(
      tester,
      const Size(900, 1200),
      store: store,
      view: AppViewMode.admin,
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
    expect(find.byKey(const ValueKey('invoice-attention')), findsNothing);
    expect(find.byKey(const ValueKey('invoice-open-records')), findsNothing);
    expect(
      find.byKey(const ValueKey('invoice-row-private-due')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoice-row-private-paid')),
      findsOneWidget,
    );
    expect(find.text('Due'), findsNothing);
    expect(find.text('Paid'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'Taylor Brooks,.*(Due|Paid)')),
      findsNothing,
    );
    expect(find.text(r'$425.00'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'Dated overdue invoices remain in date records while drafts stay separate',
    (tester) async {
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
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('invoice-row-draft-invoice')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('invoice-drafts')), findsNothing);
      expect(find.byKey(const ValueKey('open-work-drafts')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(WorkMonthCalendar),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('invoice-activity-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final calendar = tester.widget<WorkMonthCalendar>(
        find.byType(WorkMonthCalendar),
      );
      expect(calendar.entryCountForDay!(now), 1);
      expect(tester.takeException(), isNull);
    },
  );

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
