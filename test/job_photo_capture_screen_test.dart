import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/startup/application_media_coordinator.dart';
import 'package:ui_lab_2_1/src/shared/native_media_picker_scope.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/fake_native_media_gateway.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final cancelled in [false, true]) {
    testWidgets(
      'job photo capture cancelled=$cancelled preserves confirmed job state',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        addTearDown(harness.dispose);
        final db = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final job = WorkRecord(
          id: 'capture-job',
          kind: WorkRecordKind.job,
          number: 'JOB-1',
          title: 'Office cleaning',
          client: 'Test client',
          detail: 'Clean office',
          createdByEmployeeId: work.permissions.actorEmployeeId,
          pricing: WorkPricingModel.flatRate,
          total: 200,
        );
        expect(await tester.runAsync(() => work.create(job)), isTrue);
        final file = File('${harness.directory.path}/picked.png');
        await tester.runAsync(
          () => file.writeAsBytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOIqpgGRAwQCgAmfgWhCo6K7AAAAABJRU5ErkJggg==',
            ),
          ),
        );
        final gateway = FakeNativeMediaGateway()
          ..onPick = () async => cancelled
              ? []
              : [
                  MediaPickerReturnedFile(
                    path: file.path,
                    name: 'Finished office.png',
                  ),
                ];
        final media = createApplicationMediaCoordinator(
          database: db,
          gateway: gateway,
          receiptPermissions: receiptDraftUiLabOwnerPermissions(),
          work: work,
        );
        final store = PrototypeOperationsStore(workSession: work);
        final scope = OperationalScopeController();
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
        await tester.pumpWidget(
          NativeMediaPickerScope(
            coordinator: media,
            child: PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: JobWorkspaceScreen(workRecord: job),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final add = find.byKey(const ValueKey('job-attach-photo'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('take-estimate-photo'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('take-estimate-photo')));
        if (cancelled) {
          await waitForNativeSave(
            tester,
            () =>
                gateway.picks == 1 &&
                tester
                        .widget<FilledButton>(
                          find.byKey(const ValueKey('take-estimate-photo')),
                        )
                        .onPressed !=
                    null,
          );
          expect(work.records.single.sitePhotos, isEmpty);
          expect(work.storageRevisionFor(job.id), 1);
          expect(find.text('Finished office.png'), findsNothing);
          final save = find.byKey(const ValueKey('save-estimate-photos'));
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await waitForNativeSave(
            tester,
            () => find
                .byKey(const ValueKey('estimate-site-photos-screen'))
                .evaluate()
                .isEmpty,
          );
          expect(work.records.single.sitePhotos, isEmpty);
          expect(find.text('New job photo'), findsNothing);
          expect(tester.takeException(), isNull);
          return;
        }

        await waitForNativeSave(
          tester,
          () => find.text('Finished office.png').evaluate().isNotEmpty,
        );
        expect(work.records.single.sitePhotos, isEmpty);
        final save = find.byKey(const ValueKey('save-estimate-photos'));
        await waitForNativeSave(
          tester,
          () => tester.widget<FilledButton>(save).onPressed != null,
        );
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await waitForNativeSave(
          tester,
          () =>
              work.records.single.sitePhotos.length == 1 &&
              find
                  .byKey(const ValueKey('estimate-site-photos-screen'))
                  .evaluate()
                  .isEmpty,
        );
        final saved = work.records.single.sitePhotos.single;
        expect(saved.path, isNot(file.path));
        expect(await tester.runAsync(() => File(saved.path).exists()), isTrue);
        expect(find.byKey(ValueKey('job-photo-${saved.id}')), findsOneWidget);
        expect(gateway.picks, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
