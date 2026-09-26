import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_job_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/job_start_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'new job entry uses the chosen approved estimate for scheduling',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final day = DateTime(2026, 9, 24);
      final estimate = WorkRecord(
        id: 'route-estimate',
        kind: WorkRecordKind.estimate,
        number: 'EST-ROUTE',
        title: 'Schedule approved repair',
        client: 'Customer',
        detail: 'Repair fixture',
        pricing: WorkPricingModel.flatRate,
        createdOn: day,
        estimateStage: EstimateStage.approved,
        estimateDates: EstimateDates(createdOn: day, lastEditedOn: day),
        customerSignature: WorkCustomerSignature(
          signedBy: 'Customer',
          signedOn: day,
          signedRevision: 1,
        ),
      );
      final store = PrototypeOperationsStore(workRecords: [estimate]);
      final scope = OperationalScopeController(view: AppViewMode.admin);
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: JobStartScreen(initialDay: day),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('job-estimate-search')),
        'approved repair',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open estimate'));
      await tester.pumpAndSettle();
      expect(find.byType(EstimateDetailScreen), findsOneWidget);
      final action = find.byKey(const ValueKey('estimate-primary-job'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(WorkJobEditor), findsOneWidget);
      expect(
        tester
            .widget<WorkJobEditor>(find.byType(WorkJobEditor))
            .sourceEstimate
            ?.id,
        estimate.id,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
