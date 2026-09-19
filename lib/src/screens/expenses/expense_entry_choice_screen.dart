import 'dart:async';
import '../../data/expenses/expense_entry_setup_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../shared/app_preferences.dart';
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
    this.onChoiceApplied,
    this.workflow,
    this.initialCategory = ExpenseCategory.uncategorized,
    super.key,
  });
  final ExpenseEntrySetupWorkflow? workflow;

  /// Inline choice gate for new receipts opened directly from other modules.
  final ValueChanged<ExpenseEntryChoice>? onChoiceApplied;
  final bool canAttachReceipt;
  final bool canConfigureDisplay;
  final ExpenseCategory initialCategory;
  final Future<ExpenseEntrySetupWorkflow?> Function(ExpenseEntryChoice)?
  onContinue;
  @override
  State<ExpenseEntryChoiceScreen> createState() =>
      _ExpenseEntryChoiceScreenState();
}

class _ExpenseEntryChoiceScreenState extends State<ExpenseEntryChoiceScreen>
    with DraftNavigationGuard {
  StreamSubscription<DraftSaveState>? _saves;
  ExpenseEntrySetupWorkflow? _workflow;
  @override
  DraftAutosaveSession? get navigationDraft => _workflow?.session;
  @override
  bool get blockDraftNavigation => _continuing;
  @override
  void initState() {
    super.initState();
    _workflow = widget.workflow;
    _selected = widget.workflow?.input.detailChosen == true
        ? widget.workflow!.input.receiptType
        : null;
    _saves = navigationDraft?.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_saves?.cancel());
    super.dispose();
  }

  void _chooseDetail(ExpenseReceiptType type) {
    _workflow?.chooseDetail(type);
    setState(() => _selected = type);
  }

  var _fallback = const ReceiptIntakeDisplayPreferences();
  ExpenseReceiptType? _selected;
  late var _category =
      widget.workflow?.input.category ?? widget.initialCategory;
  var _continuing = false;
  bool get _inputLocked => _continuing || (navigationDraft?.isClosed ?? false);

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
        builder: (_) => ReceiptCategoryPickerScreen(
          initial: _category,
          workflow: _workflow,
        ),
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
    setState(() => _continuing = true);
    try {
      await navigationDraft?.flush();
      if (!mounted) return;
      final preferences = AppPreferencesScope.maybeOf(context);
      if (preferences != null &&
          !await preferences.rememberReceiptDetail(
            choice.type == ExpenseReceiptType.detailed,
          )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your receipt choice could not be saved. Please try again.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      if (widget.onChoiceApplied != null) {
        widget.onChoiceApplied!(choice);
        return;
      }
      if (widget.onContinue == null) {
        Navigator.pop(context, choice);
        return;
      }
      final returned = await widget.onContinue!(choice);
      if (returned == null && mounted) {
        await finishDraftRoute();
        return;
      }
      if (returned != null && mounted) {
        await _saves?.cancel();
        _workflow = returned;
        _selected = returned.input.receiptType;
        _category = returned.input.category;
        _saves = returned.session.changes.listen((_) {
          if (mounted) setState(() {});
        });
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your expense setup could not continue. Your saved input has been kept. Retry saving, then try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = readReceiptIntakeDisplayPreferences(context, _fallback);
    final mustChoose = _workflow != null
        ? !_workflow!.input.detailChosen
        : (AppPreferencesScope.maybeOf(context)?.chooseReceiptDetailEachTime ??
              false);
    final type =
        _selected ??
        (mustChoose
            ? null
            : (preferences.detailedReceipts
                  ? ExpenseReceiptType.detailed
                  : ExpenseReceiptType.basic));
    return guardDraftNavigation(
      Scaffold(
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
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
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
                        if (navigationDraft != null)
                          EditorDraftStatus(
                            state: navigationDraft!.state,
                            onRetry: () => _workflow!.retry(),
                          ),
                        Text(
                          'How much detail would you like to save?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ReceiptChoiceCard(
                          key: const ValueKey('receipt-total-only-choice'),
                          title: 'Basic receipt',
                          description:
                              'Save the total and an optional category. Individual items are not recorded.',
                          icon: Icons.receipt_outlined,
                          selected: type == ExpenseReceiptType.basic,
                          onTap: _inputLocked
                              ? null
                              : () => _chooseDetail(ExpenseReceiptType.basic),
                        ),
                        const SizedBox(height: 24),
                        ReceiptChoiceCard(
                          key: const ValueKey('receipt-every-item-choice'),
                          title: 'Detailed receipt',
                          description:
                              'Save the total, each item, how many you bought, and its price.',
                          icon: Icons.format_list_numbered,
                          selected: type == ExpenseReceiptType.detailed,
                          onTap: _inputLocked
                              ? null
                              : () =>
                                    _chooseDetail(ExpenseReceiptType.detailed),
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
                                onPressed: _inputLocked
                                    ? null
                                    : _chooseCategory,
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
                          onPressed: _continuing || type == null
                              ? null
                              : () => _continue(type),
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
      ),
    );
  }
}
