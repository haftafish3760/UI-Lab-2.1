import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_app_preferences_store.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/preferences/work_record_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/preferences/receipt_intake_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/preferences/report_display_preferences.dart';
import 'package:ui_lab_2_1/src/data/preferences/expense_display_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/work_display_draft_workflow.dart';
import 'package:ui_lab_2_1/src/shared/secondary_display_draft_workflows.dart';
import 'package:ui_lab_2_1/src/shared/report_display_draft_workflow.dart';
import 'package:ui_lab_2_1/src/shared/expense_display_draft_workflow.dart';
import 'support/storage/database_harness.dart';

Future<DraftAutosaveSession> open(
  AppPreferencesController preferences,
  String kind, {
  DraftRecoverySelection? selection,
}) async {
  final workflow = switch (kind) {
    'work' => await preferences.openWorkDisplayDraft(
      initial: const WorkDisplayPreferences(),
      recoverySelection: selection,
    ),
    'receipt' => await preferences.openReceiptDisplayDraft(
      initial: const ReceiptIntakeDisplayPreferences(),
      recoverySelection: selection,
    ),
    'report' => await preferences.openReportDisplayDraft(
      initial: const ReportDisplayPreferences.defaults(),
      recoverySelection: selection,
    ),
    'expense' => await preferences.openExpenseDisplayDraft(
      initial: const ExpenseDisplayPreferences.defaults(),
      recoverySelection: selection,
    ),
    _ => await preferences.openWorkListDisplayDraft(
      workspaceId: kind,
      initial: const WorkRecordDisplayPreferences(),
      recoverySelection: selection,
    ),
  };
  return workflow!.session;
}

void main() {
  for (final kind in [
    'work',
    'receipt',
    'report',
    'expense',
    'jobs',
    'estimates',
    'invoices',
  ]) {
    test(
      '$kind selected settings survive reopen and reject stale wrong-context and consumed selections',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var db = await harness.open();
        var preferences = AppPreferencesController(
          storage: await LocalAppPreferencesStore.open(db),
        );
        final original = await open(preferences, kind);
        await original.close();
        final raw = original.input;
        final selected = DraftRecoverySelection(
          domain: original.domain,
          draftId: original.draftId,
          revision: original.savedRevision,
        );
        preferences.dispose();
        await harness.close(db);
        db = await harness.open();
        preferences = AppPreferencesController(
          storage: await LocalAppPreferencesStore.open(db),
        );
        addTearDown(preferences.dispose);
        final before = preferences.storage!.values;
        final resumed = await open(preferences, kind, selection: selected);
        expect(resumed.input, raw);
        expect(resumed.savedRevision, selected.revision);
        await resumed.close();
        for (final wrong in [
          DraftRecoverySelection(
            domain: selected.domain,
            draftId: selected.draftId,
            revision: selected.revision + 1,
          ),
          DraftRecoverySelection(
            domain: 'different-domain',
            draftId: selected.draftId,
            revision: selected.revision,
          ),
          DraftRecoverySelection(
            domain: selected.domain,
            draftId: 'different-id',
            revision: selected.revision,
          ),
        ]) {
          await expectLater(
            open(preferences, kind, selection: wrong),
            throwsA(isA<LocalRecordConflict>()),
          );
        }
        final discard = await open(preferences, kind, selection: selected);
        await discard.discard();
        await discard.close();
        await expectLater(
          open(preferences, kind, selection: selected),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(
          await preferences.storage!.drafts.find(
            organizationId: 'device',
            ownerId: 'device',
            domain: selected.domain,
            draftId: selected.draftId,
          ),
          isNull,
        );
        expect(preferences.storage!.values, before);
        final fresh = await open(preferences, kind);
        expect(fresh.input, raw);
        await fresh.close();
      },
    );
  }
}
