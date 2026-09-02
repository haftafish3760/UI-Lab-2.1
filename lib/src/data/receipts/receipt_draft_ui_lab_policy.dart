import '../expenses/expense_ui_lab_policy.dart';
import 'authorized_receipt_draft_service.dart';
import 'file_receipt_draft_repository.dart';
import 'receipt_draft_repository.dart';

const receiptDraftUiLabPermissionRevision =
    'ui-lab-receipt-draft-owner-permissions-1';

ReceiptDraftCommandPermissions receiptDraftUiLabOwnerPermissions() =>
    ReceiptDraftCommandPermissions(
      organizationId: expenseUiLabOrganizationId,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: receiptDraftUiLabPermissionRevision,
      readScope: ReceiptDraftReadScope.company,
      canCreate: true,
      canEditOwn: true,
      canEditTeam: true,
      canSubmitOwn: true,
      canSubmitTeam: true,
      canDiscardOwn: true,
      canDiscardTeam: true,
    );

bool receiptDraftRepositoryRecoveredFromDamage(
  ReceiptDraftRepository repository,
) =>
    repository is FileReceiptDraftRepository &&
    repository.recoveredFromDamagedSnapshot;
