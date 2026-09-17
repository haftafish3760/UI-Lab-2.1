import '../expenses/expense_entry_setup_input.dart';
import '../expenses/expense_entry_setup_workflow.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import 'authorized_receipt_draft_service.dart';
import 'local_receipt_draft_repository.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';
import 'receipt_draft_ui_controller.dart';
import 'receipt_entry_setup.dart';

/// Converts setup into an empty receipt draft in the same SQLite commit that
/// consumes setup. No image import, recognition, expense, or stock confirmation.
class AtomicExpenseSetupReceipt {
  const AtomicExpenseSetupReceipt(this.repository);
  final LocalReceiptDraftRepository repository;

  Future<StoredReceiptDraft> create({
    required LocalDraftCheckpoint checkpoint,
    required ReceiptDraftCommandPermissions permissions,
    required DateTime occurredAtUtc,
  }) => repository.withStagedMediaImport((stage) async {
    if (checkpoint.domain != ExpenseEntrySetupWorkflow.domain) {
      throw const ReceiptDraftRevisionConflictException(
        'Invalid expense setup.',
      );
    }
    final drafts = LocalDraftStore(stage.prepare().database);
    final saved = await drafts.find(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: checkpoint.domain,
      draftId: checkpoint.draftId,
    );
    if (saved == null || saved.revision != checkpoint.revision) {
      throw const ReceiptDraftRevisionConflictException(
        'Expense setup changed.',
      );
    }
    final input = ExpenseEntrySetupInput.fromPayload(drafts.decode(saved));
    if (input.pendingCategory != null) {
      throw StateError('Finish or cancel the category choice first.');
    }
    final controller = ReceiptDraftUiController(
      AuthorizedReceiptDraftService(stage.repository),
      permissions,
    );
    try {
      final continuation = input.continuation;
      StoredReceiptDraft? existing;
      if (continuation != null) {
        if (continuation.destination != ExpenseSetupDestination.receipt ||
            !await controller.load()) {
          throw StateError('Receipt continuation is unavailable.');
        }
        for (final record in controller.records) {
          if (record.draftId == continuation.id) existing = record;
        }
        if (existing == null ||
            existing.lifecycle.revision != continuation.revision) {
          throw const ReceiptDraftRevisionConflictException(
            'The unfinished receipt changed. Reopen it before continuing.',
          );
        }
      }
      final receipt = existing == null
          ? await controller.create(
              draftId: '${checkpoint.draftId}-receipt',
              title: 'Receipt draft',
              expenseDate: input.date,
              evidence: const [],
              occurredAtUtc: occurredAtUtc,
              entrySetup: ReceiptEntrySetup(
                category: input.category,
                type: input.receiptType,
              ),
            )
          : await controller.update(
              draftId: existing.draftId,
              expectedRevision: continuation!.revision,
              title: existing.title,
              expenseDate: existing.expenseDate,
              retainedEvidenceIds: existing.activeEvidence.map(
                (item) => item.evidenceId,
              ),
              addedEvidence: const [],
              occurredAtUtc: occurredAtUtc,
              linkedJobId: existing.linkedJobId,
              linkedJobLabel: existing.linkedJobLabel,
              entrySetup: ReceiptEntrySetup(
                category: input.category,
                type: input.receiptType,
                pastedText: existing.entrySetup?.pastedText ?? '',
              ),
            );
      if (receipt == null) {
        throw const ReceiptDraftStorageException(
          'Receipt setup was not saved.',
        );
      }
      await commitPreparedDomainChanges(
        [stage.prepare()],
        organizationId: permissions.organizationId,
        ownerId: permissions.actorEmployeeId,
        checkpoint: checkpoint,
      );
      stage.publishCommitted();
      return receipt;
    } finally {
      controller.dispose();
    }
  });
}
