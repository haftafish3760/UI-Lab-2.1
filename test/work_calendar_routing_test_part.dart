part of 'work_screen_test.dart';

void registerWorkCalendarRoutingTests() {
  testWidgets('Work calendar opens a separate dated work screen', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844), view: AppViewMode.admin);
    final now = DateTime.now();
    final day = find.byKey(
      ValueKey('work-calendar-day-${now.year}-${now.month}-${now.day}'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('work-day-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-day-add-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('work-day-add-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('work-day-actions-screen')),
      findsOneWidget,
    );
    expect(find.text('New Job'), findsOneWidget);
    expect(find.text('New Estimate'), findsOneWidget);
    expect(find.text('New Invoice'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('work-day-action-recordPayment')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payments-screen')), findsOneWidget);
    expect(find.text('Payments received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work day entries open the exact owning record', (tester) async {
    await _pumpWork(tester, const Size(390, 844), view: AppViewMode.admin);
    final now = DateTime.now();
    final day = find.byKey(
      ValueKey('work-calendar-day-${now.year}-${now.month}-${now.day}'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    final estimate = find.byKey(const ValueKey('work-estimate-row-est-1042'));
    await tester.ensureVisible(estimate);
    await tester.tap(estimate);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('estimate-detail-est-1042')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('work-estimate-workspace')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
