import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final canRecord in [false, true]) {
    for (final canSign in [false, true]) {
      testWidgets(
        'documented approval $canRecord and signature $canSign have independent controls',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = PrototypeOperationsStore();
          final scope = OperationalScopeController();
          addTearDown(store.dispose);
          addTearDown(scope.dispose);
          const record = WorkRecord(
            id: 'estimate',
            kind: WorkRecordKind.estimate,
            number: 'EST-1',
            title: 'Repair',
            client: 'Customer',
            detail: 'Repair fixture',
            pricing: WorkPricingModel.flatRate,
            total: 100,
          );
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: EstimateDetailScreen(
                    initialRecord: record,
                    onUpdated: (_) {},
                    onCreateJob: (_) {},
                    permissions: EstimatePermissions(
                      canView: true,
                      canCreate: false,
                      canEditItems: false,
                      canSend: false,
                      canCollectSignature: canSign,
                      canRecordCustomerApproval: canRecord,
                      canConvertToJob: false,
                      canViewEstimateTotals: true,
                      canViewInternalCosts: false,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Record customer approval'),
            canRecord ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Sign in person'),
            canSign ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
