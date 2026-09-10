import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/start_workday_screen.dart';
import 'package:ui_lab_2_1/src/shared/local_draft_scope.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('start input survives Back/reopen and failed confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('start-draft-'),
    ))!;
    var db = (await tester.runAsync(
      () async => LocalDatabase.file(File('${directory.path}/data.sqlite')),
    ))!;
    late WorkdayPersistenceSession session;
    late OperationalScopeController scope;
    Future<void> mount() async {
      session = (await tester.runAsync(() => openUiLabWorkdaySession(db)))!;
      scope = OperationalScopeController();
      await tester.pumpWidget(
        LocalDraftScope(
          store: LocalDraftStore(db),
          child: WorkdayPersistenceScope(
            session: session,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StartWorkdayScreen(),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
    }

    try {
      await mount();
      final field = find.byKey(const ValueKey('start-day-odometer-field'));
      await tester.enterText(field, '1234.');
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Open').evaluate().isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      session.dispose();
      scope.dispose();
      await tester.runAsync(db.close);
      db = (await tester.runAsync(
        () async => LocalDatabase.file(File('${directory.path}/data.sqlite')),
      ))!;
      await mount();
      expect(tester.widget<TextField>(field).controller!.text, '1234.');
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER fail_workday BEFORE INSERT ON local_records WHEN NEW.domain = 'workday/records' BEGIN SELECT RAISE(ABORT, 'fail'); END",
        ),
      );
      final confirm = find.byKey(
        const ValueKey('confirm-start-workday-button'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => session.error != null && !session.isSaving,
      );
      expect(tester.widget<TextField>(field).controller!.text, '1234.');
      expect(session.records, isEmpty);
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_workday'),
      );
      await tester.tap(confirm);
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Open').evaluate().isNotEmpty,
      );
      expect(session.activeFor('alex')!.record.startOdometerTenths, 12340);
      final drafts = await tester.runAsync(
        () => db.select(db.localDrafts).get(),
      );
      expect(drafts, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      session.dispose();
      scope.dispose();
      await tester.runAsync(db.close);
      await tester.runAsync(() => directory.delete(recursive: true));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
