import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 430.0, 1280.0]) {
    testWidgets('estimate actions are inline and unobscured at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PrototypeOperationsStore();
      final scope = OperationalScopeController();
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: EstimateDetailScreen(
                initialRecord: WorkRecord(
                  id: 'draft-navigation',
                  kind: WorkRecordKind.estimate,
                  number: 'Estimate 2001',
                  title: 'Kitchen repair',
                  client: 'Avery Wilson',
                  detail: 'Repair kitchen fittings',
                  pricing: WorkPricingModel.flatRate,
                  estimateStage: EstimateStage.draft,
                  createdOn: DateTime(2026, 9, 14),
                ),
                onUpdated: (_) {},
                onCreateJob: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      for (final action in ['edit', 'items', 'preview', 'send', 'job']) {
        expect(
          find.byKey(ValueKey('estimate-primary-$action')),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('estimate-primary-job')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('estimate-primary-edit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('estimate-editor-screen')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
