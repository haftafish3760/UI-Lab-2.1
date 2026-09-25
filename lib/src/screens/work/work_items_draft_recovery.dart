part of 'work_items_editor.dart';

extension _WorkItemsDraftRecovery on _WorkItemsEditorState {
  Future<void> _confirmItems() async {
    if (_confirming) return;
    if (_pendingItem != null) {
      if (widget.onDraftChanged == null) return;
      _publishItems();
      // Retain the entire unfinished workspace through its parent recovery
      // owner; do not consume it as a completed customer-facing item list.
      await leaveDraftRoute();
      return;
    }
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
    WorkItemsDraftInput(items: _items, pendingItems: _pendingItems.values),
  );

  void _changeItems(VoidCallback change) {
    _refresh(change);
    _publishItems();
  }

  void _capturePendingItem(WorkLineItemDraftInput input) {
    _refresh(() => _pendingItems[input.lineId] = input);
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
      _pendingItems.remove(item.id);
    });
    _publishItems();
  }

  Future<void> _resumeItem(WorkLineItemDraftInput pending) async {
    final item = await Navigator.of(context).push<WorkLineItem>(
      MaterialPageRoute(
        builder: (_) => WorkLineItemEditor(
          recoveryInput: pending,
          draftSession: widget.draftSession,
          onDraftChanged: _capturePendingItem,
          onDiscardInput: _discardPendingItem,
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

  void _discardPendingItem(String id) {
    _refresh(() => _pendingItems.remove(id));
    _publishItems();
  }

  Future<void> _confirmDiscardPending(WorkLineItemDraftInput pending) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Discard unfinished changes?'),
        content: Text(
          'Discard changes to ${pending.name.trim().isEmpty ? "this item" : pending.name}? Previously saved items stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep item'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    if (mounted && discard == true) _discardPendingItem(pending.lineId);
  }
}
