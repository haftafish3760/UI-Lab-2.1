import 'models/estimate_models.dart';
import 'job_draft_controller.dart';
import 'models/work_models.dart';

class JobInputValidation implements Exception {
  const JobInputValidation(this.message);
  final String message;
}

/// Domain rules shared by every presentation of the job creation workflow.
WorkRecord buildConfirmedJob(
  JobDraftInput input, {
  required String actorEmployeeId,
  required DateTime now,
}) {
  if (input.pendingLineItem != null) {
    throw const JobInputValidation(
      'Review and save the unfinished job items first.',
    );
  }
  final source = input.sourceEstimate;
  if (source != null &&
      (source.resolvedEstimateStage != EstimateStage.approved ||
          !source.hasCurrentCustomerApproval)) {
    throw const JobInputValidation(
      'This estimate or quote revision is not currently customer-approved.',
    );
  }
  if (input.title.trim().isEmpty ||
      input.client == null ||
      input.location == null) {
    throw const JobInputValidation(
      'Enter a job title, choose a client, and choose a service location.',
    );
  }
  if (!input.scheduledEnd.isAfter(input.scheduledStart)) {
    throw const JobInputValidation('Expected end must be after the job start.');
  }
  return WorkRecord(
    id: input.jobId,
    createdByEmployeeId: actorEmployeeId,
    kind: WorkRecordKind.job,
    number: input.number,
    purchaseOrderNumber: input.purchaseOrderNumber.trim(),
    title: input.title.trim(),
    client: input.client!,
    customerSnapshot: source?.customerSnapshot,
    sitePhotos: List.unmodifiable(source?.sitePhotos ?? const []),
    detail: input.scope.trim(),
    pricing: input.pricing,
    documentPresentation:
        source?.documentPresentation ?? WorkDocumentPresentation.detailed,
    template: source?.template ?? 'Service standard',
    terms: source?.terms ?? '',
    discount: source?.discount ?? 0,
    tax: source?.tax ?? 0,
    sourceId: source?.id,
    assignee: input.assignee,
    assignedEmployeeIds: List.unmodifiable(input.assignedEmployeeIds),
    vehicle: input.vehicle,
    serviceLocation: input.location!,
    jobNotes: input.notes.trim(),
    createdOn: DateTime(now.year, now.month, now.day),
    scheduledStart: input.scheduledStart,
    scheduledEnd: input.scheduledEnd,
    scheduleBufferMinutes: input.scheduleBufferMinutes,
    status: WorkRecordStatus.scheduled,
    items: List.unmodifiable(input.items),
    total:
        source?.total ?? input.items.fold(0, (sum, item) => sum + item.total),
  );
}
