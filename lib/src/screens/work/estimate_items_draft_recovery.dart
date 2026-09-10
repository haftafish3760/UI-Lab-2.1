part of 'estimate_items_screen.dart';

extension _EstimateItemsDraftRecovery on _EstimateItemsScreenState {
  Future<void> _saveItems() async {
    if (_saving || _pendingItem != null) return;
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
          allowedTypes: _allowedTypes,
          selectedDay: widget.selectedDay,
          workspaceLabel: 'Estimate item',
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
    final discard = widget.onDiscard;
    if (discard != null) {
      _refresh(() => _saving = true);
      final discarded = await discard();
      if (!mounted) return;
      if (discarded) {
        await finishDraftRoute();
      } else {
        _refresh(() => _saving = false);
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
