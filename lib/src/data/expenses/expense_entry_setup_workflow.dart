import '../storage/draft_autosave_session.dart';
import '../storage/draft_repository.dart';
import '../storage/draft_transfer_repository.dart';
import '../storage/local_record_identity.dart';
import 'expense_entry_setup_input.dart';
import 'expense_draft_input.dart';
import 'expense_ui_repository_controller.dart';
import 'expense_workflow_models.dart';

/// Saves setup only. It cannot confirm expenses, create stock, or choose a route.
class ExpenseEntrySetupWorkflow {
  ExpenseEntrySetupWorkflow._(this.session, this._authorize);

  static const domain = 'expenses/entry-setup';
  final DraftAutosaveSession session;
  final void Function() _authorize;
  ExpenseEntrySetupInput get input =>
      ExpenseEntrySetupInput.fromPayload(session.input);

  static Future<ExpenseEntrySetupWorkflow> open({
    required DraftRepository repository,
    required String organizationId,
    required String ownerId,
    required ExpenseEntrySetupInput initial,
    required void Function() authorize,
    String? recoveryDraftId,
  }) async {
    authorize();
    final session = DraftAutosaveSession(
      store: repository,
      organizationId: organizationId,
      ownerId: ownerId,
      domain: domain,
      draftId: recoveryDraftId ?? newLocalRecordIdentity('expense-setup'),
    );
    try {
      await session.initialize();
      authorize();
      if (session.input.isEmpty) {
        if (recoveryDraftId != null) {
          throw StateError('Selected expense setup is unavailable.');
        }
        session.replaceInput(initial.toPayload());
      }
      // Reject unsupported saved input without replacing or silently defaulting it.
      ExpenseEntrySetupInput.fromPayload(session.input);
      return ExpenseEntrySetupWorkflow._(session, authorize);
    } on Object {
      await session.close().catchError((Object _) {});
      rethrow;
    }
  }

  void _update(ExpenseEntrySetupInput next) {
    _authorize();
    session.replaceInput(next.toPayload());
  }

  void chooseDetail(ExpenseReceiptType type) =>
      _update(input.change(receiptType: type));

  void proposeCategory(ExpenseCategory category) =>
      _update(input.change(pendingCategory: category));

  void acceptCategory() => _update(
    input.change(category: input.pendingCategory, clearPendingCategory: true),
  );

  void cancelCategory() => _update(input.change(clearPendingCategory: true));

  /// Creates recoverable manual input, never a confirmed expense. The stable
  /// destination remains discoverable even if navigation is interrupted.
  Future<String> continueManually({required String ownerLabel}) async {
    _authorize();
    final repository = session.store;
    if (repository is! DraftTransferRepository) {
      throw StateError('Atomic expense setup transfer is unavailable.');
    }
    if (input.pendingCategory != null) {
      throw StateError('Finish or cancel the category choice first.');
    }
    final continuation = input.continuation;
    if (continuation != null &&
        continuation.destination != ExpenseSetupDestination.manual) {
      throw StateError('Continue the existing receipt instead.');
    }
    final targetId = continuation?.id ?? '${session.draftId}-manual';
    await session.confirm((checkpoint) async {
      _authorize();
      final setup = input;
      final fresh = ExpenseDraftInput(
        expenseId: '${session.draftId}-expense',
        receiptSourceId: null,
        receiptSourceRevision: null,
        receiptImageCount: 0,
        baseRecord: null,
        baseRevision: null,
        pendingLine: null,
        ownerId: session.ownerId,
        ownerLabel: ownerLabel,
        jobId: null,
        date: setup.date,
        category: setup.category,
        receiptType: setup.receiptType,
        prepareMaterialsReview: false,
        correctionReason: '',
        vendor: '',
        amount: '',
        subtotal: '',
        salesTax: '',
        job: '',
        lines: const [],
      );
      var payload = fresh.toPayload();
      if (continuation != null) {
        final saved = await repository.find(
          organizationId: session.organizationId,
          ownerId: session.ownerId,
          domain: 'expenses/manual-entry',
          draftId: continuation.id,
        );
        if (saved == null || saved.revision != continuation.revision) {
          throw StateError(
            'The unfinished expense changed. Reopen it before continuing.',
          );
        }
        final existing = repository.decode(saved);
        final decoded = ExpenseDraftInput.fromPayload(existing);
        if (decoded.ownerId != session.ownerId ||
            decoded.baseRecord != null ||
            decoded.receiptSourceId != null) {
          throw StateError(
            'This expense cannot be changed through entry setup.',
          );
        }
        // Preserve raw unfinished fields and forward-compatible fields exactly.
        payload = {
          ...existing,
          'category': setup.category.name,
          'receiptType': setup.receiptType.name,
        };
      }
      _authorize();
      await repository.transfer(
        organizationId: session.organizationId,
        ownerId: session.ownerId,
        source: checkpoint,
        targetDomain: 'expenses/manual-entry',
        targetDraftId: targetId,
        targetPayload: payload,
        expectedTargetRevision: continuation?.revision ?? 0,
        occurredAt: DateTime.now().toUtc(),
      );
      return true;
    });
    return targetId;
  }

  Future<void> discard() async {
    _authorize();
    await session.discard();
  }

  void retry() {
    _authorize();
    session.retry();
  }
}

extension ExpenseEntrySetupOwner on ExpenseUiRepositoryController {
  Future<ExpenseEntrySetupWorkflow?> returnToManualSetup(String draftId) async {
    requireActiveDraftOwner();
    final repository = drafts;
    if (repository == null || !canCreateForEmployee(actorEmployeeId)) {
      throw StateError('Expense setup is unavailable.');
    }
    final saved = await repository.find(
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      domain: 'expenses/manual-entry',
      draftId: draftId,
    );
    if (saved == null) return null; // Confirmed or explicitly discarded.
    final input = ExpenseDraftInput.fromPayload(repository.decode(saved));
    if (input.ownerId != actorEmployeeId ||
        input.baseRecord != null ||
        input.receiptSourceId != null) {
      throw StateError('Expense setup owner changed.');
    }
    final setup = await openEntrySetup(
      initial: ExpenseEntrySetupInput(
        date: input.date,
        category: input.category,
        receiptType: input.receiptType,
        continuation: ExpenseSetupContinuation(
          destination: ExpenseSetupDestination.manual,
          id: draftId,
          revision: saved.revision,
        ),
      ),
    );
    try {
      await setup.session.flush();
      return setup;
    } on Object {
      await setup.session.close().catchError((Object _) {});
      rethrow;
    }
  }

  Future<ExpenseEntrySetupWorkflow> openEntrySetup({
    required ExpenseEntrySetupInput initial,
    String? recoveryDraftId,
  }) {
    void authorize() {
      requireActiveDraftOwner();
      if (drafts == null || !canCreateForEmployee(actorEmployeeId)) {
        throw StateError('Expense setup is unavailable.');
      }
    }

    authorize();
    return ExpenseEntrySetupWorkflow.open(
      repository: drafts!,
      organizationId: organizationId,
      ownerId: actorEmployeeId,
      initial: initial,
      authorize: authorize,
      recoveryDraftId: recoveryDraftId,
    );
  }
}
