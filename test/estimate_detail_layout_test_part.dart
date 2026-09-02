part of 'estimate_lifecycle_test.dart';

void registerEstimateDetailLayoutTests() {
  testWidgets('estimate detail and actions keep the created date first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    final record = _estimate(createdOn: DateTime(2026, 8, 30));

    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: EstimateDetailScreen(
            initialRecord: record,
            onUpdated: (_) {},
            onCreateJob: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estimate details'), findsOneWidget);
    expect(find.text('Sunday, August 30, 2026'), findsOneWidget);
    final detailDate = find.byKey(const ValueKey('work-date-heading'));
    expect(
      tester.getTopLeft(detailDate).dy,
      lessThan(tester.getTopLeft(find.text('Test estimate')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('estimate-actions-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Estimate actions'), findsOneWidget);
    expect(find.text('Sunday, August 30, 2026'), findsOneWidget);
    final actionsDate = find.byKey(const ValueKey('work-date-heading'));
    expect(
      tester.getTopLeft(actionsDate).dy,
      lessThan(tester.getTopLeft(find.text('Test estimate')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
