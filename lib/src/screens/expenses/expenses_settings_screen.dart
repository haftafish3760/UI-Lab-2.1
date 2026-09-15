import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/preferences/expense_display_preferences.dart';
import '../../data/preferences/expense_display_draft_input.dart';
import '../../data/storage/preference_draft_workflow.dart';
import '../../shared/expense_display_draft_workflow.dart';
export '../../data/preferences/expense_display_preferences.dart';
export '../../shared/preference_display_readers.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/app_preferences.dart';

import '../../shared/nested_editor_draft_status.dart';
import 'expense_models.dart';

part 'expense_settings_draft_recovery.dart';
part 'expense_settings_choice_dialogs.dart';

class ExpensesSettingsScreen extends StatefulWidget {
  const ExpensesSettingsScreen({
    this.initial = const ExpenseDisplayPreferences.defaults(),
    this.recoveredWorkflow,
    super.key,
  });

  final ExpenseDisplayPreferences initial;

  final PreferenceDraftWorkflow<ExpenseDisplayDraftInput>? recoveredWorkflow;

  @override
  State<ExpensesSettingsScreen> createState() => _ExpensesSettingsScreenState();
}

class _ExpensesSettingsScreenState extends State<ExpensesSettingsScreen>
    with DraftNavigationGuard {
  late var _weekStartsOn = widget.initial.weekStartsOn;
  late var _showJobLinks = widget.initial.showJobLinks;
  late var _categoryMode = widget.initial.categoryMode;
  late final _customCategories = widget.initial.customCategories.toSet();
  late final _receiptTypes = Map<ExpenseCategory, ExpenseReceiptType>.from(
    widget.initial.receiptTypes,
  );

  AppPreferencesController? get _saved => AppPreferencesScope.maybeOf(context);

  late PreferenceDraftWorkflow<ExpenseDisplayDraftInput>? _workflow =
      widget.recoveredWorkflow;
  DraftAutosaveSession? get _session => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _session;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_openInput());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_session?.close().catchError((Object _) {}));
    super.dispose();
  }

  Set<ExpenseCategory>? _pendingCategories;
  Map<ExpenseCategory, ExpenseReceiptType>? _pendingReceiptTypes;
  ExpenseDisplayPreferences get _current => ExpenseDisplayPreferences(
    weekStartsOn: _weekStartsOn,
    showJobLinks: _showJobLinks,
    categoryMode: _categoryMode,
    customCategories: _customCategories.toList(),
    receiptTypes: Map.of(_receiptTypes),
  );
  void _edit(VoidCallback change) {
    setState(() {
      change();
      _error = null;
    });
    _capture();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(title: const Text('Expense screen settings')),
      body: !_ready
          ? Center(child: Text(_error ?? 'Opening saved input…'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_session != null)
                      EditorDraftStatus(
                        state: _session!.state,
                        onRetry: _session!.retry,
                        onDiscard: _discard,
                      ),
                    if (_error != null) Text(_error!),
                    if (_pendingCategories != null ||
                        _pendingReceiptTypes != null)
                      const Text(
                        'Finish or cancel your unfinished choices before saving settings.',
                      ),
                    if (_pendingCategories != null &&
                        _categoryMode != ExpenseCategoryDisplayMode.custom)
                      TextButton(
                        onPressed: _saving ? null : _chooseCategories,
                        child: const Text('Continue category choices'),
                      ),

                    DropdownButtonFormField<int>(
                      key: const ValueKey('expense-week-start'),
                      initialValue: _weekStartsOn,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Business week starts on',
                      ),
                      items: [
                        for (var day = 1; day <= 7; day++)
                          DropdownMenuItem(
                            value: day,
                            child: Text(_weekdayName(context, day)),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (day) {
                              if (day != null) _edit(() => _weekStartsOn = day);
                            },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ends on ${_weekdayName(context, (_weekStartsOn + 5) % 7 + 1)}. Used for weekly expense totals and entries.',
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show related jobs'),
                      value: _showJobLinks,
                      onChanged: _saving
                          ? null
                          : (value) => _edit(() => _showJobLinks = value),
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
                            onSelected: _saving
                                ? null
                                : (_) => _edit(() => _categoryMode = mode),
                          ),
                      ],
                    ),
                    if (_categoryMode == ExpenseCategoryDisplayMode.custom) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const ValueKey('choose-expense-categories-button'),
                        onPressed: _saving ? null : _chooseCategories,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(
                          _pendingCategories != null
                              ? 'Continue category choices'
                              : 'Choose categories (${_customCategories.length}/10)',
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    ListTile(
                      key: const ValueKey('expense-receipt-type-settings'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        _pendingReceiptTypes != null
                            ? 'Continue receipt-type choices'
                            : 'Receipt types by category',
                      ),
                      subtitle: Text(_receiptTypeSummary),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _saving ? null : _chooseReceiptTypes,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TextButton(
                          onPressed:
                              _saving ||
                                  _pendingCategories != null ||
                                  _pendingReceiptTypes != null
                              ? null
                              : _restoreDefaults,
                          child: const Text('Restore defaults'),
                        ),
                        FilledButton.icon(
                          key: const ValueKey('save-expense-settings-button'),
                          onPressed: _saving ? null : _confirm,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    ),
  );

  void _restoreDefaults() => _edit(() {
    _showJobLinks = true;
    _categoryMode = ExpenseCategoryDisplayMode.off;
    _customCategories.clear();
    _receiptTypes
      ..clear()
      ..[ExpenseCategory.materials] = ExpenseReceiptType.detailed;
  });

  String get _receiptTypeSummary {
    final detailed = _receiptTypes.entries
        .where((e) => e.value == ExpenseReceiptType.detailed)
        .map((e) => e.key)
        .toList();
    if (detailed.isEmpty) return 'All categories: Simple';
    if (detailed.length == 1 && detailed.single == ExpenseCategory.materials) {
      return 'Materials: Detailed · Others: Simple';
    }
    return 'Detailed receipts: ${detailed.length} categories · Other categories: Simple';
  }

  String _categoryModeLabel(ExpenseCategoryDisplayMode mode) => switch (mode) {
    ExpenseCategoryDisplayMode.off => 'Off',
    ExpenseCategoryDisplayMode.topTen => 'Top 10',
    ExpenseCategoryDisplayMode.custom => 'Custom',
  };
}

String _weekdayName(BuildContext context, int day) => MaterialLocalizations.of(
  context,
).formatFullDate(DateTime(2026, 6, day)).split(',').first;
