import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_availability.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_schedule_openings.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'save rejects a booking hidden from the employee and preserves records',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      WorkRecord job(String id, String creator, int hour, int buffer) =>
          WorkRecord(
            id: id,
            kind: WorkRecordKind.job,
            number: id,
            title: 'Service',
            client: 'Customer',
            detail: 'Service',
            pricing: WorkPricingModel.flatRate,
            createdByEmployeeId: creator,
            vehicle: 'Truck',
            scheduledStart: DateTime(2030, 1, 1, hour),
            scheduledEnd: DateTime(2030, 1, 1, hour + 1),
            scheduleBufferMinutes: buffer,
          );
      final hidden = job('hidden', 'owner', 9, 30);
      await repository.commit(
        organizationId: 'business',
        commandId: 'seed-hidden',
        actorEmployeeId: 'owner',
        permissionRevision: 'seed',
        occurredAt: DateTime(2030),
        mutations: [
          WorkRecordMutation(record: hidden, expectedStorageRevision: 0),
        ],
      );
      final work = await WorkPersistenceSession.open(
        repository,
        WorkSessionPermissions(
          organizationId: 'business',
          actorEmployeeId: 'employee',
          permissionRevision: '1',
          visibleCreatorIds: {'employee'},
          editableKinds: {WorkRecordKind.job},
          canScheduleJobs: true,
          canAssignJobs: true,
        ),
      );
      addTearDown(work.dispose);
      expect(work.records, isEmpty);
      final candidate = job('candidate', 'employee', 10, 30);
      expect(await work.create(candidate), isFalse);
      expect(work.failureMessage, contains('too close'));
      expect(work.records, isEmpty);
      final openings = await work.findJobOpenings(
        job: candidate,
        windows: [
          JobScheduleWindow(DateTime(2030, 1, 1, 10), DateTime(2030, 1, 1, 17)),
        ],
      );
      expect(openings.first.start, DateTime(2030, 1, 1, 10, 30));
      expect(
        await work.create(
          candidate.copyWith(
            scheduledStart: openings.first.start,
            scheduledEnd: openings.first.end,
          ),
        ),
        isTrue,
        reason: work.failureMessage,
      );
      expect(work.records.single.scheduleBufferMinutes, 30);
    },
  );
  for (final allowed in [false, true]) {
    test(
      'scheduling authority $allowed is independent of editing notes',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        final repository = SqliteWorkRepository(await harness.open());
        final start = DateTime(2030, 1, 1, 9);
        final job = WorkRecord(
          id: 'job',
          kind: WorkRecordKind.job,
          number: 'JOB-1',
          title: 'Repair',
          client: 'Customer',
          detail: 'Repair',
          pricing: WorkPricingModel.flatRate,
          createdByEmployeeId: 'employee',
          scheduledStart: start,
          scheduledEnd: start.add(const Duration(hours: 1)),
        );
        await repository.commit(
          organizationId: 'business',
          commandId: 'seed',
          actorEmployeeId: 'owner',
          permissionRevision: 'seed',
          occurredAt: start,
          mutations: [
            WorkRecordMutation(record: job, expectedStorageRevision: 0),
          ],
        );
        final work = await WorkPersistenceSession.open(
          repository,
          WorkSessionPermissions(
            organizationId: 'business',
            actorEmployeeId: 'employee',
            permissionRevision: '1',
            visibleCreatorIds: {'employee'},
            editableKinds: {WorkRecordKind.job},
            canScheduleJobs: allowed,
          ),
        );
        addTearDown(work.dispose);
        expect(
          await work.update(job.copyWith(jobNotes: 'Arrived at site')),
          isTrue,
        );
        final updated = work.records.single.copyWith(
          scheduledStart: start.add(const Duration(hours: 2)),
          scheduledEnd: start.add(const Duration(hours: 3)),
        );
        expect(
          await work.update(updated),
          allowed,
          reason: work.failureMessage,
        );
        if (!allowed) {
          await expectLater(
            work.openJobScheduleDraft(job.id),
            throwsStateError,
          );
        } else {
          final invalid = work.records.single.copyWith(scheduledEnd: start);
          expect(await work.update(invalid), isFalse);
        }
        final persisted = (await repository.query(
          organizationId: 'business',
          visibleCreatorIds: {'employee'},
        )).single.record;
        expect(persisted.jobNotes, 'Arrived at site');
        expect(
          persisted.scheduledStart,
          allowed ? start.add(const Duration(hours: 2)) : start,
        );
      },
    );
  }
}
