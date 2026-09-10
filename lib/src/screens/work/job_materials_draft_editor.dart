part of 'job_workspace_screen.dart';

extension _JobMaterialsDraftEditor on _JobWorkspaceScreenState {
  Future<void> _editJobItems({JobMaterialsDraftController? selected}) async {
    if (!widget.permissions.canAddMaterials || _committing) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    JobMaterialsDraftController? workflow = selected;
    DraftAutosaveSession? draft = selected?.session;
    var base = _sourceRecord;
    _setJobBusy(true);
    try {
      if (selected != null) {
        if (work == null) throw StateError('Durable Work storage unavailable.');
        work.validateJobMaterialsHandoff(
          selected,
          base.id,
          materialPermissions: widget.permissions,
        );
      }
      if (work != null) {
        workflow =
            selected ??
            await work.openJobMaterialsDraft(
              base.id,
              materialPermissions: widget.permissions,
            );
        draft = workflow.session;
        base = workflow.input.base;
      }
      if (!mounted) return;
      _setJobBusy(false);
      final existing = editableJobMaterials(base, widget.permissions);
      await Navigator.of(context).push<List<WorkLineItem>>(
        MaterialPageRoute(
          builder: (_) => WorkItemsEditor(
            initialItems: existing,
            pricing: base.pricing,
            workspaceLabel: 'Job materials',
            draftSession: draft,
            recoveryInput: workflow?.input.workspace,
            onDraftChanged: workflow?.updateWorkspace,
            onDiscard: draft?.discard,
            onConfirm: (additions) async {
              if (!mounted ||
                  !_applyStockChanges(existing, additions, apply: false)) {
                return false;
              }
              bool saved;
              if (workflow != null) {
                final record = await workflow.confirm();
                saved = record != null;
                if (saved && mounted) _adoptCommittedJob(record);
              } else {
                final input = JobMaterialsDraftInput(
                  base: base,
                  baseRevision: 0,
                  workspace: WorkItemsDraftInput(items: additions),
                ).prepare();
                final record = input.confirmedRecord(widget.permissions);
                saved = await _commitJobChange(
                  _job.copyWith(
                    lineItems: record.items
                        .map(JobLineItem.fromWorkLineItem)
                        .toList(),
                  ),
                  record,
                );
              }
              if (saved) _applyStockChanges(existing, additions);
              return saved;
            },
            allowedTypes: const [WorkLineItemType.material],
            allowMaterialCostHistory: widget.permissions.canViewInternalCost,
            allowExpenseEvidence:
                widget.permissions.canLinkExpenses &&
                widget.permissions.canViewInternalCost,
            allowTruckStock: widget.permissions.canUseTruckStock,
            canViewInternalCost: widget.permissions.canViewInternalCost,
            canViewCustomerPrice: canViewJobCustomerPrice(widget.permissions),
            canSetCustomerPrice: widget.permissions.canSetCustomerPrice,
            allowedJobBillingTreatments: jobMaterialBillingTreatmentsFor(
              widget.permissions,
            ),
            selectedDay: base.scheduledStart,
          ),
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The saved materials input could not be opened. It has been preserved.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) _setJobBusy(false);
      await draft?.close().catchError((Object _) {});
    }
  }
}
