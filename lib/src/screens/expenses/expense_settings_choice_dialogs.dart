part of 'expenses_settings_screen.dart';

extension _ExpenseSettingsChoiceDialogs on _ExpensesSettingsScreenState {
  Future<void> _chooseCategories() async {
    final selected = _pendingCategories ?? {..._customCategories};
    _pendingCategories = selected;
    _capture();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Category shortcuts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_session != null) NestedEditorDraftStatus(session: _session!),
              Flexible(
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in ExpenseCategory.values)
                          FilterChip(
                            label: Text(category.label),
                            selected: selected.contains(category),
                            onSelected: (value) => setDialogState(() {
                              if (value && selected.length < 10) {
                                selected.add(category);
                              } else if (!value) {
                                selected.remove(category);
                              }
                              _capture();
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _edit(() => _pendingCategories = null);
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _edit(() {
                  _customCategories
                    ..clear()
                    ..addAll(selected);
                  _pendingCategories = null;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Use categories'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseReceiptTypes() async {
    final selected = _pendingReceiptTypes ?? {..._receiptTypes};
    _pendingReceiptTypes = selected;
    _capture();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Receipt types by category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_session != null) NestedEditorDraftStatus(session: _session!),
              Flexible(
                child: SizedBox(
                  width: 520,
                  height: 460,
                  child: ListView(
                    children: [
                      for (final category in ExpenseCategory.values)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(category.icon, size: 20),
                          title: Text(category.label),
                          trailing: DropdownButton<ExpenseReceiptType>(
                            value:
                                selected[category] ?? ExpenseReceiptType.basic,
                            items: [
                              for (final type in ExpenseReceiptType.values)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                            ],
                            onChanged: (value) => setDialogState(() {
                              if (value == null ||
                                  value == ExpenseReceiptType.basic) {
                                selected.remove(category);
                              } else {
                                selected[category] = value;
                              }
                              _capture();
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _edit(() => _pendingReceiptTypes = null);
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _edit(() {
                  _receiptTypes
                    ..clear()
                    ..addAll(selected);
                  _pendingReceiptTypes = null;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Use receipt types'),
            ),
          ],
        ),
      ),
    );
  }
}
