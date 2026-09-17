import '../../data/expenses/expense_entry_setup_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_theme.dart';
import 'expense_models.dart';

/// Adapted from 5.7 Rebuild's receipt category picker: staged selection,
/// searchable common/all lists, and explicit Cancel/Done. No legacy stores.
class ReceiptCategoryPickerScreen extends StatefulWidget {
  const ReceiptCategoryPickerScreen({
    required this.initial,
    this.workflow,
    super.key,
  });
  final ExpenseCategory initial;
  final ExpenseEntrySetupWorkflow? workflow;

  @override
  State<ReceiptCategoryPickerScreen> createState() =>
      _ReceiptCategoryPickerState();
}

class _ReceiptCategoryPickerState extends State<ReceiptCategoryPickerScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.workflow?.session;
  Future<void> _finish(bool accept) async {
    if (accept) {
      widget.workflow?.proposeCategory(_selected);
      widget.workflow?.acceptCategory();
    } else {
      widget.workflow?.cancelCategory();
    }
    await leaveDraftRoute(accept ? _selected : null);
  }

  late var _selected = widget.workflow?.input.pendingCategory ?? widget.initial;
  var _query = '';

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(title: const Text('Select a category')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            bool matches(ExpenseCategory c) =>
                c.label.toLowerCase().contains(_query.trim().toLowerCase());
            final common = commonReceiptCategories.where(matches).toList();
            final other =
                receiptCategories
                    .where(
                      (c) =>
                          c != ExpenseCategory.uncategorized &&
                          !commonReceiptCategories.contains(c) &&
                          matches(c),
                    )
                    .toList()
                  ..sort((a, b) => a.label.compareTo(b.label));
            return Center(
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose what this expense was for. You can leave it without a category or change it before saving.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('receipt-category-search'),
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search categories',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            _category(ExpenseCategory.uncategorized),
                            if (widget.initial !=
                                    ExpenseCategory.uncategorized &&
                                !receiptCategories.contains(widget.initial) &&
                                matches(widget.initial)) ...[
                              _heading('Current category'),
                              _category(widget.initial),
                            ],
                            if (common.isNotEmpty) ...[
                              _heading('Common categories'),
                              ...common.map(_category),
                            ],
                            if (other.isNotEmpty) ...[
                              _heading('All categories'),
                              ...other.map(_category),
                            ],
                            if (common.isEmpty &&
                                other.isEmpty &&
                                _query.trim().isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'No matching categories. Try another search.',
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                              onPressed: () => _finish(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              key: const ValueKey('confirm-receipt-category'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                              ),
                              onPressed: () => _finish(true),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _category(ExpenseCategory category) {
    final selected = category == _selected;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        child: SectionCard(
          padding: EdgeInsets.zero,
          backgroundColor: selected ? colors.primaryContainer : colors.surface,
          borderColor: selected ? colors.primary : colors.outline,
          child: ListTile(
            key: ValueKey('receipt-category-${category.name}'),
            minVerticalPadding: 16,
            title: Text(
              category.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: selected ? const Icon(Icons.check) : null,
            onTap: () {
              widget.workflow?.proposeCategory(category);
              setState(() => _selected = category);
            },
          ),
        ),
      ),
    );
  }
}
