part of 'work_items_editor.dart';

extension _WorkItemsDraftRecovery on _WorkItemsEditorState {
  Future<void> _confirmItems() async {
    if (_confirming || _pendingItem != null) return;
    if (widget.onConfirm == null) {
      await leaveDraftRoute(List<WorkLineItem>.of(_items));
      return;
    }
    _refresh(() => _confirming = true);
    try {
      await widget.draftSession?.flush();
      final saved = await widget.onConfirm!(List<WorkLineItem>.of(_items));
      if (!saved) throw StateError('Items were not saved.');
      if (mounted) await finishDraftRoute(List<WorkLineItem>.of(_items));
    } on Object {
      if (mounted) {
        _refresh(() {
          _confirming = false;
          _confirmationError =
              'The materials were not saved. Your unfinished input has been kept. Retry saving.';
        });
      }
    }
  }

  void _publishItems() => widget.onDraftChanged?.call(
    WorkItemsDraftInput(items: _items, pendingItem: _pendingItem),
  );

  void _changeItems(VoidCallback change) {
    if (_pendingItem != null) return;
    _refresh(change);
    _publishItems();
  }

  void _capturePendingItem(WorkLineItemDraftInput input) {
    _refresh(() => _pendingItem = input);
    _publishItems();
  }

  void _acceptItem(WorkLineItem item) {
    _refresh(() {
      final index = _items.indexWhere((candidate) => candidate.id == item.id);
      if (index < 0) {
        _items.add(item);
      } else {
        _items[index] = item;
      }
      _pendingItem = null;
    });
    _publishItems();
  }

  Future<void> _resumeItem() async {
    final pending = _pendingItem;
    if (pending == null) return;
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          recoveryInput: pending,
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          allowedTypes: widget.allowedTypes,
          canViewInternalCost: widget.canViewInternalCost,
          canSetCustomerPrice: widget.canSetCustomerPrice,
          allowedJobBillingTreatments: widget.allowedJobBillingTreatments,
          selectedDay: widget.selectedDay,
          workspaceLabel: widget.workspaceLabel,
        ),
      ),
    );
    if (mounted && item != null) _acceptItem(item);
  }

  Future<void> _discardItemChanges() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard item changes?'),
        content: const Text(
          'This removes unfinished item input and restores the items from before this editing session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (widget.onDiscard != null) {
      _refresh(() => _confirming = true);
      try {
        await widget.onDiscard!();
        if (mounted) await finishDraftRoute();
      } on Object {
        if (mounted) {
          _refresh(() {
            _confirming = false;
            _confirmationError =
                'Unfinished materials could not be discarded. They have been preserved.';
          });
        }
      }
      return;
    }
    _refresh(() {
      _items
        ..clear()
        ..addAll(widget.initialItems);
      _pendingItem = null;
    });
    _publishItems();
    await leaveDraftRoute(List<WorkLineItem>.of(widget.initialItems));
  }
}
