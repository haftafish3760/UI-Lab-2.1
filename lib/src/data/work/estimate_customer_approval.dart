import 'models/estimate_models.dart';
import 'models/work_models.dart';

extension EstimateCustomerApproval on WorkRecord {
  WorkRecord recordCustomerApproval(WorkCustomerApproval approval) {
    if (!isProposal ||
        !companyReviewAllowsCustomerApproval ||
        resolvedEstimateStage == EstimateStage.converted ||
        resolvedEstimateStage == EstimateStage.archived ||
        approval.revision != revision ||
        approval.customerName.trim().isEmpty ||
        approval.recordedByEmployeeId.trim().isEmpty ||
        items.isEmpty ||
        (client.trim().isEmpty || client == 'Client not selected') ||
        detail.trim().isEmpty ||
        detail == 'Proposed work not entered yet.' ||
        (title.trim().isEmpty || title == 'Untitled estimate')) {
      throw StateError(
        'Complete and review this document before recording customer approval.',
      );
    }
    if (approval.method == CustomerApprovalMethod.other &&
        approval.note.trim().isEmpty) {
      throw StateError('Describe how the customer approved the document.');
    }
    return copyWith(
      customerApprovals: [...customerApprovals, approval],
    ).withEstimateStage(EstimateStage.approved, approval.recordedOn);
  }
}
