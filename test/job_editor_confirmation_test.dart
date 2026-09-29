import 'support/visible_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/work_job_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'failed linked job confirmation retains draft and approval; retry consumes draft atomically',
    (tester) async {
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
      final source = WorkRecord(
        id: 'source-for-job',
        kind: WorkRecordKind.estimate,
        number: 'EST-SOURCE',
        title: 'Approved repair',
        client: 'Maya Thompson',
        detail: 'Approved work',
        pricing: WorkPricingModel.flatRate,
        estimateStage: EstimateStage.approved,
        customerSignature: WorkCustomerSignature(
          signedBy: 'Maya Thompson',
          signedOn: DateTime(2026, 9, 9),
          signedRevision: 1,
        ),
      );
      expect(await tester.runAsync(() => work.create(source)), isTrue);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_job_form BEFORE INSERT ON local_records WHEN NEW.record_id LIKE 'job-%' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        ),
      );
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => WorkJobEditor(
                          sourceEstimate: source,
                          initialDay: DateTime(2026, 9, 9),
                        ),
                      ),
                    ),
                    child: const Text('Plan job'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Plan job'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () =>
            find.byKey(const ValueKey('job-title-field')).evaluate().isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('job-title-field')),
        'Planned repair',
      );
      await tapVisibleControl(tester, find.byKey(const ValueKey('save-job')));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(WorkJobEditor), findsOneWidget);
      expect(
        work.records
            .singleWhere((r) => r.id == source.id)
            .resolvedEstimateStage,
        EstimateStage.approved,
      );
      final drafts = LocalDraftStore(db);
      Future<List<dynamic>> rows() => drafts.list(
        organizationId: work.permissions.organizationId,
        domain: 'work/job-editor',
        ownerId: work.permissions.actorEmployeeId,
      );
      final retained = (await tester.runAsync(rows))!;
      expect(drafts.decode(retained.single)['title'], 'Planned repair');
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_job_form'),
      );
      await tapVisibleControl(tester, find.byKey(const ValueKey('save-job')));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkJobEditor).evaluate().isEmpty,
      );
      expect(
        work.records.singleWhere((r) => r.sourceId == source.id).title,
        'Planned repair',
      );
      expect(
        work.records
            .singleWhere((r) => r.id == source.id)
            .resolvedEstimateStage,
        EstimateStage.converted,
      );
      expect(await tester.runAsync(rows), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
