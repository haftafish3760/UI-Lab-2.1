import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/job_opening_picker.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'opening picker selects a free time at large text ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final day = DateTime(2030, 1, 1);
        WorkRecord job(String id, int hour, int end) => WorkRecord(
          id: id,
          kind: WorkRecordKind.job,
          number: id,
          title: 'Repair',
          client: 'Customer',
          detail: 'Repair',
          pricing: WorkPricingModel.flatRate,
          assignedEmployeeIds: const ['employee'],
          scheduledStart: DateTime(2030, 1, 1, hour),
          scheduledEnd: DateTime(2030, 1, 1, end),
        );
        DateTime? chosen;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    chosen = await showDialog<DateTime>(
                      context: context,
                      builder: (_) => JobOpeningPicker(
                        job: job('current', 9, 11),
                        jobs: [job('other', 9, 12)],
                        initialDay: day,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Find openings'));
        await tester.tap(find.text('Find openings'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Use time').first);
        await tester.tap(find.text('Use time').first);
        await tester.pumpAndSettle();
        expect(chosen, DateTime(2030, 1, 1, 12));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
