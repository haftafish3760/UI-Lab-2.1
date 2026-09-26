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
  testWidgets('job starting choices remain readable at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day = DateTime(2026, 9, 24);
    final store = PrototypeOperationsStore(
      workRecords: [
        WorkRecord(
          id: 'compact-estimate',
          kind: WorkRecordKind.estimate,
          number: 'Estimate 2003',
          title: 'Bathroom fan installation',
          client: 'Morgan Reed',
          detail: 'Install fan',
          pricing: WorkPricingModel.flatRate,
          createdOn: day,
        ),
      ],
    );
    final scope = OperationalScopeController(view: AppViewMode.admin);
    addTearDown(store.dispose);
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(1.7),
              ),
              child: JobStartScreen(initialDay: day),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create job without an estimate'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('job-start-estimate-compact-estimate')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new job entry uses the chosen approved estimate for scheduling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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
      final choice = find.byKey(
        const ValueKey('job-start-estimate-route-estimate'),
      );
      expect(tester.getSize(choice).height, lessThan(110));
      await tester.tap(choice);
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
