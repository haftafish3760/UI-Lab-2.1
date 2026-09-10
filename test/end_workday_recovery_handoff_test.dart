import 'package:ui_lab_2_1/src/data/workday/workday_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/workday_recovery_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/workday/end_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'selected ending draft retains partial mileage without ending work',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final work = (await tester.runAsync(
        () async => openUiLabWorkdaySession(await harness.open()),
      ))!;
      final start = await tester.runAsync(
        () => work.start(
          id: 'handoff-workday',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );
      expect(start!.committed, isTrue);
      final workflow = (await tester.runAsync(
        () => work.openEndDraft(
          workdayId: 'handoff-workday',
          initialOdometer: '101.',
        ),
      ))!;
      await tester.runAsync(workflow.session.flush);
      expect(
        () => work.validateEndWorkdayHandoff(workflow, 'another-workday'),
        throwsStateError,
      );
      Future<void>? route;
      try {
        await tester.pumpWidget(
          WorkdayPersistenceScope(
            session: work,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => route = openWorkdayRecovery(
                      context,
                      ResumedWorkdayEnd(workflow),
                    ),
                    child: const Text('Resume workday'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Resume workday'));
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('ending-odometer-field'));
        await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
        expect(tester.widget<TextField>(field).controller!.text, '101.');
        await tester.enterText(field, '102.');
        await finishNativeOperation(tester, workflow.session.flush);
        await tester.ensureVisible(find.text('Keep workday open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep workday open'));
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
        expect(jsonDecode(saved!.payload)['odometer'], '102.');
        expect(work.activeFor('alex'), isNotNull);
        expect(work.odometerFor('transit-12')!.readingTenths, 1000);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        work.dispose();
        await tester.runAsync(harness.dispose);
      }
    },
  );
}
