import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'verbal approval converts atomically without signature; failed and stale conversions preserve source',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final work = await openUiLabWorkSession(db);
      addTearDown(work.dispose);
      final estimate = WorkRecord(
        id: 'approved-source',
        kind: WorkRecordKind.estimate,
        number: 'EST-TEST',
        title: 'Repair',
        client: 'Customer',
        detail: 'Approved scope',
        pricing: WorkPricingModel.flatRate,
        estimateStage: EstimateStage.approved,
        total: 50,
        items: const [
          WorkLineItem(
            id: 'labor',
            type: WorkLineItemType.labor,
            name: 'Repair',
            quantity: 1,
            unit: 'hour',
            customerPrice: 50,
          ),
        ],
        customerApprovals: [
          WorkCustomerApproval(
            method: CustomerApprovalMethod.verbal,
            customerName: 'Customer',
            recordedByEmployeeId: work.permissions.actorEmployeeId,
            recordedOn: DateTime(2026, 9, 9),
            revision: 1,
          ),
        ],
      );
      expect(await work.create(estimate), isTrue);
      WorkRecord job(String id) => WorkRecord(
        id: id,
        kind: WorkRecordKind.job,
        number: 'JOB-TEST',
        title: 'Repair',
        client: 'Customer',
        detail: 'Approved scope',
        pricing: WorkPricingModel.flatRate,
        sourceId: estimate.id,
        items: estimate.items,
        total: 50,
      );
      final revision = work.storageRevisionFor(estimate.id);
      expect(await work.create(job('non-atomic')), isFalse);
      await db.customStatement(
        "CREATE TRIGGER fail_job BEFORE INSERT ON local_records WHEN NEW.record_id = 'new-job' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(
        await work.createJobFromApprovedEstimate(
          job: job('new-job'),
          expectedSourceStorageRevision: revision,
          expectedSourceDocumentRevision: 1,
        ),
        isFalse,
      );
      expect(work.records.where((r) => r.id == 'new-job'), isEmpty);
      expect(
        work.records
            .singleWhere((r) => r.id == estimate.id)
            .resolvedEstimateStage,
        EstimateStage.approved,
      );
      await db.customStatement('DROP TRIGGER fail_job');
      final competing = await openUiLabWorkSession(await harness.open());
      addTearDown(competing.dispose);
      expect(
        await work.createJobFromApprovedEstimate(
          job: job('new-job'),
          expectedSourceStorageRevision: revision,
          expectedSourceDocumentRevision: 1,
        ),
        isTrue,
      );
      expect(
        work.records
            .singleWhere((r) => r.id == estimate.id)
            .resolvedEstimateStage,
        EstimateStage.converted,
      );
      expect(
        await work.createJobFromApprovedEstimate(
          job: job('duplicate-job'),
          expectedSourceStorageRevision: revision,
          expectedSourceDocumentRevision: 1,
        ),
        isFalse,
      );
      expect(
        await competing.createJobFromApprovedEstimate(
          job: job('stale-job'),
          expectedSourceStorageRevision: revision,
          expectedSourceDocumentRevision: 1,
        ),
        isFalse,
      );
      final reopened = await openUiLabWorkSession(await harness.open());
      addTearDown(reopened.dispose);
      expect(reopened.records.where((r) => r.id == 'stale-job'), isEmpty);
      expect(
        reopened.records.singleWhere((r) => r.id == 'new-job').sourceId,
        estimate.id,
      );
      expect(
        reopened.records
            .singleWhere((r) => r.id == estimate.id)
            .hasCurrentCustomerApproval,
        isTrue,
      );
    },
  );
}
