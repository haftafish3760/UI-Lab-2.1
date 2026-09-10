import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/job_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/job_notes_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_assignment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_materials_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';
import 'job_materials_draft_workflow_test.dart' show job;
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;

DraftAutosaveSession sessionOf(ResumedJobAction resumed) => switch (resumed) {
  ResumedJobNotes(:final controller) => controller.session,
  ResumedJobSchedule(:final controller) => controller.session,
  ResumedJobAssignment(:final controller) => controller.session,
  ResumedJobMaterials(:final controller) => controller.session,
};
Future<void> seedActions(WorkPersistenceSession work) async {
  expect(await work.create(job), isTrue);
  final notes = await work.openJobNotesDraft(job.id);
  notes.updateNotes('  Unfinished\nnotes  ');
  await notes.session.close();
  final schedule = await work.openJobScheduleDraft(job.id);
  schedule.update(
    day: DateTime(2026, 9, 10),
    hour: '',
    minute: '0',
    period: 'PM',
  );
  await schedule.session.close();
  final assignment = await work.openJobAssignmentDraft(job.id);
  assignment.updateAssignment(
    assignee: 'Unassigned',
    vehicle: 'No vehicle assigned',
  );
  await assignment.session.close();
  final materials = await work.openJobMaterialsDraft(
    job.id,
    materialPermissions: const JobWorkspacePermissions.development(),
  );
  materials.updateWorkspace(
    WorkItemsDraftInput.fromPayload(legacyItemsWorkspace()),
  );
  await materials.session.close();
}

JobActionDraftRecovery recoveryFor(WorkPersistenceSession work) =>
    JobActionDraftRecovery(
      work,
      materialPermissions: () => const JobWorkspacePermissions.development(),
    );
void main() {
  test(
    'all job actions reopen exact unfinished input independently of widget trees',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      await seedActions(work);
      final before = await recoveryFor(work).list();
      final raw = <String, Map<String, Object?>>{};
      for (final entry in before) {
        final row = (await work.drafts.find(
          organizationId: work.permissions.organizationId,
          ownerId: work.permissions.actorEmployeeId,
          domain: entry.domain,
          draftId: entry.draftId,
        ))!;
        raw[entry.domain] = work.drafts.decode(row);
      }
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final recovery = recoveryFor(work);
      final entries = await recovery.list();
      expect(entries, hasLength(4));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final session = sessionOf(await recovery.resume(entry));
        expect(session.input, raw[entry.domain]);
        expect(session.savedRevision, entry.revision);
        await session.close();
      }
      expect(work.storageRevisionFor(job.id), 1);
    },
  );
  test(
    'every selected job action refuses stale and consumed selection without recreation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      await seedActions(work);
      final recovery = recoveryFor(work);
      for (final entry in await recovery.list()) {
        Future<Object> open(int revision) {
          final selected = DraftRecoverySelection(
            domain: entry.domain,
            draftId: entry.draftId,
            revision: revision,
          );
          return switch (entry.domain) {
            'work/job-notes' => work.openJobNotesDraft(
              job.id,
              recoverySelection: selected,
            ),
            'work/job-schedule' => work.openJobScheduleDraft(
              job.id,
              recoverySelection: selected,
            ),
            'work/job-assignment' => work.openJobAssignmentDraft(
              job.id,
              recoverySelection: selected,
            ),
            _ => work.openJobMaterialsDraft(
              job.id,
              materialPermissions: const JobWorkspacePermissions.development(),
              recoverySelection: selected,
            ),
          };
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
    },
  );
  test(
    'material authority changes hide and protect its draft; newer job retains all conflicts',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      await seedActions(work);
      var permission = const JobWorkspacePermissions.development();
      final recovery = JobActionDraftRecovery(
        work,
        materialPermissions: () => permission,
      );
      final selected = await recovery.list();
      final materials = selected.singleWhere(
        (e) => e.domain == 'work/job-materials',
      );
      permission = const JobWorkspacePermissions(
        canEditJob: true,
        canViewEstimate: false,
        canAddMaterials: false,
        canAttachReceipts: false,
        canChangeStatus: false,
        canContactCustomer: false,
      );
      expect(await recovery.list(), hasLength(3));
      await expectLater(recovery.resume(materials), throwsStateError);
      await expectLater(recovery.discard(materials), throwsStateError);
      permission = const JobWorkspacePermissions.development();
      expect(
        await work.update(job.copyWith(jobNotes: 'Newer confirmed notes')),
        isTrue,
      );
      final conflicts = await recovery.list();
      expect(conflicts, hasLength(4));
      for (final entry in conflicts) {
        expect(entry.preview.availability, DraftRecoveryAvailability.conflict);
        await expectLater(recovery.resume(entry), throwsStateError);
      }
      expect(await recovery.list(), hasLength(4));
    },
  );
}
