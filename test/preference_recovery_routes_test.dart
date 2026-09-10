import 'package:flutter_test/flutter_test.dart';
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

import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/shared/preference_draft_recovery.dart';
import 'package:ui_lab_2_1/src/shell/application_recovery_routes.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'support/storage/native_widget_pump.dart';

Future<ResumedPreferenceDraft> openDraft(
  AppPreferencesController owner,
  String kind,
) async {
  switch (kind) {
    case 'work':
      return ResumedWorkPreferences(
        (await owner.openWorkDisplayDraft(
          initial: const WorkDisplayPreferences(),
        ))!,
      );
    case 'receipt':
      return ResumedReceiptPreferences(
        (await owner.openReceiptDisplayDraft(
          initial: const ReceiptIntakeDisplayPreferences(),
        ))!,
      );
    case 'report':
      return ResumedReportPreferences(
        (await owner.openReportDisplayDraft(
          initial: const ReportDisplayPreferences.defaults(),
        ))!,
      );
    case 'expense':
      return ResumedExpensePreferences(
        (await owner.openExpenseDisplayDraft(
          initial: const ExpenseDisplayPreferences.defaults(),
        ))!,
      );
    default:
      return ResumedWorkListPreferences(
        kind,
        (await owner.openWorkListDisplayDraft(
          workspaceId: kind,
          initial: const WorkRecordDisplayPreferences(),
        ))!,
      );
  }
}

Future<void> openPreferenceRecovery(
  BuildContext context,
  ResumedPreferenceDraft workflow,
) => openApplicationRecovery(
  context,
  workflow,
  expensePermissions: const ExpensePermissions.development(),
  estimatePermissions: const EstimatePermissions.development(),
  materialPermissions: const JobWorkspacePermissions.development(),
  selectedDay: DateTime(2026, 9, 10),
  employeeLabel: (id) => id,
);

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
    for (final wrongStore in [false, true]) {
      testWidgets(
        '$kind recovery route retains input; wrong store: $wrongStore',
        (tester) async {
          final harness = (await tester.runAsync(DatabaseHarness.create))!;
          final db = (await tester.runAsync(harness.open))!;
          final repository = (await tester.runAsync(
            () => LocalAppPreferencesStore.open(db),
          ))!;
          final owner = AppPreferencesController(storage: repository);
          final replacement = AppPreferencesController(
            storage: (await tester.runAsync(
              () => LocalAppPreferencesStore.open(db),
            ))!,
          );
          final selected = (await tester.runAsync(
            () => openDraft(owner, kind),
          ))!;
          late BuildContext routeContext;
          Future<void>? route;
          Object? routeError;
          var finished = false;
          try {
            await tester.pumpWidget(
              AppPreferencesScope(
                controller: wrongStore ? replacement : owner,
                child: MaterialApp(
                  home: Builder(
                    builder: (context) {
                      routeContext = context;
                      return const Scaffold(body: Text('Recovery home'));
                    },
                  ),
                ),
              ),
            );
            route = openPreferenceRecovery(routeContext, selected).then(
              (_) => finished = true,
              onError: (Object error) {
                routeError = error;
                finished = true;
              },
            );
            if (wrongStore) {
              await waitForNativeSave(tester, () => finished);
              expect(routeError, isA<StateError>());
              expect(find.text('Recovery home'), findsOneWidget);
            } else {
              await waitForNativeSave(
                tester,
                () => find.byType(SwitchListTile).evaluate().isNotEmpty,
              );
              final toggle = find.byType(SwitchListTile).first;
              final oldValue = tester.widget<SwitchListTile>(toggle).value;
              await tester.tap(toggle);
              await waitForNativeSave(
                tester,
                () => find
                    .text('Draft saved on this device')
                    .evaluate()
                    .isNotEmpty,
              );
              await tester.pageBack();
              await waitForNativeSave(tester, () => finished);
              expect(routeError, isNull);
              final reopened = (await tester.runAsync(
                () => openDraft(owner, kind),
              ))!;
              finished = false;
              route = openPreferenceRecovery(
                routeContext,
                reopened,
              ).then((_) => finished = true);
              await waitForNativeSave(
                tester,
                () => find.byType(SwitchListTile).evaluate().isNotEmpty,
              );
              expect(
                tester
                    .widget<SwitchListTile>(find.byType(SwitchListTile).first)
                    .value,
                !oldValue,
              );
              await tester.pageBack();
              await waitForNativeSave(tester, () => finished);
            }
            expect(repository.values, isEmpty);
            expect(
              (await tester.runAsync(
                () => PreferenceDraftRecovery(owner).list(),
              ))!,
              hasLength(1),
            );
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await finishNativeOperation(tester, selected.close);
            if (route != null) {
              await finishNativeOperation(tester, () => route!);
            }
            owner.dispose();
            replacement.dispose();
            await tester.runAsync(harness.dispose);
          }
        },
      );
    }
  }
}
