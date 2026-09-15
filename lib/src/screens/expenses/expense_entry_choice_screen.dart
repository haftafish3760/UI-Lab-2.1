import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';
import 'expense_models.dart';
import 'receipt_category_picker_screen.dart';
import 'receipt_choice_card.dart';
import 'receipt_intake_settings_screen.dart';

class ExpenseEntryChoice {
  const ExpenseEntryChoice({
    required this.withReceipt,
    required this.type,
    this.category = ExpenseCategory.uncategorized,
  });
  final bool withReceipt;
  final ExpenseReceiptType type;
  final ExpenseCategory category;
}

/// Receipt setup only. The next screen owns camera, files and text choices.
class ExpenseEntryChoiceScreen extends StatefulWidget {
  const ExpenseEntryChoiceScreen({
    required this.canAttachReceipt,
    this.canConfigureDisplay = true,
    this.onContinue,
    this.initialCategory = ExpenseCategory.uncategorized,
    super.key,
  });
  final bool canAttachReceipt;
  final bool canConfigureDisplay;
  final ExpenseCategory initialCategory;
  final Future<void> Function(ExpenseEntryChoice)? onContinue;
  @override
  State<ExpenseEntryChoiceScreen> createState() =>
      _ExpenseEntryChoiceScreenState();
}

class _ExpenseEntryChoiceScreenState extends State<ExpenseEntryChoiceScreen> {
  var _fallback = const ReceiptIntakeDisplayPreferences();
  ExpenseReceiptType? _selected;
  late var _category = widget.initialCategory;
  var _continuing = false;

  Future<void> _settings() async {
    final saved = readReceiptIntakeDisplayPreferences(context, _fallback);
    final result = await Navigator.of(context)
        .push<ReceiptIntakeDisplayPreferences>(
          MaterialPageRoute(
            builder: (_) => ReceiptIntakeSettingsScreen(initial: saved),
          ),
        );
    if (mounted && result != null) setState(() => _fallback = result);
  }

  Future<void> _chooseCategory() async {
    final result = await Navigator.of(context).push<ExpenseCategory>(
      MaterialPageRoute(
        builder: (_) => ReceiptCategoryPickerScreen(initial: _category),
      ),
    );
    if (mounted && result != null) setState(() => _category = result);
  }

  Future<void> _continue(ExpenseReceiptType type) async {
    if (_continuing) return;
    final choice = ExpenseEntryChoice(
      withReceipt: widget.canAttachReceipt,
      type: _selected ?? type,
      category: _category,
    );
    if (widget.onContinue == null) {
      Navigator.pop(context, choice);
      return;
    }
    setState(() => _continuing = true);
    try {
      await widget.onContinue!(choice);
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = readReceiptIntakeDisplayPreferences(context, _fallback);
    final type =
        _selected ??
        (preferences.detailedReceipts
            ? ExpenseReceiptType.detailed
            : ExpenseReceiptType.basic);
    return Scaffold(
      key: const ValueKey('expense-entry-choice-screen'),
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          if (widget.canConfigureDisplay)
            IconButton(
              onPressed: _continuing ? null : _settings,
              tooltip: 'Receipt settings',
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 24),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'What would you like to keep track of?',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 14),
                            ReceiptChoicePair(
                              first: ReceiptChoiceCard(
                                key: const ValueKey(
                                  'receipt-total-only-choice',
                                ),
                                title: 'Total only',
                                description:
                                    'Simple receipt. Save how much you spent.',
                                icon: Icons.receipt_outlined,
                                selected: type == ExpenseReceiptType.basic,
                                onTap: _continuing
                                    ? null
                                    : () => setState(
                                        () => _selected =
                                            ExpenseReceiptType.basic,
                                      ),
                              ),
                              second: ReceiptChoiceCard(
                                key: const ValueKey(
                                  'receipt-every-item-choice',
                                ),
                                title: 'Items and total',
                                description:
                                    'Detailed receipt. Save each item, its quantity and price.',
                                icon: Icons.format_list_numbered,
                                selected: type == ExpenseReceiptType.detailed,
                                onTap: _continuing
                                    ? null
                                    : () => setState(
                                        () => _selected =
                                            ExpenseReceiptType.detailed,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Category (optional)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'What was this expense for? You can decide later.',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                              key: const ValueKey('choose-receipt-category'),
                              onPressed: _continuing ? null : _chooseCategory,
                              icon: const Icon(Icons.category_outlined),
                              label: Text(
                                _category == ExpenseCategory.uncategorized
                                    ? 'Choose a category'
                                    : _category.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const ValueKey('continue-expense-setup'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: _continuing ? null : () => _continue(type),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
