import 'package:flutter/material.dart';
import 'expense_spending_summary.dart';
import 'expense_period_screen.dart';

import '../../data/operational_attention.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../data/receipts/receipt_draft_ui_adapter.dart';
import '../../data/receipts/receipt_draft_ui_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/operational_attention_panel.dart';
import '../../shared/section_card.dart';
import '../../shared/recorded_entries_section.dart';
import '../../shared/operational_section_heading.dart';
import '../../theme/operational_card_palette.dart';
import '../../shared/module_month_calendar.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_attention_screen.dart';
import 'expense_category_screen.dart';
import 'expense_detail_screen.dart';
import 'expense_editor_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_record_card.dart';
import 'expense_receipt_drafts_screen.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';
import 'receipt_intake_screen.dart';
import 'recurring_expense_repository_status.dart';
import 'removed_expenses_screen.dart';
import 'scheduled_expense_editor_screen.dart';
import 'scheduled_expenses_screen.dart';

part 'expenses_widgets.dart';
part 'expenses_home_layout.dart';
part 'expenses_collection_widgets.dart';

part 'expenses_day_screen.dart';
part 'expenses_day_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, this.initialExpenses, this.permissions});

  final List<ExpenseRecord>? initialExpenses;
  final ExpensePermissions? permissions;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _selectedDate = dashboardToday;
  late final List<ExpenseRecord>? _injectedExpenses;
  var _fixturePreferences = const ExpenseDisplayPreferences.defaults();
  ExpenseDisplayPreferences get _preferences =>
      readExpenseDisplayPreferences(context, _fixturePreferences);

  AppViewMode get _view => OperationalScope.of(context).view;
  String? get _selectedEmployeeId =>
      OperationalScope.of(context).selectedEmployeeId;
  ExpensePermissions get _permissions =>
      widget.permissions ?? expensePermissionsForView(_view);

  @override
  void initState() {
    super.initState();
    _injectedExpenses = widget.initialExpenses == null
        ? null
        : [...widget.initialExpenses!];
  }

  List<ExpenseRecord> get _expenses =>
      _injectedExpenses ?? PrototypeOperationsScope.of(context).expenses;

  @override
  Widget build(BuildContext context) => _buildExpenseHome(context);

  List<ExpenseRecord> get _scopeExpenses => _expenses
      .where(
        (record) => _view == AppViewMode.technician
            ? record.paidByEmployeeId ==
                  (_selectedEmployeeId ?? _permissions.actorEmployeeId)
            : _selectedEmployeeId == null ||
                  record.paidByEmployeeId == _selectedEmployeeId,
      )
      .toList();

  List<ExpenseRecord> get _visibleExpenses => _scopeExpenses.where((item) {
    final date = item.resolvedDate;
    return date != null && sameDashboardDay(date, _selectedDate);
  }).toList();

  List<ExpenseRecord> get _visibleDeletedExpenses {
    final records = PrototypeOperationsScope.of(context).deletedExpenses;
    return records
        .where((record) {
          final isOwn = _permissions.owns(
            paidByEmployeeId: record.paidByEmployeeId,
          );
          if (!_permissions.canRestoreRecord(isOwn: isOwn)) return false;
          if (_view == AppViewMode.technician) return isOwn;
          return _selectedEmployeeId == null ||
              record.paidByEmployeeId == _selectedEmployeeId;
        })
        .toList(growable: false);
  }

  OperationalAttentionQuery _attentionQuery() => OperationalAttentionQuery(
    panelId: 'expenses-home',
    module: OperationalAttentionModule.expenses,
    view: _view,
    access: _view == AppViewMode.admin
        ? const OperationalAttentionAccess.adminDevelopment()
        : const OperationalAttentionAccess.technicianDevelopment(),
    selectedEmployeeId: _selectedEmployeeId,
  );

  List<ExpenseReceiptDraft> get _visibleDrafts {
    final controller = ReceiptDraftUiScope.maybeOf(context);
    final drafts = controller == null
        ? PrototypeOperationsScope.of(context).expenseStore.receiptDrafts
        : controller.records
              .map(
                (stored) => ReceiptDraftUiAdapter.toUi(
                  stored,
                  (employeeId) => dashboardEmployeeById(employeeId).name,
                ),
              )
              .toList(growable: false);
    if (_view == AppViewMode.admin && _selectedEmployeeId == null) {
      return drafts.toList();
    }
    final ownerEmployeeId = _selectedEmployeeId ?? 'alex';
    return drafts
        .where((item) => item.ownerEmployeeId == ownerEmployeeId)
        .toList();
  }

  List<ScheduledExpenseRecord> get _visibleScheduledExpenses {
    final records =
        RecurringExpenseUiScope.maybeOf(context)?.records ??
        PrototypeOperationsScope.of(context).expenseStore.scheduledExpenses;
    final visible = _view == AppViewMode.admin && _selectedEmployeeId == null
        ? records
        : records.where(
            (item) =>
                item.owner ==
                dashboardEmployeeById(_selectedEmployeeId ?? 'alex').name,
          );
    return visible.toList()..sort((a, b) => a.nextDueOn.compareTo(b.nextDueOn));
  }

  void _changeView(AppViewMode view) {
    OperationalScope.of(context).setView(view);
  }

  void _changeEmployee(String? employeeId) {
    OperationalScope.of(context).selectEmployee(employeeId);
  }

  Future<void> _openSettings() async {
    if (!_permissions.canConfigureDisplay) return;
    final result = await Navigator.of(context).push<ExpenseDisplayPreferences>(
      MaterialPageRoute(
        builder: (_) => ExpensesSettingsScreen(initial: _preferences),
      ),
    );
    if (mounted && result != null) setState(() => _fixturePreferences = result);
  }

  Future<void> _recordExpense({
    ExpenseCategory initialCategory = ExpenseCategory.materials,
  }) async {
    if (!_permissions.canCreate) return;
    await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(
          expenseDate: _selectedDate,
          initialCategory: initialCategory,
          initialReceiptType: _preferences.receiptTypeFor(initialCategory),
          permissions: _permissions,
          onConfirm: (record) async {
            if (_injectedExpenses case final injected?) {
              setState(() => injected.insert(0, record));
              return record;
            }
            return PrototypeOperationsScope.of(context).addExpense(record);
          },
        ),
      ),
    );
  }

  void _openSpendingPeriod(String period) {
    if (!_permissions.canView || !_permissions.canViewAmounts) return;
    if (period == 'Day') { _openExpenseDay(_selectedDate); return; }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      ExpensePeriodScreen(period: period, anchor: _selectedDate,
        firstWeekday: _preferences.weekStartsOn, permissions: _permissions)));
  }

  void _openReceiptIntake() {
    if (!_permissions.canAttachReceipt) return;
    Navigator.of(context).push(
      MaterialPageRoute<ExpenseRecord>(
        builder: (_) => ReceiptIntakeScreen(
          expenseDate: _selectedDate,
          permissions: _permissions,
        ),
      ),
    );
  }

  void _openAttentionItem(OperationalAttentionItem item) {
    if (!_permissions.canViewAmounts) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(
          expenseId: item.sourceId,
          permissions: _permissions,
        ),
      ),
    );
  }

  void _openAttention(List<OperationalAttentionItem> items) {
    if (!_permissions.canViewAmounts) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExpenseAttentionScreen(items: items, permissions: _permissions),
      ),
    );
  }

  void _openReceiptDrafts() {
    if (!_permissions.canAttachReceipt) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseReceiptDraftsScreen(permissions: _permissions),
      ),
    );
  }

  void _openScheduledExpenses() {
    if (!_permissions.canManageScheduledExpenses) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScheduledExpensesScreen(permissions: _permissions),
      ),
    );
  }

  Future<void> _addScheduledExpense() async {
    if (!_permissions.canManageScheduledExpenses) return;
    final record = await Navigator.of(context).push<ScheduledExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseEditorScreen(
          permissions: _permissions,
          onConfirm: RecurringExpenseUiScope.maybeOf(context)?.create,
        ),
      ),
    );
    if (mounted && record != null) {
      final controller = RecurringExpenseUiScope.maybeOf(context);
      if (controller == null) {
        PrototypeOperationsScope.of(
          context,
        ).expenseStore.addScheduledExpense(record);
        return;
      }
    }
  }

  void _openExpense(ExpenseRecord expense) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ExpenseDetailScreen(expenseId: expense.id, permissions: _permissions),
    ),
  );

  void _openRemovedExpenses() {
    if (_visibleDeletedExpenses.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RemovedExpensesScreen(permissions: _permissions),
      ),
    );
  }

  void _openCategory(ExpenseCategory category) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ExpenseCategoryScreen(category: category, permissions: _permissions),
    ),
  );

  void _openExpenseDay(DateTime day) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExpensesDayScreen(day: day, permissions: _permissions),
    ),
  );
}
