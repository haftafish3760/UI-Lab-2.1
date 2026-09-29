import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';

EstimateDraftInput input(
  String actor, {
  String amount = '25.00',
  bool required = true,
  WorkRecord? base,
}) => EstimateDraftInput(
  creatorId: actor,
  number: 'Estimate 78',
  baseStorageRevision: base == null ? 0 : 1,
  title: 'Repair',
  discount: '',
  tax: '',
  terms: 'Work as described.',
  client: 'Customer',
  requiresDeposit: required,
  depositAmount: amount,
  pricing: WorkPricingModel.flatRate,
  template: 'Service standard',
  createdOn: DateTime(2026, 9, 27),
  items: const [
    WorkLineItem(
      id: 'line',
      type: WorkLineItemType.labor,
      name: 'Repair',
      quantity: 1,
      unit: 'service',
      customerPrice: 100,
    ),
  ],
  baseRecord: base,
  estimateId: 'deposit-estimate',
  scope: 'Repair fitting',
  expiresOn: DateTime(2027),
  followUpOn: null,
  proposedServiceOn: null,
  pendingLineItems: const {},
  pendingPhotos: null,
  sitePhotos: const [],
);
void main() {
  test(
    'deposit input rejects invalid precision, negative and excessive values',
    () {
      for (final amount in ['', '-1', '0', '101', 'NaN', '0.001']) {
        expect(
          () => buildConfirmedEstimate(
            input('alex', amount: amount),
            now: DateTime(2026, 9, 27),
          ),
          throwsA(isA<EstimateInputValidation>()),
        );
      }
      expect(
        buildConfirmedEstimate(
          input('alex', amount: '100'),
          now: DateTime.now(),
        ).requiredDepositCents,
        10000,
      );
      expect(
        buildConfirmedEstimate(
          input('alex', amount: 'bad', required: false),
          now: DateTime.now(),
        ).requiredDepositCents,
        0,
      );
    },
  );
  test(
    'legacy records default to no requirement and changes invalidate approval',
    () {
      final record = buildConfirmedEstimate(input('alex'), now: DateTime.now());
      final legacy = encodeWorkRecord(record)..remove('requiredDepositCents');
      expect(decodeWorkRecord(legacy).requiredDepositCents, 0);
      final approved = record.recordEstimateSignature(
        'Customer',
        DateTime.now(),
      );
      final changed = buildConfirmedEstimate(
        input('alex', amount: '30', base: approved),
        now: DateTime.now(),
      );
      expect(changed.revision, approved.revision + 1);
      expect(changed.hasCurrentCustomerApproval, isFalse);
      expect(changed.requiredDepositCents, 3000);
      expect(approved.copyWith().requiredDepositCents, 2500);
      expect(
        approved
            .withEstimateStage(EstimateStage.converted, DateTime.now())
            .requiredDepositCents,
        2500,
      );
    },
  );
  test(
    'required deposit survives draft recovery, confirmation and database restart',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      final actor = work.permissions.actorEmployeeId;
      var draft = await work.openEstimateDraft(creatorId: actor);
      final draftId = draft.session.draftId;
      draft.updateInput(input(actor));
      await draft.session.flush();
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      draft = await work.openEstimateDraft(
        creatorId: actor,
        recoveryDraftId: draftId,
      );
      expect(draft.recoveredInput!.depositAmount, '25.00');
      expect(draft.recoveredInput!.requiresDeposit, isTrue);
      final saved = await draft.confirm();
      expect(saved!.requiredDepositCents, 2500);
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      expect(
        work.records.singleWhere((r) => r.id == saved.id).requiredDepositCents,
        2500,
      );
      work.dispose();
    },
  );
}
