part of 'expense_editor_screen.dart';

extension _ExpenseEditorDraftRecovery on _ExpenseEditorScreenState {
  List<TextEditingController> get _draftFields => [
    _correctionReason,
    _vendor,
    _amount,
    _subtotal,
    _salesTax,
    _job,
  ];

  ExpenseDraftInput get _expenseInput => ExpenseDraftInput(
    expenseId: _expenseId,
    receiptSourceId: widget.receiptDraftId,
    receiptSourceRevision: _receiptSourceRevision,
    receiptImageCount: _draftImageCount,
    baseRecord: _editingBase ?? widget.existing,
    baseRevision: _baseRevision,
    pendingLine: _pendingLine,
    ownerId: _draftOwnerId ?? demoEmployees.first.id,
    ownerLabel: _draftOwnerLabel ?? demoEmployees.first.name,
    jobId: _draftJobId,
    date: _expenseDate,
    category: _category,
    receiptType: _receiptType,
    prepareMaterialsReview: _prepareMaterialsReview,
    correctionReason: _correctionReason.text,
    vendor: _vendor.text,
    amount: _amount.text,
    subtotal: _subtotal.text,
    salesTax: _salesTax.text,
    job: _job.text,
    lines: _lineItems,
  );

  void _changeExpenseInput(VoidCallback change) {
    _refresh(change);
    _captureExpenseInput();
  }

  void _updateExpenseDraftOwner() {
    if (_draft == null) return;
    final scope = OperationalScope.of(context);
    _draftOwnerId = scope.view == AppViewMode.technician
        ? _expenseController!.actorEmployeeId
        : scope.selectedEmployeeId ?? _expenseController!.actorEmployeeId;
    _draftOwnerLabel =
        demoEmployees
            .where((employee) => employee.id == _draftOwnerId)
            .firstOrNull
            ?.name ??
        'Unknown employee';
    _captureExpenseInput();
  }

  void _captureExpenseInput() {
    if (_draftOpening || _saving) return;
    _inputWorkflow?.updateInput(_expenseInput);
  }

  Future<void> _openExpenseDraft() async {
    if (!mounted) return;
    if (widget.purpose == ExpenseEditorPurpose.receiptReview &&
        widget.receiptDraftId != null &&
        ReceiptSubmissionScope.maybeOf(context) != null) {
      await _openReceiptReviewDraft();
      return;
    }

    final controller = _expenseController;
    if (controller != null &&
        controller.drafts == null &&
        LocalDraftScope.maybeOf(context) != null &&
        widget.purpose == ExpenseEditorPurpose.manualEntry &&
        widget.initialReceiptImageCount == 0) {
      _refresh(
        () => _confirmationError =
            'Saved input could not be opened. Leave this screen and retry; the draft has been preserved.',
      );
      return;
    }
    // Receipt intake owns a separate draft and confirmation workflow.
    if (controller?.drafts == null ||
        controller == null ||
        widget.purpose != ExpenseEditorPurpose.manualEntry ||
        widget.initialReceiptImageCount != 0) {
      _refresh(() => _draftOpening = false);
      return;
    }
    if (!widget.permissions.canUseEditor(
      isExisting: widget.existing != null,
      isOwn: widget.existingRecordIsOwn,
      purpose: widget.purpose,
    )) {
      return;
    }
    try {
      if (widget.existing == null &&
          !controller.canCreateForEmployee(controller.actorEmployeeId)) {
        throw StateError('Expense creation is unavailable.');
      }
      final scope = OperationalScope.of(context);
      _draftOwnerId = scope.view == AppViewMode.technician
          ? controller.actorEmployeeId
          : scope.selectedEmployeeId ?? controller.actorEmployeeId;
      _draftOwnerLabel =
          demoEmployees
              .where((employee) => employee.id == _draftOwnerId)
              .firstOrNull
              ?.name ??
          'Unknown employee';
      String? draftId;
      final candidates =
          !widget.startNewExpense &&
              widget.existing == null &&
              widget.recoveredExpenseWorkflow == null
          ? await controller.manualDraftRecovery.list()
          : const <DraftRecoveryChoice>[];
      if (!mounted) return;
      if (widget.existing == null && candidates.isNotEmpty) {
        final chosen = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Continue an unfinished expense?'),
            children: [
              for (final row in candidates)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(row.draftId),
                  child: Text(row.label),
                ),
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop('new'),
                child: const Text('Start another expense'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (chosen == null) {
          await leaveDraftRoute();
          return;
        }
        if (chosen != 'new') draftId = chosen;
      }
      final workflow =
          widget.recoveredExpenseWorkflow ??
          await controller.openExpenseDraft(
            initial: _expenseInput,
            existingRecordId: widget.existing?.id,
            recoveryDraftId: draftId,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      if (widget.recoveredReceiptWorkflow != null ||
          workflow.session.organizationId != controller.organizationId ||
          workflow.session.ownerId != controller.actorEmployeeId ||
          (workflow.input.baseRevision == null
              ? widget.existing != null
              : widget.existing?.id != workflow.input.expenseId)) {
        await workflow.session.close();
        _draft = null;
        throw StateError('Recovered expense does not match this editor.');
      }
      _expenseWorkflow = workflow;
      _inputWorkflow = workflow;
      final draft = workflow.session;
      _draft = draft;
      _restoreExpenseDraftInput(workflow.input);
      _activateExpenseDraft(draft);
      if (widget.initialLineId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openRequestedExpenseLine();
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _confirmationError =
              'Saved input could not be opened. Leave this screen and retry; the draft has been preserved.';
        });
      }
    }
  }

  void _restoreExpenseDraftInput(ExpenseDraftInput input) {
    _expenseId = input.expenseId;
    _draftImageCount = input.receiptImageCount;
    _receiptSourceRevision = input.receiptSourceRevision;
    _editingBase = input.baseRecord;
    _baseRevision = input.baseRevision;
    _pendingLine = input.pendingLine;
    _draftOwnerId = input.ownerId;
    _draftOwnerLabel = input.ownerLabel;
    _draftJobId = input.jobId;
    _expenseDate = input.date;
    _category = input.category;
    _receiptType = input.receiptType;
    _prepareMaterialsReview = input.prepareMaterialsReview;
    _correctionReason.text = input.correctionReason;
    _vendor.text = input.vendor;
    _amount.text = input.amount;
    _subtotal.text = input.subtotal;
    _salesTax.text = input.salesTax;
    _job.text = input.job;
    _lineItems
      ..clear()
      ..addAll(input.lines);
  }

  void _activateExpenseDraft(DraftAutosaveSession draft) {
    for (final field in _draftFields) {
      field.addListener(_captureExpenseInput);
    }
    _draftSubscription = draft.changes.listen((_) {
      if (mounted) _refresh(() {});
    });
    _refresh(() => _draftOpening = false);
  }

  Future<void> _discardExpenseDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished expense input?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _refresh(() => _saving = true);
    try {
      await _draft!.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _confirmationError =
              'The draft could not be discarded. Your input has been preserved.';
        });
      }
    }
  }
}
