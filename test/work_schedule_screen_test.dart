import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_schedule_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/screens/work/work_detail_header.dart';

void main() {
  testWidgets(
    'empty schedule retains navigation without empty record containers',
    (tester) async {
      final store = PrototypeOperationsStore(
        workRecords: [],
        financialEntries: [],
      );
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
              home: WorkScheduleScreen(initialDay: DateTime(2026, 9, 28)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkDetailHeader), findsOneWidget);
      expect(find.textContaining('No jobs'), findsNothing);
      expect(find.textContaining('Scheduled jobs ·'), findsNothing);
      expect(find.textContaining('Needs scheduling ·'), findsNothing);
      final waiting = find.byKey(
        const ValueKey('dashboard-summary-schedule-waiting'),
      );
      await tester.ensureVisible(waiting);
      await tester.tap(waiting);
      await tester.pumpAndSettle();
      expect(find.textContaining('Needs scheduling ·'), findsNothing);
      expect(find.byKey(const ValueKey('work-5-7-calendar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (width, textScale) in [
    (320.0, 1.5),
    (320.0, 2.0),
    (430.0, 1.5),
    (1280.0, 1.5),
  ]) {
    testWidgets(
      'schedule shows selected/all jobs at $width and ${textScale}x text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final day = DateTime(2026, 9, 14);
        WorkRecord job(String id, DateTime? start, DateTime? end) => WorkRecord(
          id: id,
          kind: WorkRecordKind.job,
          number: 'Job $id',
          title: 'Heating inspection',
          client: id,
          detail: 'Inspect equipment',
          pricing: WorkPricingModel.flatRate,
          status: WorkRecordStatus.scheduled,
          scheduledStart: start,
          scheduledEnd: end,
        );
        final store = PrototypeOperationsStore(
          workRecords: [
            job(
              'Overnight job',
              day.subtract(const Duration(hours: 1)),
              day.add(const Duration(hours: 2)),
            ),
            job(
              'Tomorrow only',
              day.add(const Duration(days: 1, hours: 9)),
              day.add(const Duration(days: 1, hours: 10)),
            ),
            job('Needs a date', null, null),
          ],
        );
        addTearDown(store.dispose);
        final preferences = AppPreferencesController();
        addTearDown(preferences.dispose);
        final scope = OperationalScopeController();
        addTearDown(scope.dispose);
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: AppPreferencesScope(
              controller: preferences,
              child: MaterialApp(
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
                home: OperationalScope(
                  controller: scope,
                  child: WorkScheduleScreen(initialDay: day),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Overnight job'), findsOneWidget);
        expect(find.text('Tomorrow only'), findsNothing);
        expect(find.text('Needs a date'), findsNothing);
        final waiting = find.byKey(
          const ValueKey('dashboard-summary-schedule-waiting'),
        );
        await tester.ensureVisible(waiting);
        await tester.tap(waiting);
        await tester.pumpAndSettle();
        expect(find.text('Needs a date'), findsOneWidget);
        expect(find.text('Overnight job'), findsNothing);
        final scheduled = find.byKey(
          const ValueKey('dashboard-summary-schedule-scheduled'),
        );
        await tester.ensureVisible(scheduled);
        await tester.tap(scheduled);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('schedule-all-jobs')),
        );
        await tester.tap(find.byKey(const ValueKey('schedule-all-jobs')));
        await tester.pumpAndSettle();
        expect(find.text('Tomorrow only'), findsOneWidget);
        expect(find.text('Scheduled jobs · all dates (2)'), findsOneWidget);
        final tomorrowLabel = MaterialLocalizations.of(
          tester.element(find.byType(WorkScheduleScreen)),
        ).formatMediumDate(day.add(const Duration(days: 1)));
        expect(find.textContaining(tomorrowLabel), findsWidgets);
        await tester.ensureVisible(
          find.byKey(const ValueKey('schedule-selected-day')),
        );
        await tester.tap(find.byKey(const ValueKey('schedule-selected-day')));
        await tester.pumpAndSettle();
        expect(find.text('Tomorrow only'), findsNothing);
        expect(find.byTooltip('Scheduling settings'), findsOneWidget);
        expect(find.byType(WorkDetailHeader), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
