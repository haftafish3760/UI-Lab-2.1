import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'company setting is inherited by new estimates and blocks sending until approval',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final directory = await openUiLabDirectory(db);
      final work = await openUiLabWorkSession(db);
      addTearDown(directory.dispose);
      addTearDown(work.dispose);
      expect(
        await directory.saveCompany(
          demoWorkCompany.copyWith(requireEstimateApproval: true),
        ),
        isTrue,
      );
      final draft = await work.openEstimateDraft(
        creatorId: work.permissions.actorEmployeeId,
      );
      addTearDown(draft.session.close);
      final now = DateTime.now();
      draft.updateInput(
        EstimateDraftInput(
          creatorId: work.permissions.actorEmployeeId,
          number: 'Estimate 7001',
          baseStorageRevision: 0,
          title: 'Repair',
          discount: '0',
          tax: '0',
          terms: 'Reviewed company terms',
          client: 'Avery Wilson',
          pricing: WorkPricingModel.flatRate,
          template: 'print-v1',
          createdOn: now,
          items: const [
            WorkLineItem(
              id: 'labor',
              type: WorkLineItemType.labor,
              name: 'Repair',
              quantity: 1,
              unit: 'hour',
              customerPrice: 100,
            ),
          ],
          baseRecord: null,
          estimateId: 'policy-estimate',
          scope: 'Repair fitting',
          expiresOn: now.add(const Duration(days: 30)),
          followUpOn: null,
          proposedServiceOn: now.add(const Duration(days: 2)),
          pendingLineItems: const {},
          pendingPhotos: null,
          sitePhotos: const [],
        ),
      );
      final record = await draft.confirm();
      expect(record, isNotNull);
      expect(record!.requiresCompanyReview, isTrue);
      expect(record.companyReviewAllowsCustomerApproval, isFalse);
      final delivery = EstimateDeliveryInput.initial(
        record,
        baseRevision: 1,
        customers: const [],
      ).withRecipient('customer@example.test').withReviewed(true).prepare();
      expect(delivery.confirmedRecord, throwsStateError);
    },
  );

  test(
    'delivery preparation leaves original draft unchanged and never claims delivery',
    () {
      const draft = WorkRecord(
        id: 'draft',
        kind: WorkRecordKind.estimate,
        number: 'Estimate 7002',
        title: 'Repair',
        client: 'Jordan Patel',
        detail: 'Repair fitting',
        pricing: WorkPricingModel.flatRate,
        items: [
          WorkLineItem(
            id: 'labor',
            type: WorkLineItemType.labor,
            name: 'Repair',
            quantity: 1,
            unit: 'hour',
            customerPrice: 100,
          ),
        ],
        total: 100,
      );
      final input = EstimateDeliveryInput.initial(
        draft,
        baseRevision: 1,
        customers: const [],
      );
      expect(draft.resolvedEstimateStage, EstimateStage.draft);
      final prepared = input
          .withRecipient('customer@example.test')
          .withReviewed(true)
          .prepare()
          .confirmedRecord();
      expect(prepared.resolvedEstimateStage, EstimateStage.readyToSend);
      expect(prepared.estimateDates?.sentOn, isNull);
      expect(draft.resolvedEstimateStage, EstimateStage.draft);
    },
  );
}
