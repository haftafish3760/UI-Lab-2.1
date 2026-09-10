import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_installation_switch_coordinator.dart';
import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/local_restore_workflow.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';
import 'package:ui_lab_2_1/src/startup/application_startup_screen.dart';
import 'package:ui_lab_2_1/src/startup/ui_lab_startup_controller.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mode in [
    'success',
    'open failure',
    'save failure',
    'media pending',
  ]) {
    final failFirstOpen = mode == 'open failure';
    testWidgets('mounted restore and rollback preserve input: $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('mounted-switch-'),
      ))!;
      var failLoad = false;
      Completer<void>? loadGate;
      var gatedLoads = 0;
      Future<UiLabApp> load() async {
        if (loadGate case final gate?) {
          gatedLoads++;
          await gate.future;
        }
        if (failLoad) throw StateError('injected loader failure');
        return await openUiLabApplication(
              storageDirectory: root,
              nativeNotifications: const UnsupportedNativeNotificationGateway(),
            )
            as UiLabApp;
      }

      final original = (await tester.runAsync(load))!;
      final backup = (await tester.runAsync(
        () => LocalSnapshotBundle.capture(
          original.workSession!.repository.database,
        ),
      ))!;
      final selection = (await tester.runAsync(
        () => LocalInstallationSelection.open(root),
      ))!;
      final startup = UiLabStartupController(loadApplication: load);
      UiLabApp? current() => startup.currentApplication as UiLabApp?;
      bool blocked() => tester
          .widget<AbsorbPointer>(find.byType(AbsorbPointer).first)
          .absorbing;
      await tester.pumpWidget(
        ApplicationStartupScreen(
          load: () async => original,
          hostController: startup,
          onAbandoned: closeUnstartedApplication,
        ),
      );
      await waitForNativeSave(tester, () => current() != null);
      startup.configureRestore(selection: selection, authorize: () {});
      final restore = startup.restoreWorkflow!;
      final checkpointId = backup.directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last;
      late LocalRestoreReview review;
      await finishNativeOperation(tester, () async {
        review = await restore.reviewCheckpoint(checkpointId);
      });
      final runtime = startup.installationRuntime;
      final coordinator = LocalInstallationSwitchCoordinator(
        selection: selection,
        runtime: runtime,
      );
      final draft = DraftAutosaveSession(
        store: original.draftStore!,
        organizationId: 'business',
        ownerId: 'owner',
        domain: 'invoice',
        draftId: 'unfinished',
      );
      try {
        await finishNativeOperation(tester, draft.initialize);
        if (mode == 'save failure') {
          await finishNativeOperation(
            tester,
            () => original.workSession!.repository.database.customStatement(
              "CREATE TRIGGER fail_switch_draft BEFORE INSERT ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected draft failure'); END",
            ),
          );
        }
        draft.replaceInput({
          'amount': '12.',
          'notes': '  current unfinished input  ',
        });
        if (mode == 'media pending') {
          final requests = original.mediaCoordinator!.requests;
          late LocalMediaPickerRequest pending;
          await finishNativeOperation(tester, () async {
            pending = await requests.begin(
              organizationId: 'business',
              ownerId: 'owner',
              destination: MediaPickerDestination.estimate,
              targetId: 'unfinished-photo-target',
              targetRevision: 1,
              source: MediaPickerSource.camera,
            );
            await expectLater(
              restore.confirm(review),
              throwsA(
                isA<InstallationSwitchFailure>().having(
                  (error) => error.phase,
                  'phase',
                  InstallationSwitchPhase.pausing,
                ),
              ),
            );
          });
          expect(current(), same(original));
          expect(blocked(), isFalse);
          expect(draft.input['amount'], '12.');
          late LocalMediaPickerRequest? preserved;
          late InstallationSelectionState unchanged;
          await finishNativeOperation(tester, () async {
            preserved = await requests.findFor(
              organizationId: 'business',
              ownerId: 'owner',
            );
            unchanged = await selection.read();
          });
          expect(preserved!.requestId, pending.requestId);
          expect(unchanged.revision, 0);
          // Fixture-only request: no native picker was launched. Retire it so
          // the remainder also verifies the ready host can retry restoration.
          await finishNativeOperation(
            tester,
            () => requests.cancel(
              request: pending,
              organizationId: 'business',
              ownerId: 'owner',
            ),
          );
        }
        if (mode == 'save failure') {
          await finishNativeOperation(tester, () async {
            await expectLater(
              restore.confirm(review),
              throwsA(
                isA<InstallationSwitchFailure>().having(
                  (error) => error.phase,
                  'phase',
                  InstallationSwitchPhase.pausing,
                ),
              ),
            );
          });
          expect(current(), same(original));
          expect(blocked(), isFalse);
          expect(draft.input['amount'], '12.');
          expect(draft.hasFailure, isTrue);
          final unchanged = await tester.runAsync(selection.read);
          expect(unchanged!.revision, 0);
          await finishNativeOperation(
            tester,
            () => original.workSession!.repository.database.customStatement(
              'DROP TRIGGER fail_switch_draft',
            ),
          );
          draft.retry();
        }
        failLoad = failFirstOpen;
        if (failFirstOpen) {
          await finishNativeOperation(tester, () async {
            await expectLater(
              restore.confirm(review),
              throwsA(
                isA<InstallationSwitchFailure>().having(
                  (error) => error.phase,
                  'phase',
                  InstallationSwitchPhase.opening,
                ),
              ),
            );
          });
          expect(current(), isNull);
          expect(blocked(), isTrue);
          expect(restore.canRetryOpening, isTrue);
          // A separate caller must not bypass the workflow's busy guard and
          // start another loader against the same selected installation.
          loadGate = Completer<void>();
          late int attempts;
          await finishNativeOperation(tester, () async {
            final first = expectLater(
              restore.retryOpening(),
              throwsA(isA<InstallationSwitchFailure>()),
            );
            final second = expectLater(
              runtime.openSelected(),
              throwsStateError,
            );
            await Future<void>.delayed(Duration.zero);
            attempts = gatedLoads;
            loadGate!.complete();
            await Future.wait([first, second]);
          });
          expect(attempts, 1);
          loadGate = null;
          failLoad = false;
          await finishNativeOperation(tester, restore.retryOpening);
        } else {
          await finishNativeOperation(tester, () async {
            try {
              await restore.confirm(review);
            } on InstallationSwitchFailure catch (error) {
              fail('Switch ${error.phase}: ${error.cause}');
            }
          });
        }
        expect(blocked(), isFalse);

        expect(original.storageLifecycle!.isAttached, isFalse);
        late InstallationSelectionState selected;
        await finishNativeOperation(tester, () async {
          selected = await selection.read();
        });
        expect(selected.revision, 1);
        expect(selected.active, isNotEmpty);
        expect(
          current()!.workSession!.repository.database.storageFile!.path,
          '${selection.root.path}/${selected.active}/maintainiac.sqlite',
        );
        await finishNativeOperation(tester, draft.close);
        await finishNativeOperation(
          tester,
          () => coordinator.rollback(expectedRevision: 1),
        );
        final saved = await tester.runAsync(
          () => current()!.draftStore!.find(
            organizationId: 'business',
            ownerId: 'owner',
            domain: 'invoice',
            draftId: 'unfinished',
          ),
        );
        expect(saved!.payload, contains('  current unfinished input  '));
        expect(blocked(), isFalse);
        expect(coordinator.phase, InstallationSwitchPhase.idle);
        expect(tester.takeException(), isNull);
      } finally {
        final finalApplication = current();
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, draft.close);
        // Fixture cleanup must not mask a failure in the runtime under test.
        if (finalApplication != null) {
          await tester.runAsync(
            finalApplication.workSession!.repository.database.close,
          );
        }
        await tester.runAsync(original.workSession!.repository.database.close);
        await tester.runAsync(selection.close);
        await tester.runAsync(() => root.delete(recursive: true));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
}
