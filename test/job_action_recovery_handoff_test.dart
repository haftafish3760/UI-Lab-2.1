import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/job_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/job_details_recovery_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_notes_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/job_notes_editor_dialog.dart';
import 'package:ui_lab_2_1/src/screens/work/job_schedule_editor_sheet.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final schedule in [false, true]) {
    for (final mismatch in [false, true]) {
      testWidgets(
        'job action schedule=$schedule mismatch=$mismatch preserves draft',
        (tester) async {
          final harness = (await tester.runAsync(DatabaseHarness.create))!;
          final work = (await tester.runAsync(
            () async => openSeededTestWorkSession(await harness.open()),
          ))!;
          final job = work.records.firstWhere(
            (r) => r.kind == WorkRecordKind.job && work.permissions.canEdit(r),
          );
          final notes = schedule
              ? null
              : (await tester.runAsync(() => work.openJobNotesDraft(job.id)))!;
          final timing = schedule
              ? (await tester.runAsync(
                  () => work.openJobScheduleDraft(job.id),
                ))!
              : null;
          final session = notes?.session ?? timing!.session;
          await tester.runAsync(() async {
            notes?.updateNotes('Unfinished note');
            timing?.update(
              day: DateTime(2030, 1, 2),
              hour: '',
              minute: '0',
              period: 'PM',
            );
            await session.flush();
          });
          final revision = work.storageRevisionFor(job.id);
          final target = mismatch
              ? work.records.firstWhere((r) => r.id != job.id)
              : job;
          final store = PrototypeOperationsStore(workSession: work);
          Future<void>? route;
          try {
            await tester.pumpWidget(
              PrototypeOperationsScope(
                store: store,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: mismatch
                      ? Scaffold(
                          body: schedule
                              ? JobScheduleEditorSheet(
                                  record: target,
                                  work: work,
                                  recoveredWorkflow: timing,
                                )
                              : JobNotesEditorDialog(
                                  record: target,
                                  work: work,
                                  recoveredWorkflow: notes,
                                ),
                        )
                      : Builder(
                          builder: (context) => Scaffold(
                            body: TextButton(
                              onPressed: () => route = openJobDetailsRecovery(
                                context,
                                schedule
                                    ? ResumedJobSchedule(timing!)
                                    : ResumedJobNotes(notes!),
                              ),
                              child: const Text('Resume job action'),
                            ),
                          ),
                        ),
                ),
              ),
            );
            if (!mismatch) await tester.tap(find.text('Resume job action'));
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
              final field = find.byWidgetPredicate(
                (w) =>
                    w is TextField &&
                    w.decoration?.labelText ==
                        (schedule ? 'Hour' : 'Notes for this job'),
              );
              expect(
                tester.widget<TextField>(field).controller!.text,
                schedule ? '' : 'Unfinished note',
              );
              await tester.enterText(field, schedule ? '1' : 'Continued note');
              await finishNativeOperation(tester, session.flush);
            }
            if (!mismatch) {
              final keep = find.text(
                schedule ? 'Keep unfinished schedule' : 'Keep unfinished notes',
              );
              await tester.ensureVisible(keep);
              await tester.pumpAndSettle();
              await tester.tap(keep);
              await finishNativeOperation(tester, () => route!);
              expect(find.text('Resume job action'), findsOneWidget);
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await finishNativeOperation(tester, session.close);
            final saved = await tester.runAsync(
              () => work.drafts.find(
                organizationId: session.organizationId,
                domain: session.domain,
                draftId: session.draftId,
                ownerId: session.ownerId,
              ),
            );
            expect(
              jsonDecode(saved!.payload)[schedule ? 'hour' : 'notes'],
              mismatch
                  ? (schedule ? '' : 'Unfinished note')
                  : (schedule ? '1' : 'Continued note'),
            );
            expect(work.storageRevisionFor(job.id), revision);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await finishNativeOperation(tester, session.close);
            store.dispose();
            work.dispose();
            await tester.runAsync(harness.dispose);
          }
        },
      );
    }
  }
}
