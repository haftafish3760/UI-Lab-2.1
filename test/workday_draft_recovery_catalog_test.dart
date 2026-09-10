import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/workday/start_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/end_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/stored_workday_record.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'start and end recovery retain raw input through reopen without starting or ending work',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkdaySession(db);
      expect(
        (await work.start(
          id: 'active-day',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        )).committed,
        isTrue,
      );
      final start = await work.openStartDraft(
        employeeId: 'jordan',
        vehicleId: 'pickup-2',
        initialOdometer: '12.',
        gpsAssistance: true,
      );
      final end = await work.openEndDraft(
        workdayId: 'active-day',
        initialOdometer: '100.',
      );
      await start.session.close();
      await end.session.close();
      final raw = {
        'workday/start': start.session.input,
        'workday/end': end.session.input,
      };
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkdaySession(db);
      addTearDown(work.dispose);
      final recovery = WorkdayDraftRecovery(work);
      final entries = await recovery.list();
      expect(entries, hasLength(2));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        final session = switch (resumed) {
          ResumedWorkdayStart(:final controller) => controller.session,
          ResumedWorkdayEnd(:final controller) => controller.session,
        };
        expect(session.input, raw[entry.domain]);
        expect(session.savedRevision, entry.revision);
        await session.close();
        Future<Object> open(int revision) {
          final selected = DraftRecoverySelection(
            domain: entry.domain,
            draftId: entry.draftId,
            revision: revision,
          );
          return entry.domain == 'workday/start'
              ? work.openStartDraft(
                  employeeId: 'jordan',
                  vehicleId: 'pickup-2',
                  initialOdometer: '0',
                  recoverySelection: selected,
                )
              : work.openEndDraft(
                  workdayId: 'active-day',
                  initialOdometer: '0',
                  recoverySelection: selected,
                );
        }

        await expectLater(
          open(entry.revision + 1),
          throwsA(isA<LocalRecordConflict>()),
        );
        await recovery.discard(entry);
        await expectLater(
          open(entry.revision),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      expect(await recovery.list(), isEmpty);
      expect(work.records, hasLength(1));
      expect(work.activeFor('alex'), isNotNull);
      expect(work.activeFor('jordan'), isNull);
    },
  );
  test(
    'fresh reads detect occupied start context and ending revision or closed parent',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final work = await openUiLabWorkdaySession(db);
      addTearDown(work.dispose);
      final start = await work.openStartDraft(
        employeeId: 'alex',
        vehicleId: 'transit-12',
        initialOdometer: '100.',
      );
      await start.session.close();
      final recovery = WorkdayDraftRecovery(work);
      final startEntry = (await recovery.list()).single;
      expect(
        startEntry.preview.availability,
        DraftRecoveryAvailability.recoverable,
      );
      final other = await openUiLabWorkdaySession(db);
      addTearDown(other.dispose);
      expect(
        (await other.start(
          id: 'other-start',
          employeeId: 'alex',
          vehicleId: 'transit-12',
          odometerTenths: 1000,
          expectedOdometerRevision: 0,
          at: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        )).committed,
        isTrue,
      );
      expect(work.records, isEmpty);
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(startEntry), throwsStateError);
      expect(await work.reload(), isTrue);
      final end = await work.openEndDraft(
        workdayId: 'other-start',
        initialOdometer: '110.',
      );
      await end.session.close();
      final endEntry = (await recovery.list()).singleWhere(
        (e) => e.domain == 'workday/end',
      );
      expect(
        endEntry.preview.availability,
        DraftRecoveryAvailability.recoverable,
      );
      await other.repository.change(
        id: 'other-start',
        expectedRevision: 1,
        at: DateTime.now().toUtc(),
        access: other.access,
        status: StoredWorkdayStatus.ended,
        endingOdometerTenths: 1100,
        expectedOdometerRevision: 1,
      );
      expect(work.activeFor('alex'), isNotNull);
      expect(
        (await recovery.list())
            .singleWhere((e) => e.domain == 'workday/end')
            .preview
            .availability,
        DraftRecoveryAvailability.parentUnavailable,
      );
      await expectLater(recovery.resume(endEntry), throwsStateError);
      expect(await recovery.list(), hasLength(2));
    },
  );
}
