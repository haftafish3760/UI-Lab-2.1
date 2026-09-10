import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('job status waits for SQLite and failed update can be retried', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final db = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    final job = WorkRecord(
      id: 'durable-job',
      kind: WorkRecordKind.job,
      number: 'JOB-TEST',
      title: 'Service visit',
      client: 'Maya Thompson',
      detail: 'Repair fixture',
      pricing: WorkPricingModel.flatRate,
      status: WorkRecordStatus.scheduled,
      scheduledStart: DateTime(2026, 9, 9, 9),
      scheduledEnd: DateTime(2026, 9, 9, 11),
    );
    expect(await tester.runAsync(() => work.create(job)), isTrue);
    await tester.runAsync(
      () => db.customStatement(
        "CREATE TRIGGER fail_job_status BEFORE UPDATE ON local_records WHEN NEW.record_id = 'durable-job' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      ),
    );
    var legacyCalls = 0;
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: JobWorkspaceScreen(
              workRecord: job,
              onWorkRecordUpdated: (_) => legacyCalls++,
            ),
          ),
        ),
      ),
    );
    Future<void> arrived() async {
      await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('job-action-markArrived')));
      await tester.pumpAndSettle();
    }

    await arrived();
    await waitForNativeSave(tester, () => work.failureMessage != null);
    expect(
      work.records.singleWhere((record) => record.id == job.id).status,
      WorkRecordStatus.scheduled,
    );
    expect(find.text('Scheduled'), findsWidgets);
    await tester.runAsync(
      () => db.customStatement('DROP TRIGGER fail_job_status'),
    );
    await arrived();
    await waitForNativeSave(
      tester,
      () =>
          work.records.singleWhere((record) => record.id == job.id).status ==
          WorkRecordStatus.arrived,
    );
    expect(find.text('Arrived'), findsWidgets);
    expect(legacyCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
