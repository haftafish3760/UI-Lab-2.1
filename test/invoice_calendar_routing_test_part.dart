part of 'invoice_workspace_test.dart';

void registerInvoiceCalendarRoutingTests() {
  testWidgets('Invoice calendar day opens the exact owning Invoice', (
    tester,
  ) async {
    await _pumpInvoices(tester, const Size(390, 844), view: AppViewMode.admin);
    final today = DateUtils.dateOnly(DateTime.now());
    final day = find.byKey(
      ValueKey('work-calendar-day-${today.year}-${today.month}-${today.day}'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('invoice-day-screen')), findsOneWidget);
    final invoice = find.byKey(const ValueKey('invoice-day-row-inv-2088'));
    await tester.ensureVisible(invoice);
    await tester.tap(invoice);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('invoice-detail-inv-2088')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
