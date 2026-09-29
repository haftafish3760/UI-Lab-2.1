import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'estimate_draft_workflow_test.dart' as estimate;
import 'invoice_draft_workflow_test.dart' as invoice;
import 'job_draft_workflow_test.dart' as job;
import 'support/storage/database_harness.dart';

void main() {
  test(
    'unnamed estimate and invoice drafts use the selected customer',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final e = await work.openEstimateDraft(creatorId: actor);
      e.updateInput(
        EstimateDraftInput.fromPayload({
          ...estimate.inputFor(actor).toPayload(),
          'title': '  ',
          'client': 'Estimate customer',
        }),
      );
      await e.session.close();
      final i = await work.openInvoiceDraft();
      i.updateInput(
        InvoiceDraftInput.fromPayload({
          ...invoice.inputFor(actor).toPayload(),
          'title': '',
          'client': 'Invoice customer',
        }),
      );
      await i.session.close();
      final entries = await WorkPrimaryDraftRecovery(work).list();
      expect(
        entries.map((entry) => entry.preview.title),
        containsAll(['Estimate customer', 'Invoice customer']),
      );
    },
  );

  test(
    'primary Work recovery reopens all controllers without changing raw input or records',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      final actor = work.permissions.actorEmployeeId;
      final recordsBefore = work.records.length;
      final e = await work.openEstimateDraft(creatorId: actor);
      e.updateInput(estimate.inputFor(actor));
      await e.session.close();
      final i = await work.openInvoiceDraft();
      i.updateInput(invoice.inputFor(actor));
      await i.session.close();
      final j = await work.openJobDraft();
      j.updateInput(job.inputFor(null, 0));
      await j.session.close();
      final raws = {
        e.session.domain: e.session.input,
        i.session.domain: i.session.input,
        j.session.domain: j.session.input,
      };
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      final recovery = WorkPrimaryDraftRecovery(work);
      final entries = await recovery.list();
      expect(entries, hasLength(3));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final wrong = DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: entry.revision + 1,
        );
        final attempt = switch (entry.domain) {
          'work/estimate-editor' => work.openEstimateDraft(
            creatorId: actor,
            recoverySelection: wrong,
          ),
          'work/invoice-editor' => work.openInvoiceDraft(
            recoverySelection: wrong,
          ),
          _ => work.openJobDraft(recoverySelection: wrong),
        };
        await expectLater(attempt, throwsA(isA<LocalRecordConflict>()));
        final resumed = await recovery.resume(entry);
        final session = switch (resumed) {
          ResumedQuoteDraft(:final controller) ||
          ResumedEstimateDraft(:final controller) => controller.session,
          ResumedInvoiceDraft(:final controller) => controller.session,
          ResumedJobDraft(:final controller) => controller.session,
        };
        expect(session.input, raws[entry.domain]);
        expect(session.savedRevision, entry.revision);
        await session.close();
      }
      expect(work.records, hasLength(recordsBefore));
    },
  );

  test(
    'changed and missing parents remain listed without silently rebasing input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final original = buildConfirmedInvoice(invoice.inputFor(actor));
      expect(await work.create(original), isTrue);
      final editor = await work.openInvoiceDraft(existingRecordId: original.id);
      editor.updateInput(invoice.inputFor(actor, existing: true));
      await editor.session.close();
      final recovery = WorkPrimaryDraftRecovery(work);
      final selected = (await recovery.list()).single;
      expect(
        await work.save(
          records: [
            buildConfirmedInvoice(
              InvoiceDraftInput.fromPayload({
                ...invoice.inputFor(actor).toPayload(),
                'title': 'Newer invoice',
              }),
            ),
          ],
          expectedStorageRevisions: {original.id: 1},
        ),
        isTrue,
      );
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(selected), throwsStateError);
      final orphan = {
        ...invoice.inputFor(actor, existing: true).toPayload(),
        'existingRecordId': 'missing',
        'recordId': 'missing',
      };
      await work.drafts.save(
        organizationId: work.permissions.organizationId,
        ownerId: actor,
        domain: 'work/invoice-editor',
        draftId: 'orphan',
        expectedRevision: 0,
        payload: orphan,
        occurredAt: DateTime.now(),
      );
      final missing = (await recovery.list()).singleWhere(
        (entry) => entry.draftId == 'orphan',
      );
      expect(
        missing.preview.availability,
        DraftRecoveryAvailability.parentUnavailable,
      );
      await expectLater(recovery.resume(missing), throwsStateError);
      await recovery.discard(missing);
      expect(
        work.records.singleWhere((r) => r.id == original.id).title,
        'Newer invoice',
      );
    },
  );

  test(
    'selected invoice identity wins over legacy lookup and consumed selection cannot reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final original = buildConfirmedInvoice(invoice.inputFor(actor));
      expect(await work.create(original), isTrue);
      for (final id in ['edit-${original.id}', 'edit-$actor-${original.id}']) {
        await work.drafts.save(
          organizationId: work.permissions.organizationId,
          ownerId: actor,
          domain: 'work/invoice-editor',
          draftId: id,
          expectedRevision: 0,
          payload: {
            ...invoice.inputFor(actor, existing: true).toPayload(),
            'title': id,
          },
          occurredAt: DateTime.now(),
        );
      }
      final recovery = WorkPrimaryDraftRecovery(work);
      final entry = (await recovery.list()).singleWhere(
        (e) => e.draftId == 'edit-$actor-${original.id}',
      );
      final resumed = await recovery.resume(entry) as ResumedInvoiceDraft;
      expect(resumed.controller.recoveredInput!.title, entry.draftId);
      await resumed.controller.session.close();
      await recovery.discard(entry);
      await expectLater(
        work.openInvoiceDraft(
          existingRecordId: original.id,
          recoverySelection: DraftRecoverySelection(
            domain: entry.domain,
            draftId: entry.draftId,
            revision: entry.revision,
          ),
        ),
        throwsA(isA<LocalRecordConflict>()),
      );
      expect((await recovery.list()).single.draftId, 'edit-${original.id}');
    },
  );

  test(
    'foreign creator input is hidden and malformed input stays retained',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      for (final record in [
        ('hidden', invoice.inputFor('not-visible').toPayload()),
        (
          'malformed',
          <String, Object?>{'title': 'Must not leak malformed content'},
        ),
      ]) {
        await work.drafts.save(
          organizationId: work.permissions.organizationId,
          ownerId: actor,
          domain: 'work/invoice-editor',
          draftId: record.$1,
          expectedRevision: 0,
          payload: record.$2,
          occurredAt: DateTime.now(),
        );
      }
      final recovery = WorkPrimaryDraftRecovery(work);
      final entries = await recovery.list();
      expect(entries, hasLength(1));
      expect(entries.single.draftId, 'malformed');
      expect(
        entries.single.preview.availability,
        DraftRecoveryAvailability.unreadable,
      );
      await expectLater(recovery.resume(entries.single), throwsStateError);
      expect(
        await work.drafts.list(
          organizationId: work.permissions.organizationId,
          ownerId: actor,
          domain: 'work/invoice-editor',
        ),
        hasLength(2),
      );
    },
  );
}
