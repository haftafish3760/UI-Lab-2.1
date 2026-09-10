import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'estimate readiness waits for SQLite and rejects a stale displayed revision',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      var callbacks = 0;
      try {
        final original = work.records.singleWhere(
          (item) => item.id == 'est-1040',
        );
        expect(original.resolvedEstimateStage, EstimateStage.draft);
        await tester.pumpWidget(UiLabApp(workSession: work));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(DashboardScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: original,
              onUpdated: (_) => callbacks++,
              onCreateJob: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_estimate BEFORE UPDATE ON local_records WHEN NEW.record_id = 'est-1040' BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        Future<void> ready() async {
          final button = find.text('Mark ready to send');
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pump();
        }

        await ready();
        await waitForNativeSave(
          tester,
          () => work.failureMessage != null && !work.isSaving,
        );
        expect(
          work.records
              .singleWhere((item) => item.id == original.id)
              .resolvedEstimateStage,
          EstimateStage.draft,
        );
        expect(find.text('Mark ready to send'), findsOneWidget);
        expect(callbacks, 0);
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_estimate'),
        );
        // A concurrent saved change must not be overwritten by the still-open details.
        expect(
          await tester.runAsync(
            () => work.update(original.copyWith(jobNotes: 'Concurrent note')),
          ),
          isTrue,
        );
        await ready();
        await waitForNativeSave(
          tester,
          () => work.failureMessage != null && !work.isSaving,
        );
        expect(
          work.records.singleWhere((item) => item.id == original.id).jobNotes,
          'Concurrent note',
        );
        expect(
          work.records
              .singleWhere((item) => item.id == original.id)
              .resolvedEstimateStage,
          EstimateStage.draft,
        );
        Navigator.of(tester.element(find.byType(EstimateDetailScreen))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(DashboardScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: original,
              onUpdated: (_) => callbacks++,
              onCreateJob: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await ready();
        await waitForNativeSave(
          tester,
          () =>
              work.records
                      .singleWhere((item) => item.id == original.id)
                      .resolvedEstimateStage ==
                  EstimateStage.readyToSend &&
              !work.isSaving,
        );
        expect(find.text('Mark ready to send'), findsNothing);
        expect(
          work.records.singleWhere((item) => item.id == original.id).jobNotes,
          'Concurrent note',
        );
        expect(callbacks, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(harness.dispose);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
