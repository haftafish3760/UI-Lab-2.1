import 'package:ui_lab_2_1/src/data/storage/local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/verified_local_snapshot_bundle.dart';
import 'package:ui_lab_2_1/src/data/storage/prepared_local_restore.dart';
import 'package:ui_lab_2_1/src/shared/local_document_path_scope.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final width in [390.0, 1400.0]) {
    testWidgets('restored startup menu saved-work editor round trip at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('saved-work-integration-'),
      ))!;
      var app =
          (await tester.runAsync(
                () => openUiLabApplication(
                  storageDirectory: directory,
                  resolveRetainedPath: (reference) => '/mapped/$reference',
                  nativeNotifications:
                      const UnsupportedNativeNotificationGateway(),
                ),
              ))!
              as UiLabApp;
      final seed = AppPreferencesController(storage: app.preferencesStore);
      final workflow = (await tester.runAsync(
        () => seed.openWorkDisplayDraft(
          initial: const WorkDisplayPreferences(showDailySummaries: false),
        ),
      ))!;
      await finishNativeOperation(tester, workflow.session.close);
      seed.dispose();
      // Exercise normal startup on a separately prepared writable installation.
      final prepared = (await tester.runAsync(() async {
        final snapshot = await LocalSnapshotBundle.capture(
          app.workSession!.repository.database,
        );
        return PreparedLocalRestore.prepare(
          source: await VerifiedLocalSnapshotBundle.open(snapshot.directory),
          liveDatabaseFile: app.workSession!.repository.database.storageFile!,
        );
      }))!;
      await tester.runAsync(() => closeUnstartedApplication(app));
      app =
          (await tester.runAsync(
                () => openUiLabApplication(
                  storageDirectory: prepared.directory,
                  resolveRetainedPath: prepared.resolveRetainedPath,
                  nativeNotifications:
                      const UnsupportedNativeNotificationGateway(),
                ),
              ))!
              as UiLabApp;

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pump();
      }

      try {
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        await tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('menu-system-settings')));
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('system-saved-work')));
        await waitForNativeSave(
          tester,
          () => find.text('Continue').evaluate().isNotEmpty,
        );
        await tap(find.text('Continue'));
        final toggle = find.byKey(const ValueKey('show-work-daily-summaries'));
        await waitForNativeSave(tester, () => toggle.evaluate().isNotEmpty);
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        expect(
          LocalDocumentPathScope.resolvePath(
            tester.element(toggle),
            '${prepared.directory.path}/attachments/new/image',
          ),
          '${prepared.directory.path}/attachments/new/image',
        );
        await tester.tap(toggle);
        await waitForNativeSave(
          tester,
          () => find.text('Draft saved on this device').evaluate().isNotEmpty,
        );
        await tester.pageBack();
        await waitForNativeSave(
          tester,
          () =>
              find.text('Continue').evaluate().isNotEmpty &&
              find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        expect(app.preferencesStore!.values['workShowDailySummaries'], isNull);
        await tap(find.text('Continue'));
        await waitForNativeSave(tester, () => toggle.evaluate().isNotEmpty);
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.pageBack();
        await waitForNativeSave(
          tester,
          () =>
              find.text('Continue').evaluate().isNotEmpty &&
              find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        app.dayNoteSession?.dispose();
        app.workdaySession?.dispose();
        app.directorySession?.dispose();
        app.workSession?.dispose();
        await tester.runAsync(
          () => app.workSession!.repository.database.close(),
        );
        await tester.runAsync(() => directory.delete(recursive: true));
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  }
}
