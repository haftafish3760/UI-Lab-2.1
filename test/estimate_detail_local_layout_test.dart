import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('estimate actions follow the local pane width on a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    final created = DateTime(2026, 8, 30);
    final record = WorkRecord(
      id: 'estimate-local-pane',
      kind: WorkRecordKind.estimate,
      number: 'EST-LOCAL',
      title: 'Replace kitchen faucet',
      client: 'Maya Thompson',
      detail: 'Replace the existing faucet and test for leaks.',
      pricing: WorkPricingModel.flatRate,
      createdOn: created,
      status: WorkRecordStatus.ready,
      total: 250,
      estimateStage: EstimateStage.readyToSend,
      estimateDates: EstimateDates(
        createdOn: created,
        lastEditedOn: created,
        expiresOn: created.add(const Duration(days: 30)),
      ),
    );

    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 700,
              height: 900,
              child: EstimateDetailScreen(
                initialRecord: record,
                onUpdated: (_) {},
                onCreateJob: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('estimate-actions-fab')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('estimate-detail-estimate-local-pane')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
