import '../../screens/expenses/expense_models.dart';
import 'authorized_receipt_draft_service.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_draft_ui_lab_policy.dart';

const bool receiptDraftUiLabDemoDataEnabled = bool.fromEnvironment(
  'MAINTAINIAC_UI_LAB_DEMO_DATA',
  defaultValue: true,
);

/// Adds deterministic UI Lab draft metadata only to a new, empty store.
///
/// Demo records intentionally claim no retained photos or PDFs. Real evidence
/// must be selected by a person and copied into private app storage.
Future<void> seedReceiptDraftUiLabDemoDataIfEmpty(
  ReceiptDraftRepository repository,
) async {
  if (!receiptDraftUiLabDemoDataEnabled) return;
  final permissions = receiptDraftUiLabOwnerPermissions();
  final service = AuthorizedReceiptDraftService(repository);
  final existing = await service.query(permissions: permissions);
  if (existing.isNotEmpty) return;
  final now = DateTime.now().toUtc();
  for (final draft in demoExpenseReceiptDrafts) {
    await service.create(
      draft: StoredReceiptDraft(
        draftId: draft.id,
        organizationId: permissions.organizationId,
        ownerEmployeeId: permissions.actorEmployeeId,
        title: draft.title,
        expenseDate: draft.updatedOn,
        evidence: const [],
        lifecycle: ReceiptDraftLifecycle(
          revision: 1,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ),
      evidence: const [],
      permissions: permissions,
      occurredAtUtc: now,
    );
  }
}
