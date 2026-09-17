import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_add_actions_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_job_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('Dashboard does not replay a stale editor result', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final db = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
    var workDisposed = false;
    try {
      await tester.pumpWidget(UiLabApp(workSession: work));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DashboardAddAction.schedule.controlKey));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () =>
            find.byKey(const ValueKey('job-title-field')).evaluate().isNotEmpty,
      );

      // Exercise the actual Dashboard return callback with an editor result
      // that became stale before navigation completed. Editor commit behavior
      // itself is covered by job_editor_confirmation_test.
      final returned = WorkRecord(
        id: 'job-return-race',
        kind: WorkRecordKind.job,
        number: 'JOB-RETURN',
        title: 'Editor committed title',
        client: 'Test customer',
        detail: 'Return callback ownership',
        pricing: WorkPricingModel.flatRate,
      );
      await finishNativeOperation(tester, () async {
        expect(await work.create(returned), isTrue);
      });
      final newer = returned.copyWith(status: WorkRecordStatus.arrived);
      await finishNativeOperation(tester, () async {
        expect(await work.update(newer), isTrue);
      });
      Navigator.of(tester.element(find.byType(WorkJobEditor))).pop(returned);
      await tester.pumpAndSettle();
      await waitForNativeSave(tester, () => !work.isSaving);
      expect(work.failureMessage, isNull);
      expect(work.records.single.status, WorkRecordStatus.arrived);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      work.dispose();
      workDisposed = true;
      await finishNativeOperation(tester, () => harness.close(db));
      final reopenedDb = (await tester.runAsync(harness.open))!;
      final reopened = (await tester.runAsync(
        () => openUiLabWorkSession(reopenedDb),
      ))!;
      expect(reopened.records.single.status, WorkRecordStatus.arrived);
      reopened.dispose();
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      if (!workDisposed) work.dispose();
      await finishNativeOperation(tester, harness.dispose);
    }
  });
}
