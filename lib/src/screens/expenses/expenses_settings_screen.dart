import 'package:flutter/material.dart';

import 'expense_models.dart';

enum ExpenseCategoryDisplayMode { off, topTen, custom }

@immutable
class ExpenseDisplayPreferences {
  const ExpenseDisplayPreferences({
    required this.showJobLinks,
    required this.categoryMode,
    this.customCategories = const [],
    this.receiptTypes = const {
      ExpenseCategory.materials: ExpenseReceiptType.detailed,
    },
  });

  const ExpenseDisplayPreferences.defaults()
    : showJobLinks = true,
      categoryMode = ExpenseCategoryDisplayMode.off,
      customCategories = const [],
      receiptTypes = const {
        ExpenseCategory.materials: ExpenseReceiptType.detailed,
      };

  final bool showJobLinks;
  final ExpenseCategoryDisplayMode categoryMode;
  final List<ExpenseCategory> customCategories;
  final Map<ExpenseCategory, ExpenseReceiptType> receiptTypes;

  ExpenseReceiptType receiptTypeFor(ExpenseCategory category) =>
      receiptTypes[category] ?? ExpenseReceiptType.basic;
}

class ExpensesSettingsScreen extends StatefulWidget {
  const ExpensesSettingsScreen({
    this.initial = const ExpenseDisplayPreferences.defaults(),
    super.key,
  });

  final ExpenseDisplayPreferences initial;

  @override
  State<ExpensesSettingsScreen> createState() => _ExpensesSettingsScreenState();
}

class _ExpensesSettingsScreenState extends State<ExpensesSettingsScreen> {
  late var _showJobLinks = widget.initial.showJobLinks;
  late var _categoryMode = widget.initial.categoryMode;
  late final _customCategories = widget.initial.customCategories.toSet();
  late final _receiptTypes = Map<ExpenseCategory, ExpenseReceiptType>.from(
    widget.initial.receiptTypes,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Expense screen settings')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show related jobs'),
              value: _showJobLinks,
              onChanged: (value) => setState(() => _showJobLinks = value),
            ),
            const Divider(height: 24),
            Text(
              'Category shortcuts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in ExpenseCategoryDisplayMode.values)
                  ChoiceChip(
                    key: ValueKey('expense-category-mode-${mode.name}'),
                    label: Text(_categoryModeLabel(mode)),
                    selected: _categoryMode == mode,
                    onSelected: (_) => setState(() => _categoryMode = mode),
                  ),
              ],
            ),
            if (_categoryMode == ExpenseCategoryDisplayMode.custom) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('choose-expense-categories-button'),
                onPressed: _chooseCategories,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  'Choose categories (${_customCategories.length}/10)',
                ),
              ),
            ],
            const Divider(height: 24),
            ListTile(
              key: const ValueKey('expense-receipt-type-settings'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Receipt types by category'),
              subtitle: const Text('Materials: Detailed · Others: Basic'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _chooseReceiptTypes,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                TextButton(
                  onPressed: _restoreDefaults,
                  child: const Text('Restore defaults'),
                ),
                FilledButton.icon(
                  key: const ValueKey('save-expense-settings-button'),
                  onPressed: () => Navigator.pop(
                    context,
                    ExpenseDisplayPreferences(
                      showJobLinks: _showJobLinks,
                      categoryMode: _categoryMode,
                      customCategories: _customCategories.toList(
                        growable: false,
                      ),
                      receiptTypes: Map.unmodifiable(_receiptTypes),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _chooseCategories() async {
    final selected = {..._customCategories};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Category shortcuts'),
          content: SizedBox(
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
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _customCategories
                    ..clear()
                    ..addAll(selected);
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
    final selected = {..._receiptTypes};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Receipt types by category'),
          content: SizedBox(
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
                      value: selected[category] ?? ExpenseReceiptType.basic,
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
                      }),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _receiptTypes
                    ..clear()
                    ..addAll(selected);
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

  void _restoreDefaults() => setState(() {
    _showJobLinks = true;
    _categoryMode = ExpenseCategoryDisplayMode.off;
    _customCategories.clear();
    _receiptTypes
      ..clear()
      ..[ExpenseCategory.materials] = ExpenseReceiptType.detailed;
  });

  String _categoryModeLabel(ExpenseCategoryDisplayMode mode) => switch (mode) {
    ExpenseCategoryDisplayMode.off => 'Off',
    ExpenseCategoryDisplayMode.topTen => 'Top 10',
    ExpenseCategoryDisplayMode.custom => 'Custom',
  };
}
