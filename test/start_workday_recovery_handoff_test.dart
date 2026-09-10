import 'package:ui_lab_2_1/src/data/workday/workday_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/workday_recovery_routes.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/workday/start_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'selected start input overrides current display selection without starting work',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final work = (await tester.runAsync(
        () async => openUiLabWorkdaySession(await harness.open()),
      ))!;
      final workflow = (await tester.runAsync(
        () => work.openStartDraft(
          employeeId: 'jordan',
          vehicleId: 'service-van-4',
          initialOdometer: '123.',
        ),
      ))!;
      await tester.runAsync(workflow.session.flush);
      final scope = OperationalScopeController();
      scope.setView(AppViewMode.admin);
      scope.selectEmployee('alex');
      scope.selectVehicle('transit-12');
      Future<void>? route;
      try {
        await tester.pumpWidget(
          WorkdayPersistenceScope(
            session: work,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => route = openWorkdayRecovery(
                        context,
                        ResumedWorkdayStart(workflow),
                      ),
                      child: const Text('Resume workday'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Resume workday'));
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('start-day-odometer-field'));
        await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
        expect(scope.selectedEmployeeId, 'jordan');
        expect(scope.selectedVehicleId, 'service-van-4');
        expect(workflow.input.odometer, '123.');
        await tester.enterText(field, '124.');
        await finishNativeOperation(tester, workflow.session.flush);
        await tester.ensureVisible(find.byTooltip('Back to Dashboard'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back to Dashboard'));
        await finishNativeOperation(tester, () => route!);
        expect(find.text('Resume workday'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        final saved = await tester.runAsync(
          () => work.drafts.find(
            organizationId: workflow.session.organizationId,
            domain: workflow.session.domain,
            draftId: workflow.session.draftId,
            ownerId: workflow.session.ownerId,
          ),
        );
        final raw = jsonDecode(saved!.payload);
        expect(raw['odometer'], '124.');
        expect(raw['vehicleId'], 'service-van-4');
        expect(raw['employeeId'], 'jordan');
        expect(work.records, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        scope.dispose();
        work.dispose();
        await tester.runAsync(harness.dispose);
      }
    },
  );
}
