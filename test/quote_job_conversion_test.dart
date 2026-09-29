import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'support/storage/database_harness.dart';

void main() {
  test(
    'accepted quote becomes exactly one job atomically after draft recovery',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final quote = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(quote), isTrue);
      final approved = quote.recordCustomerApproval(
        WorkCustomerApproval(
          method: CustomerApprovalMethod.verbal,
          customerName: quote.client,
          recordedByEmployeeId: work.permissions.actorEmployeeId,
          recordedOn: DateTime.now().toUtc(),
          revision: quote.revision,
        ),
      );
      expect(await work.update(approved), isTrue);
      var draft = await work.openJobDraft(sourceEstimateId: quote.id);
      draft.updateInput(
        JobDraftInput(
          jobId: 'quote-job',
          number: 'Job 1',
          sourceEstimate: approved,
          sourceStorageRevision: work.storageRevisionFor(quote.id),
          scheduledStart: DateTime(2026, 10, 1, 9),
          scheduledEnd: DateTime(2026, 10, 1, 11),
          client: approved.client,
          location: '12 Example Street',
          assignee: null,
          vehicle: null,
          pricing: approved.pricing,
          items: approved.items,
          pendingLineItem: null,
          title: approved.title,
          scope: approved.detail,
          notes: 'Customer prefers morning.',
        ),
      );
      await draft.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final recovered = await WorkPrimaryDraftRecovery(work).list();
      expect(recovered, hasLength(1));
      draft = await work.openJobDraft(sourceEstimateId: quote.id);
      work.validateJobHandoff(draft, sourceEstimateId: quote.id);
      await db.customStatement(
        "CREATE TRIGGER reject_quote_job BEFORE INSERT ON local_records WHEN NEW.record_id = 'quote-job' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      expect(await draft.confirm(), isNull);
      expect(work.records.single.resolvedEstimateStage, EstimateStage.approved);
      expect(draft.recoveredInput, isNotNull);
      await db.customStatement('DROP TRIGGER reject_quote_job');
      final job = (await draft.confirm())!;
      expect(job.kind, WorkRecordKind.job);
      expect(job.sourceId, quote.id);
      expect(job.client, quote.client);
      expect(job.total, quote.total);
      expect(job.detail, quote.detail);
      expect(job.terms, quote.terms);
      expect(
        work.records.singleWhere((r) => r.id == quote.id).resolvedEstimateStage,
        EstimateStage.converted,
      );
      expect(
        await work.createJobFromApprovedEstimate(
          job: decodeWorkRecord({
            ...encodeWorkRecord(job),
            'id': 'duplicate-job',
          }),
          expectedSourceStorageRevision: work.storageRevisionFor(quote.id),
          expectedSourceDocumentRevision: quote.revision,
        ),
        isFalse,
      );
      expect(await work.update(approved), isFalse);
      await draft.session.close();
      final standaloneConversion = approved.withEstimateStage(
        EstimateStage.converted,
        DateTime.now(),
      );
      // A fresh accepted quote cannot simply disappear into a converted state without its job.
      final other = buildConfirmedEstimate(
        quoteInput(
          work.permissions.actorEmployeeId,
          id: 'quote-2',
          number: 'Quote 2',
        ),
        now: DateTime.now(),
      );
      expect(await work.create(other), isTrue);
      expect(
        await work.update(
          decodeWorkRecord({
            ...encodeWorkRecord(standaloneConversion),
            'id': other.id,
            'number': other.number,
          }),
        ),
        isFalse,
      );
    },
  );
}
