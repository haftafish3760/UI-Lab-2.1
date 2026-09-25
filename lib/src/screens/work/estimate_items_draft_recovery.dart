part of 'estimate_items_screen.dart';

extension _EstimateItemsDraftRecovery on _EstimateItemsScreenState {
  Future<void> _saveItems() async {
    if (_saving) return;
    if (_pendingItem != null) {
      if (widget.onDraftChanged == null) return;
      _publishItems();
      // Retain the entire unfinished workspace through its parent recovery
      // owner; do not consume it as a completed customer-facing item list.
      await leaveDraftRoute();
      return;
    }
    final save = widget.onSave;
    if (save == null) {
      await leaveDraftRoute(List<WorkLineItem>.of(_items));
      return;
    }
    _refresh(() => _saving = true);
    final saved = await save(List<WorkLineItem>.of(_items));
    if (!mounted) return;
    if (saved) {
      await finishDraftRoute(List<WorkLineItem>.of(_items));
    } else {
      _refresh(() => _saving = false);
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
          allowedTypes: _allowedTypes,
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
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
