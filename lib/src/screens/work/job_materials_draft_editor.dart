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
            workspaceLabel: 'Job items',
            draftSession: draft,
            recoveryInput: workflow?.input.workspace,
            onDraftChanged: workflow?.updateWorkspace,
            onDiscard: draft?.discard,
            onConfirm: (additions) async {
              if (!mounted ||
                  !_applyStockChanges(existing, additions, apply: false)) {
                return false;
              }
              final needsApproval = additions
                  .where(
                    (item) =>
                        item.resolvedJobMaterialBillingTreatment ==
                            JobMaterialBillingTreatment.invoiceCandidate &&
                        item.changeApproval == null,
                  )
                  .toList();
              if (needsApproval.isNotEmpty) {
                if (work == null) return false;
                final approval = await showDialog<WorkCustomerApproval>(
                  context: context,
                  builder: (_) => EstimateCustomerApprovalDialog(
                    record: base,
                    actorId: work.permissions.actorEmployeeId,
                    summary:
                        'Approve these job additions:\n${needsApproval.map((item) => '${item.name}: \$${item.total.toStringAsFixed(2)}').join('\n')}\nTotal: \$${needsApproval.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                  ),
                );
                if (!mounted || approval == null) return false;
                final evidence = {
                  ...approval.toJson(),
                  'revision': base.revision + 1,
                };
                additions = [
                  for (final item in additions)
                    if (needsApproval.contains(item))
                      decodeWorkLineItem({
                        ...encodeWorkLineItem(item),
                        'changeApproval': evidence,
                      })
                    else
                      item,
                ];
                workflow?.updateWorkspace(
                  WorkItemsDraftInput(items: additions),
                );
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
            allowedTypes: WorkLineItemType.values,
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
