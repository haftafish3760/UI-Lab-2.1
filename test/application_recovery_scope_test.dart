import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_hub.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/application_recovery_scope.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'package:ui_lab_2_1/src/shared/preference_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'receipt_evidence_draft_workflow_test.dart' show openEvidenceSession;
import 'recurring_payment_draft_workflow_test.dart' show openSession;

void main() {
  testWidgets(
    'layout rebuild retains selection; replacement and unmount retire recovery',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp(
          'application-recovery-scope-',
        );
        final p = await LocalPersistence.open(directory: dir);
        final work = await openUiLabWorkSession(p.database);
        final directory = await openUiLabDirectory(p.database);
        final workday = await openUiLabWorkdaySession(p.database);
        final notes = await openUiLabDayNotes(p.database);
        final operations = PrototypeOperationsStore(
          workSession: work,
          directorySession: directory,
          workdaySession: workday,
          dayNoteSession: notes,
        );
        final prefs = AppPreferencesController(
          storage: await LocalAppPreferencesStore.open(p.database),
        );
        final recurring = await openSession(p);
        final receipts = await openEvidenceSession(p);
        final draft = (await prefs.openWorkDisplayDraft(
          initial: const WorkDisplayPreferences(),
        ))!;
        await draft.session.close();
        return (
          dir: dir,
          p: p,
          operations: operations,
          prefs: prefs,
          recurring: recurring,
          receipts: receipts,
        );
      }))!;
      DraftRecoveryHub<Object>? observed;
      var view = AppViewMode.technician;
      Future<void> mount(AppPreferencesController preferences, bool wide) =>
          tester.pumpWidget(
            ApplicationRecoveryHost(
              operations: fixture.operations,
              preferences: preferences,
              receipts: fixture.receipts,
              recurring: fixture.recurring,
              view: () => view,
              child: Builder(
                builder: (context) {
                  observed = ApplicationRecoveryScope.maybeOf(context);
                  return SizedBox(width: wide ? 1200 : 320);
                },
              ),
            ),
          );
      AppPreferencesController? replacement;
      try {
        await mount(fixture.prefs, false);
        final original = observed!;
        final listing = (await tester.runAsync(original.list))!;
        expect(listing.isComplete, isTrue);
        final selected = listing.entries.single;
        expect(selected.providerId, 'preferences');
        view = AppViewMode.admin;
        await mount(fixture.prefs, true);
        expect(identical(observed, original), isTrue);
        await tester.runAsync(() async {
          final resumed =
              await original.resume(selected) as ResumedWorkPreferences;
          await resumed.close();
        });
        replacement = (await tester.runAsync(
          () async => AppPreferencesController(
            storage: await LocalAppPreferencesStore.open(fixture.p.database),
          ),
        ))!;
        await mount(replacement, false);
        expect(identical(observed, original), isFalse);
        await expectLater(original.list(), throwsStateError);
        await expectLater(original.resume(selected), throwsStateError);
        await expectLater(original.discard(selected), throwsStateError);
        final current = observed!;
        expect((await tester.runAsync(current.list))!.entries, hasLength(1));
        await tester.pumpWidget(const SizedBox.shrink());
        await expectLater(current.list(), throwsStateError);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        fixture.prefs.dispose();
        replacement?.dispose();
        fixture.operations.dispose();
        fixture.operations.workSession?.dispose();
        fixture.operations.directorySession?.dispose();
        fixture.operations.workdaySession?.dispose();
        fixture.operations.dayNoteSession?.dispose();
        await tester.runAsync(() async {
          await fixture.p.close();
          await fixture.dir.delete(recursive: true);
        });
      }
    },
  );
}
