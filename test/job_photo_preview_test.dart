import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_photo_preview_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';

void main() {
  testWidgets(
    'saved job photo opens with its details and explicit unavailable image state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await tester.runAsync(DatabaseHarness.create);
      addTearDown(harness!.dispose);
      final work = await tester.runAsync(
        () async => openUiLabWorkSession(await harness.open()),
      );
      final record = WorkRecord(
        id: 'job-photo',
        kind: WorkRecordKind.job,
        number: 'JOB-1',
        title: 'Office cleaning',
        client: 'Test client',
        detail: 'Clean the reception area',
        pricing: WorkPricingModel.flatRate,
        total: 200,
        createdByEmployeeId: work!.permissions.actorEmployeeId,
        sitePhotos: [
          WorkSitePhoto(
            id: 'before',
            path: '${harness.directory.path}/unavailable.png',
            name: 'Reception before work',
            source: WorkSitePhotoSource.camera,
            addedOn: DateTime(2026, 9, 29),
            note: 'Scuff on the entrance door.',
          ),
        ],
      );
      expect(await tester.runAsync(() => work.create(record)), isTrue);
      final store = PrototypeOperationsStore(workSession: work);
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
              home: JobWorkspaceScreen(workRecord: record),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final photo = find.byKey(const ValueKey('job-photo-before'));
      await tester.ensureVisible(photo);
      await tester.pumpAndSettle();
      await tester.tap(photo);
      for (
        var i = 0;
        i < 30 && find.byType(EstimatePhotoPreviewScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.byType(EstimatePhotoPreviewScreen), findsOneWidget);
      expect(find.text('Job photo'), findsOneWidget);
      expect(find.text('Scuff on the entrance door.'), findsOneWidget);
      for (
        var i = 0;
        i < 30 &&
            find.text('This image could not be opened.').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('This image could not be opened.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
