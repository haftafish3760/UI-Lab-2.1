part of 'job_workspace_screen.dart';

extension _JobWorkspaceInteractions on _JobWorkspaceScreenState {
  Future<void> _createInvoice() async {
    if (_committing || _sourceRecord.status != WorkRecordStatus.completed) {
      return;
    }
    final permissions = invoicePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (!permissions.canCreate) return;
    final store = PrototypeOperationsScope.of(context);
    final existing = store.workRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.invoice &&
              record.sourceId == _sourceRecord.id,
        )
        .firstOrNull;
    if (existing != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              InvoiceDetailScreen(record: existing, permissions: permissions),
        ),
      );
      return;
    }
    final invoice = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) =>
            InvoiceEditorScreen(initialDay: _jobDay, sourceJob: _sourceRecord),
      ),
    );
    if (!mounted || invoice == null) return;
    if (store.workSession == null) store.addWorkRecord(invoice);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            InvoiceDetailScreen(record: invoice, permissions: permissions),
      ),
    );
  }

  Future<void> _openJobActions() async {
    final action = await Navigator.of(context).push<_JobAction>(
      MaterialPageRoute(
        builder: (_) => _JobActionsScreen(
          job: _job,
          selectedDay: _jobDay,
          permissions: widget.permissions,
        ),
      ),
    );
    if (!mounted || action == null) return;
    await _handleJobAction(action);
  }

  Future<void> _handleJobAction(_JobAction action) async {
    switch (action) {
      case _JobAction.addMaterials:
        await _editJobItems();
      case _JobAction.linkExpense:
        await _linkExistingExpense();
      case _JobAction.addReceipt:
        await _attachReceipt();
      case _JobAction.addPhoto:
        await _attachJobPhoto();
      case _JobAction.editNotes:
        await _editNotes();
      case _JobAction.startTravel:
        await _setJobStatus(JobStatus.enRoute);
      case _JobAction.markArrived:
        await _setJobStatus(JobStatus.arrived);
      case _JobAction.startWork || _JobAction.resumeWork:
        await _setJobStatus(JobStatus.inProgress);
      case _JobAction.pauseWork:
        await _setJobStatus(JobStatus.paused);
      case _JobAction.needsReturnVisit:
        await _setJobStatus(JobStatus.needsReturnVisit);
      case _JobAction.completeJob:
        await _setJobStatus(JobStatus.completed);
      case _JobAction.reschedule:
        await _rescheduleJob();
      case _JobAction.reassign:
        await _reassignJob();
    }
  }

  Future<void> _setJobStatus(JobStatus status) async {
    final recordStatus = switch (status) {
      JobStatus.scheduled => WorkRecordStatus.scheduled,
      JobStatus.enRoute => WorkRecordStatus.enRoute,
      JobStatus.arrived => WorkRecordStatus.arrived,
      JobStatus.inProgress => WorkRecordStatus.inProgress,
      JobStatus.paused => WorkRecordStatus.paused,
      JobStatus.needsReturnVisit => WorkRecordStatus.needsReturnVisit,
      JobStatus.completed => WorkRecordStatus.completed,
    };
    final saved = await _commitJobChange(
      _job.copyWith(status: status),
      _sourceRecord.copyWith(
        status: recordStatus,
        completedOn: recordStatus == WorkRecordStatus.completed
            ? DateTime.now()
            : _sourceRecord.completedOn,
      ),
    );
    if (saved &&
        mounted &&
        status == JobStatus.completed &&
        invoicePermissionsForView(
          OperationalScope.of(context).view,
        ).canCreate) {
      final create = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Job completed'),
          content: const Text(
            'Create the invoice from the completed work and approved additions?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Create invoice'),
            ),
          ],
        ),
      );
      if (mounted && create == true) await _createInvoice();
    }
  }

  Future<void> _linkExistingExpense() async {
    if (!widget.permissions.canLinkExpenses) return;
    final store = PrototypeOperationsScope.maybeOf(context);
    if (store == null) return;
    final source = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEvidenceSourcePicker(expenses: store.expenses),
      ),
    );
    if (!mounted || source == null) return;
    await _linkExpenseRecord(source);
  }

  Future<void> _linkExpenseRecord(ExpenseRecord source) async {
    final attachmentId = 'expense-${source.id}';
    if (_job.receipts.any((item) => item.id == attachmentId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That expense is already linked.')),
      );
      return;
    }
    final attachment = ReceiptAttachment(
      id: attachmentId,
      name: '${source.vendor} · ${expenseMoney(source.amount)}',
      source: 'Existing expense',
      status: source.receiptStatus ?? 'No receipt attached',
      kind: JobAttachmentKind.expense,
    );

    await _commitJobChange(
      _job.copyWith(receipts: [..._job.receipts, attachment]),
      _sourceRecord.copyWith(
        linkedExpenseIds: [..._sourceRecord.linkedExpenseIds, source.id],
      ),
    );
  }

  Future<void> _editNotes() async {
    if (!widget.permissions.canEditJob) return;
    final store = PrototypeOperationsScope.maybeOf(context);
    final record = await showDialog<WorkRecord>(
      context: context,
      builder: (_) =>
          JobNotesEditorDialog(record: _sourceRecord, work: store?.workSession),
    );
    if (!mounted || record == null) return;
    if (store?.workSession == null) {
      await _commitJobChange(
        _job.copyWith(technicianNotes: record.jobNotes),
        record,
      );
    } else {
      _adoptCommittedJob(record);
    }
  }

  bool _applyStockChanges(
    List<WorkLineItem> before,
    List<WorkLineItem> after, {
    bool apply = true,
  }) {
    final store = PrototypeOperationsScope.maybeOf(context);
    if (store == null) return true;
    double used(List<WorkLineItem> items, String stockId) => items
        .where((item) => item.sourceStockId == stockId)
        .fold(0, (sum, item) => sum + item.quantity);
    final stockIds = after
        .map((item) => item.sourceStockId)
        .whereType<String>()
        .toSet();
    final allStockIds = {
      ...stockIds,
      ...before.map((item) => item.sourceStockId).whereType<String>(),
    };
    if (allStockIds.isNotEmpty && !widget.permissions.canUseTruckStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to change truck stock.'),
        ),
      );
      return false;
    }
    final stockById = {
      for (final record in store.inventoryStock) record.id: record,
    };
    for (final stockId in allStockIds) {
      if (!stockById.containsKey(stockId)) {
        return _reportMissingStock(stockId);
      }
    }
    for (final stockId in stockIds) {
      final record = stockById[stockId]!;
      final change = used(after, stockId) - used(before, stockId);
      if (change > record.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only ${record.quantity} ${record.unitLabel} of ${record.materialName} are recorded on ${record.locationLabel}.',
            ),
          ),
        );
        return false;
      }
    }
    if (!apply) return true;
    for (final stockId in allStockIds) {
      final record = stockById[stockId]!;
      final change = used(after, stockId) - used(before, stockId);
      if (change != 0) {
        store.updateInventoryStock(
          record.copyWith(
            quantity: record.quantity - change,
            updatedOn: DateTime.now(),
          ),
        );
      }
    }
    return true;
  }

  bool _reportMissingStock(String stockId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'The saved truck-stock source $stockId is no longer available. No stock was changed.',
        ),
      ),
    );
    return false;
  }

  Future<void> _attachReceipt() async {
    if (!widget.permissions.canAttachReceipts) return;
    final store = PrototypeOperationsScope.maybeOf(context);
    if (store == null) return;
    final permissions = expensePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (!permissions.canAttachReceipt) return;
    final source = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ReceiptIntakeScreen(
          expenseDate: _jobDay,
          linkedJobId: _sourceRecord.id,
          linkedJobLabel: '${_sourceRecord.number} · ${_sourceRecord.title}',
          permissions: permissions,
        ),
      ),
    );
    if (!mounted || source == null) return;
    if (!store.expenses.any((record) => record.id == source.id)) return;
    await _linkExpenseRecord(source);
  }

  Future<void> _attachJobPhoto() async {
    if (!widget.permissions.canAttachReceipts) return;
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture job photo'),
              onTap: () => Navigator.pop(context, 'Camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose existing photo'),
              onTap: () => Navigator.pop(context, 'Photo library'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Attach a file'),
              onTap: () => Navigator.pop(context, 'File picker'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No job photo was attached. $source storage is not connected yet.',
        ),
      ),
    );
  }

  Future<void> _rescheduleJob() async {
    if (!widget.permissions.canEditJob) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work != null && !work.permissions.canScheduleJobs) return;
    final record = await showModalBottomSheet<WorkRecord>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => JobScheduleEditorSheet(record: _sourceRecord, work: work),
    );
    if (!mounted || record == null) return;
    if (work == null) {
      await _commitJobChange(
        _job.copyWith(
          scheduledTime: _scheduledTimeLabel(context, record),
          status: record.status == WorkRecordStatus.scheduled
              ? JobStatus.scheduled
              : _job.status,
        ),
        record,
      );
    } else {
      _adoptCommittedJob(record);
    }
  }

  Future<void> _reassignJob() async {
    if (!widget.permissions.canEditJob) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work != null && !work.permissions.canAssignJobs) return;
    final record = await showModalBottomSheet<WorkRecord>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          JobAssignmentEditorSheet(record: _sourceRecord, work: work),
    );
    if (!mounted || record == null) return;
    if (work == null) {
      await _commitJobChange(
        _job.copyWith(
          assignedTechnician: record.assignee,
          assignedVehicle: record.vehicle,
        ),
        record,
      );
    } else {
      _adoptCommittedJob(record);
    }
  }
}
