part of 'app.dart';

extension _ApplicationDataScopes on _UiLabAppState {
  Widget _buildDataScopes(Widget child) {
    final resolver = widget.resolveRetainedPath;
    final documentScope = resolver == null
        ? child
        : LocalDocumentPathScope(resolve: resolver, child: child);
    Widget scoped = ApplicationRecoveryHost(
      operations: _operationsStore,
      preferences: _preferences,
      receipts: _receiptSubmission,
      recurring: _recurringPayment,
      view: () => _scope.view,
      child: PrototypeOperationsScope(
        store: _operationsStore,
        child: documentScope,
      ),
    );
    final directory = widget.directorySession;
    if (directory != null) {
      scoped = DocumentImageScope(load: CompanyDocumentBrandingService(directory).readLogo, child: scoped);
    }
    final portal = widget.customerPortal;
    if (portal != null) {
      scoped = CustomerPortalScope(gateway: portal, child: scoped);
    }
    final workday = widget.workdaySession;
    if (workday != null) {
      scoped = WorkdayPersistenceScope(
        session: workday,
        child: WorkdayRecoveryNotice(session: workday, child: scoped),
      );
    }
    final recurringPayment = _recurringPayment;
    if (recurringPayment != null) {
      scoped = RecurringPaymentScope(session: recurringPayment, child: scoped);
    }
    final receiptSubmission = _receiptSubmission;
    if (receiptSubmission != null) {
      scoped = ReceiptSubmissionScope(
        session: receiptSubmission,
        child: scoped,
      );
    }
    final media = _mediaCoordinator;
    if (media != null) {
      scoped = NativeMediaPickerScope(coordinator: media, child: scoped);
    }
    final draftStore = widget.draftStore;
    if (draftStore != null) {
      scoped = LocalDraftScope(store: draftStore, child: scoped);
    }
    final recurringController = _recurringExpenseController;
    if (recurringController != null) {
      scoped = RecurringExpenseUiScope(
        controller: recurringController,
        child: scoped,
      );
    }
    final receiptDraftController = _receiptDraftController;
    if (receiptDraftController != null) {
      scoped = ReceiptDraftUiScope(
        controller: receiptDraftController,
        child: scoped,
      );
    }
    final expenseController = _expenseController;
    if (expenseController == null) return scoped;
    return ExpenseUiScope(controller: expenseController, child: scoped);
  }
}
