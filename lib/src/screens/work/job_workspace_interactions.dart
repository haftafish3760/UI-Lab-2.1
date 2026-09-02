part of 'job_workspace_screen.dart';

extension _JobWorkspaceInteractions on _JobWorkspaceScreenState {
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
        _setJobStatus(JobStatus.enRoute);
      case _JobAction.markArrived:
        _setJobStatus(JobStatus.arrived);
      case _JobAction.startWork || _JobAction.resumeWork:
        _setJobStatus(JobStatus.inProgress);
      case _JobAction.pauseWork:
        _setJobStatus(JobStatus.paused);
      case _JobAction.needsReturnVisit:
        _setJobStatus(JobStatus.needsReturnVisit);
      case _JobAction.completeJob:
        _setJobStatus(JobStatus.completed);
      case _JobAction.reschedule:
        await _rescheduleJob();
      case _JobAction.reassign:
        await _reassignJob();
    }
  }

  void _setJobStatus(JobStatus status) {
    _replaceJob(_job.copyWith(status: status));
    final recordStatus = switch (status) {
      JobStatus.scheduled => WorkRecordStatus.scheduled,
      JobStatus.enRoute => WorkRecordStatus.enRoute,
      JobStatus.arrived => WorkRecordStatus.arrived,
      JobStatus.inProgress => WorkRecordStatus.inProgress,
      JobStatus.paused => WorkRecordStatus.paused,
      JobStatus.needsReturnVisit => WorkRecordStatus.needsReturnVisit,
      JobStatus.completed => WorkRecordStatus.completed,
    };
    _persistSource(
      _sourceRecord.copyWith(
        status: recordStatus,
        completedOn: recordStatus == WorkRecordStatus.completed
            ? DateTime.now()
            : _sourceRecord.completedOn,
      ),
    );
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
    _linkExpenseRecord(source);
  }

  void _linkExpenseRecord(ExpenseRecord source) {
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
    _replaceJob(_job.copyWith(receipts: [..._job.receipts, attachment]));
    _persistSource(
      _sourceRecord.copyWith(
        linkedExpenseIds: [..._sourceRecord.linkedExpenseIds, source.id],
      ),
    );
  }

  Future<void> _editNotes() async {
    final controller = TextEditingController(text: _job.technicianNotes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 480),
        title: const Text('Edit job notes'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Notes for this job'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save notes'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted && notes != null) {
      _replaceJob(_job.copyWith(technicianNotes: notes));
      _persistSource(_sourceRecord.copyWith(jobNotes: notes));
    }
  }

  Future<void> _editJobItems() async {
    if (!widget.permissions.canAddMaterials) return;
    final existingMaterials = _job.lineItems
        .where(
          (item) =>
              item.isJobAddition &&
              item.kind == JobLineKind.material &&
              canEditJobMaterialAddition(item, widget.permissions),
        )
        .map((item) => item.toWorkLineItem())
        .toList();
    final editableIds = existingMaterials.map((item) => item.id).toSet();
    final additions = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: existingMaterials,
          pricing: _sourceRecord.pricing,
          workspaceLabel: 'Job materials',
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
          selectedDay: _sourceRecord.scheduledStart,
        ),
      ),
    );
    if (!mounted || additions == null) return;
    if (!_applyStockChanges(existingMaterials, additions)) return;
    final jobItems = [
      ..._job.lineItems.where((item) => !editableIds.contains(item.id)),
      ...additions.map(
        (item) => JobLineItem.fromWorkLineItem(item, isJobAddition: true),
      ),
    ];
    final revised = jobItems.map((item) => item.toWorkLineItem()).toList();
    _replaceJob(_job.copyWith(lineItems: jobItems));
    _persistSource(
      _sourceRecord.reviseItems(revised, changedOn: DateTime.now()),
    );
  }

  bool _applyStockChanges(List<WorkLineItem> before, List<WorkLineItem> after) {
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
    _linkExpenseRecord(source);
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
          'No job photo was attached. $source storage is not connected in UI Lab yet.',
        ),
      ),
    );
  }

  Future<void> _rescheduleJob() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'Choose the new job date',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Choose the new arrival time',
    );
    if (!mounted || time == null) return;
    final localizations = MaterialLocalizations.of(context);
    final value =
        '${localizations.formatMediumDate(date)} · '
        '${localizations.formatTimeOfDay(time)}';
    final rescheduledReturnVisit = _job.status == JobStatus.needsReturnVisit;
    _replaceJob(
      _job.copyWith(
        scheduledTime: value,
        status: rescheduledReturnVisit ? JobStatus.scheduled : _job.status,
      ),
    );
    final scheduledStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _persistSource(
      _sourceRecord.copyWith(
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledStart.add(const Duration(hours: 2)),
        status: rescheduledReturnVisit
            ? WorkRecordStatus.scheduled
            : _sourceRecord.status,
      ),
    );
  }

  Future<void> _reassignJob() async {
    var technician = _job.assignedTechnician;
    var vehicle = _job.assignedVehicle;
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reassign job',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: technician,
                    decoration: const InputDecoration(labelText: 'Technician'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Alex Morgan',
                        child: Text('Alex Morgan'),
                      ),
                      DropdownMenuItem(
                        value: 'Jordan Lee',
                        child: Text('Jordan Lee'),
                      ),
                      DropdownMenuItem(
                        value: 'Unassigned',
                        child: Text('Unassigned'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => technician = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: vehicle,
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Transit 12',
                        child: Text('Transit 12'),
                      ),
                      DropdownMenuItem(
                        value: 'Service Van 4',
                        child: Text('Service Van 4'),
                      ),
                      DropdownMenuItem(
                        value: 'No vehicle assigned',
                        child: Text('No vehicle assigned'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => vehicle = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, (technician, vehicle)),
                    child: const Text('Save assignment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    _replaceJob(
      _job.copyWith(assignedTechnician: result.$1, assignedVehicle: result.$2),
    );
    _persistSource(
      _sourceRecord.copyWith(assignee: result.$1, vehicle: result.$2),
    );
  }
}
