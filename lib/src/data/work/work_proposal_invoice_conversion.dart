part of 'work_persistence_session.dart';

extension WorkProposalInvoiceConversion on WorkPersistenceSession {
  /// Creates an unissued invoice and consumes the accepted proposal together.
  /// Issuing, payment, and invoice signatures remain separate explicit actions.
  Future<WorkRecord?> createInvoiceFromApprovedProposal({
    required String sourceId,
    required int expectedSourceStorageRevision,
    required DateTime invoiceDate,
  }) async {
    final source = _records[sourceId];
    if (source == null ||
        !source.isProposal ||
        source.resolvedEstimateStage != EstimateStage.approved ||
        !source.hasCurrentCustomerApproval ||
        !source.companyReviewAllowsCustomerApproval ||
        !permissions.canEdit(source) ||
        !permissions.editableKinds.contains(WorkRecordKind.invoice)) {
      await _reject(
        'Open a currently approved estimate or quote to create its invoice.',
      );
      return null;
    }
    final day = DateTime(invoiceDate.year, invoiceDate.month, invoiceDate.day);
    final invoice = WorkRecord(
      id: newLocalRecordIdentity('invoice'),
      kind: WorkRecordKind.invoice,
      number: await nextDocumentNumber(WorkRecordKind.invoice),
      createdByEmployeeId: permissions.actorEmployeeId,
      sourceId: source.id,
      title: source.title,
      client: source.client,
      customerSnapshot: source.customerSnapshot,
      detail: source.detail,
      purchaseOrderNumber: source.purchaseOrderNumber,
      pricing: source.pricing,
      documentPresentation: source.documentPresentation,
      items: List.unmodifiable(source.items),
      sitePhotos: List.unmodifiable(source.sitePhotos),
      serviceLocation: source.serviceLocation,
      template: source.template,
      terms: source.terms,
      discount: source.discount,
      tax: source.tax,
      total: source.total,
      status: WorkRecordStatus.draft,
      createdOn: day,
      issuedOn: day,
      dueOn: day.add(const Duration(days: 14)),
      requiresInvoiceApproval: permissions.requiresInvoiceApproval,
    );
    final saved = await save(
      records: [
        invoice,
        source.withEstimateStage(EstimateStage.converted, DateTime.now()),
      ],
      expectedStorageRevisions: {
        invoice.id: 0,
        source.id: expectedSourceStorageRevision,
      },
    );
    return saved ? invoice : null;
  }
}
