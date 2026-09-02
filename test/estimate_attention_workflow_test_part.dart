part of 'estimate_lifecycle_test.dart';

void registerEstimateAttentionWorkflowTests() {
  testWidgets('Estimate attention opens its exact record through shared list', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController(view: AppViewMode.admin);
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EstimateWorkspaceScreen(initialDay: DateTime.now()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show all 1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('estimate-attention-list')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('estimate-attention-list-est-1039')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('estimate-detail-est-1039')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
