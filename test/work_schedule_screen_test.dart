import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_schedule_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 430.0, 1280.0]) {
    testWidgets(
      'schedule shows only overlapping jobs at $width without overflow',
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
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: WorkScheduleScreen(initialDay: day),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Overnight job'), findsOneWidget);
        expect(find.text('Tomorrow only'), findsNothing);
        expect(find.text('Needs a date'), findsOneWidget);
        expect(find.byTooltip('Scheduling settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
