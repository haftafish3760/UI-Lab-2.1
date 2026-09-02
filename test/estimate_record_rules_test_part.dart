part of 'estimate_lifecycle_test.dart';

void registerEstimateRecordRuleTests() {
  test(
    'estimate calendar activity includes follow-up without changing filing identity',
    () {
      final estimate = _estimate(createdOn: DateTime(2026, 8, 1));
      expect(estimate.occursOn(DateTime(2026, 8, 1)), isTrue);
      expect(estimate.occursOn(DateTime(2026, 8, 3)), isTrue);
      expect(estimate.occursOn(DateTime(2026, 8, 4)), isFalse);
      expect(estimate.id, 'estimate-test');
    },
  );

  test('estimate actions cannot be granted without view permission', () {
    expect(
      () => EstimatePermissions(
        canView: false,
        canCreate: true,
        canEditItems: false,
        canSend: false,
        canCollectSignature: false,
        canConvertToJob: false,
        canViewEstimateTotals: false,
        canViewInternalCosts: false,
      ),
      throwsAssertionError,
    );
  });

  test('prepared delivery does not falsely mark an estimate as sent', () {
    final estimate = _estimate();
    final prepared = estimate.recordEstimateDelivery(
      method: EstimateDeliveryMethod.email,
      recipient: 'customer@example.com',
      occurredOn: DateTime(2026, 8, 30, 10),
    );

    expect(prepared.resolvedEstimateStage, EstimateStage.readyToSend);
    expect(prepared.estimateDates?.sentOn, isNull);
    expect(
      prepared.estimateDeliveries.single.description,
      contains('not confirmed'),
    );

    final delivered = estimate.recordEstimateDelivery(
      method: EstimateDeliveryMethod.email,
      recipient: 'customer@example.com',
      occurredOn: DateTime(2026, 8, 30, 10),
      confirmedDelivered: true,
    );
    expect(delivered.resolvedEstimateStage, EstimateStage.awaitingCustomer);
    expect(delivered.estimateDates?.sentOn, isNotNull);
  });

  test('customer signature approves only the current revision', () {
    final approved = _estimate().recordEstimateSignature(
      'Maya Thompson',
      DateTime(2026, 8, 30, 11),
    );
    expect(approved.resolvedEstimateStage, EstimateStage.approved);
    expect(approved.hasCurrentCustomerSignature, isTrue);

    final changed = approved.reviseItems(const [
      WorkLineItem(
        id: 'changed-line',
        type: WorkLineItemType.material,
        name: 'Added fitting',
        quantity: 1,
        unit: 'item',
        customerPrice: 1,
      ),
    ], changedOn: DateTime(2026, 8, 30, 12));
    expect(changed.revision, 2);
    expect(changed.hasCurrentCustomerSignature, isFalse);
    expect(changed.resolvedEstimateStage, EstimateStage.readyToSend);
    expect(changed.estimateRevisionHistory.single.customerApproved, isTrue);
  });

  test('editing customer-visible estimate details requires approval again', () {
    final approved = _estimate().recordEstimateSignature(
      'Maya Thompson',
      DateTime(2026, 8, 30, 11),
    );
    final dates = approved.estimateDates!;
    final revised = approved.reviseEstimate(
      title: approved.title,
      client: approved.client,
      scope: '${approved.detail} Includes disposal.',
      pricing: approved.pricing,
      items: approved.items,
      template: approved.template,
      terms: approved.terms,
      discount: approved.discount,
      tax: approved.tax,
      dates: dates,
      changedOn: DateTime(2026, 8, 30, 12),
    );
    expect(revised.revision, approved.revision + 1);
    expect(revised.hasCurrentCustomerSignature, isFalse);
    expect(revised.resolvedEstimateStage, EstimateStage.readyToSend);
    expect(revised.detail, contains('Includes disposal'));
  });

  test(
    'company review permits delivery without recording customer approval',
    () {
      final pending = WorkRecord(
        id: 'company-review',
        kind: WorkRecordKind.estimate,
        number: 'EST-REVIEW',
        title: 'Panel replacement estimate',
        client: 'Jordan Miller',
        detail: 'Replace the damaged electrical panel.',
        pricing: WorkPricingModel.flatRate,
        status: WorkRecordStatus.ready,
        items: const [
          WorkLineItem(
            id: 'panel-labor',
            type: WorkLineItemType.labor,
            name: 'Panel replacement labor',
            quantity: 8,
            unit: 'hours',
            customerPrice: 125,
          ),
        ],
        total: 1000,
        estimateStage: EstimateStage.readyToSend,
        requiresCompanyReview: true,
        estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
      );

      expect(
        () => pending.recordEstimateDelivery(
          method: EstimateDeliveryMethod.email,
          recipient: 'customer@example.com',
          occurredOn: DateTime(2026, 8, 30),
        ),
        throwsStateError,
      );
      final approved = pending.recordCompanyReview(
        decision: EstimateCompanyReviewDecision.approved,
        reviewedBy: 'Company reviewer',
        note: 'Revision 1 approved for customer delivery.',
        reviewedOn: DateTime(2026, 8, 30),
      );
      expect(approved.companyReviewAllowsCustomerApproval, isTrue);
      expect(approved.hasCurrentCustomerSignature, isFalse);
      expect(approved.resolvedEstimateStage, EstimateStage.readyToSend);
    },
  );

  test(
    'editing an internally approved estimate requires company review again',
    () {
      final reviewed = WorkRecord(
        id: 'reviewed-estimate',
        kind: WorkRecordKind.estimate,
        number: 'EST-REVIEWED',
        title: 'Reviewed estimate',
        client: 'Jordan Miller',
        detail: 'Replace the existing fixture.',
        pricing: WorkPricingModel.flatRate,
        status: WorkRecordStatus.ready,
        items: const [
          WorkLineItem(
            id: 'original',
            type: WorkLineItemType.material,
            name: 'Replacement fixture',
            quantity: 1,
            unit: 'item',
            customerPrice: 200,
          ),
        ],
        total: 200,
        estimateStage: EstimateStage.readyToSend,
        requiresCompanyReview: true,
        estimateCompanyReviewStatus: EstimateCompanyReviewStatus.approved,
      );
      final revised = reviewed.reviseItems(const [
        WorkLineItem(
          id: 'original',
          type: WorkLineItemType.material,
          name: 'Replacement fixture',
          quantity: 1,
          unit: 'item',
          customerPrice: 225,
        ),
      ], changedOn: DateTime(2026, 8, 30));

      expect(
        revised.estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.changesRequested,
      );
      expect(revised.companyReviewAllowsCustomerApproval, isFalse);
    },
  );
}
