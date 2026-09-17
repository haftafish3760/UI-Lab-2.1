import '../storage/draft_recovery_catalog.dart';
import 'expense_entry_setup_input.dart';
import 'expense_entry_setup_workflow.dart';
import 'expense_ui_repository_controller.dart';

class ExpenseEntrySetupRecovery {
  ExpenseEntrySetupRecovery(this.owner) {
    final repository = owner.drafts;
    if (repository == null) throw StateError('Expense setup unavailable.');
    catalog = DraftRecoveryCatalog(
      repository: repository,
      organizationId: owner.organizationId,
      ownerId: owner.actorEmployeeId,
      handlers: [
        DraftRecoveryHandler(
          domain: ExpenseEntrySetupWorkflow.domain,
          workflowLabel: 'Expense setup',
          canList: () => owner.canCreateForEmployee(owner.actorEmployeeId),
          inspect: (raw) async {
            try {
              final input = ExpenseEntrySetupInput.fromPayload(raw);
              return DraftRecoveryPreview(
                title: 'Expense setup · ${input.category.label}',
              );
            } on Object {
              return const DraftRecoveryPreview(
                title: 'Expense setup unavailable — saved input retained',
                availability: DraftRecoveryAvailability.unreadable,
              );
            }
          },
          canDiscard: (_) async => true,
        ),
      ],
    );
  }
  final ExpenseUiRepositoryController owner;
  late final DraftRecoveryCatalog catalog;
  Future<List<DraftRecoveryEntry>> list() => catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => catalog.discard(entry);
  Future<ExpenseEntrySetupWorkflow> resume(DraftRecoveryEntry entry) async {
    final current = await catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Expense setup requires review.');
    }
    final saved = await owner.drafts!.find(
      organizationId: owner.organizationId,
      ownerId: owner.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null) throw StateError('Expense setup unavailable.');
    final workflow = await owner.openEntrySetup(
      initial: ExpenseEntrySetupInput.fromPayload(owner.drafts!.decode(saved)),
      recoveryDraftId: current.draftId,
    );
    if (workflow.session.savedRevision != current.revision) {
      await workflow.session.close();
      throw StateError('Expense setup changed; refresh saved work.');
    }
    return workflow;
  }
}
