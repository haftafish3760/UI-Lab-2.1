import 'package:ui_lab_2_1/src/screens/dashboard/day_note_recovery_route.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/day_note_editor_dialog.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets('selected day note date mismatch=$mismatch preserves input', (
      tester,
    ) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final notes = (await tester.runAsync(
        () async => openUiLabDayNotes(await harness.open()),
      ))!;
      final day = DateTime(2030, 1, 2);
      final workflow = (await tester.runAsync(
        () => notes.openDraft(date: day, employeeId: 'alex'),
      ))!;
      await tester.runAsync(() async {
        workflow.update(text: 'Unfinished day record', timeMinutes: 581);
        await workflow.session.flush();
      });
      Future<void>? route;
      final count = notes.records.length;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: !mismatch
                ? Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => route = openDayNoteRecovery(
                          context,
                          workflow,
                          session: notes,
                          employeeLabel: 'Alex',
                        ),
                        child: const Text('Resume day note'),
                      ),
                    ),
                  )
                : DayNoteEditorDialog(
                    session: notes,
                    date: mismatch ? day.add(const Duration(days: 1)) : day,
                    employeeId: 'alex',
                    employeeLabel: 'Alex',
                    recoveredWorkflow: workflow,
                  ),
          ),
        );
        if (!mismatch) await tester.tap(find.text('Resume day note'));
        await tester.pumpAndSettle();
        if (mismatch) {
          await waitForNativeSave(
            tester,
            () => find
                .textContaining('could not be opened')
                .evaluate()
                .isNotEmpty,
          );
        } else {
          final field = find.byKey(const ValueKey('day-note-description'));
          await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Unfinished day record',
          );
          await tester.enterText(field, 'Continued day record');
          await finishNativeOperation(tester, workflow.session.flush);
        }
        if (!mismatch) {
          await tester.ensureVisible(find.text('Keep unfinished'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Keep unfinished'));
          await finishNativeOperation(tester, () => route!);
          expect(find.text('Resume day note'), findsOneWidget);
        }
        expect(notes.records.length, count);
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        final saved = await tester.runAsync(
          () => notes.drafts.find(
            organizationId: workflow.session.organizationId,
            domain: workflow.session.domain,
            draftId: workflow.session.draftId,
            ownerId: workflow.session.ownerId,
          ),
        );
        final raw = jsonDecode(saved!.payload);
        expect(
          raw['text'],
          mismatch ? 'Unfinished day record' : 'Continued day record',
        );
        expect(raw['date'], '2030-01-02');
        expect(raw['timeMinutes'], 581);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        notes.dispose();
        await tester.runAsync(harness.dispose);
      }
    });
  }
}
