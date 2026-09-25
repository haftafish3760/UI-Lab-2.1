import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'job materials survive reopen and failed confirmation keeps editor and draft',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      var store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      const job = WorkRecord(
        id: 'material-job',
        kind: WorkRecordKind.job,
        number: 'JOB-MATERIAL',
        title: 'Repair',
        client: 'Maya Thompson',
        detail: 'Repair',
        pricing: WorkPricingModel.flatRate,
      );
      expect(await tester.runAsync(() => work.create(job)), isTrue);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_materials BEFORE UPDATE ON local_records WHEN NEW.record_id = 'material-job' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        ),
      );
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> open() async {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: JobWorkspaceScreen(workRecord: job),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('job-actions-fab')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('job-action-addMaterials')));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.byType(WorkItemsEditor).evaluate().isNotEmpty,
        );
      }

      Future<void> back(Type type) async {
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(type).evaluate().isEmpty,
        );
      }

      await open();
      await tester.tap(find.byKey(const ValueKey('add-estimate-line-item')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<WorkLineItemType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Material').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('Material name'), 'Valve');
      await tester.enterText(field('Quantity'), '2..');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save unfinished item'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkLineItemEditor).evaluate().isEmpty,
      );
      await back(WorkItemsEditor);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      work.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      store = PrototypeOperationsStore(workSession: work);
      await open();
      await tester.tap(find.text('Valve'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Quantity')).controller!.text,
        '2..',
      );
      await tester.enterText(field('Quantity'), '2');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save item'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save item'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkLineItemEditor).evaluate().isEmpty,
      );
      await tester.tap(find.text('Save items'));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(find.byType(WorkItemsEditor), findsOneWidget);
      expect(
        work.records.singleWhere((record) => record.id == job.id).items,
        isEmpty,
      );
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_materials'),
      );
      await tester.tap(find.text('Save items'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkItemsEditor).evaluate().isEmpty,
      );
      expect(
        work.records
            .singleWhere((record) => record.id == job.id)
            .items
            .single
            .name,
        'Valve',
      );
      expect(
        work.records
            .singleWhere((record) => record.id == job.id)
            .items
            .single
            .isJobAddition,
        isTrue,
      );
      expect(
        await tester.runAsync(
          () => LocalDraftStore(db).list(
            organizationId: work.permissions.organizationId,
            domain: 'work/job-materials',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
