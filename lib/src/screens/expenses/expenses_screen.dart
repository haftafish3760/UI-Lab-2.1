import 'package:flutter/material.dart';

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
import '../../shared/module_month_calendar.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import '../dashboard/employee_status_strip.dart';
import 'expense_attention_screen.dart';
import 'expense_category_screen.dart';
import 'expense_detail_screen.dart';
import 'expense_editor_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_record_card.dart';
import 'expense_receipt_drafts_screen.dart';
import 'expense_save_feedback.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';
import 'receipt_intake_screen.dart';
import 'recurring_expense_repository_status.dart';
import 'removed_expenses_screen.dart';
import 'scheduled_expense_editor_screen.dart';
import 'scheduled_expense_feedback.dart';
import 'scheduled_expenses_screen.dart';

part 'expenses_widgets.dart';
part 'expenses_collection_widgets.dart';
part 'expenses_add_actions_screen.dart';
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
  var _preferences = const ExpenseDisplayPreferences.defaults();

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
  Widget build(BuildContext context) {
    final permissions = _permissions;
    if (!permissions.canView) {
      return const Scaffold(
        key: ValueKey('expenses-module-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view expenses.'),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final availableWidth = constraints.maxWidth - insets.horizontal;
        final layout = AppLayoutEngine.operationsFor(
          availableWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final showInlineActions = layout.showsInlineModuleActions;
        final recurringController = RecurringExpenseUiScope.maybeOf(context);
        final showRecurringStatus =
            recurringController != null &&
            (recurringController.isLoading ||
                recurringController.phase == RecurringExpenseUiPhase.failed ||
                recurringController.showRecoveryNotice);
        final attentionQuery = _attentionQuery();
        final attentionCenter = PrototypeOperationsScope.of(
          context,
        ).attentionCenter;
        final attentionItems = attentionCenter.itemsFor(attentionQuery);
        final showAttention =
            permissions.canViewAmounts &&
            attentionCenter.shouldShow(attentionQuery, attentionItems);
        return Scaffold(
          key: const ValueKey('expenses-module-screen'),
          floatingActionButton: showInlineActions || !permissions.hasAddActions
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'expenses-record-fab',
                  onPressed: _showExpenseActions,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    permissions.canCreate ? 'Add expense' : 'Add receipt',
                  ),
                ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                SizedBox(
                  width: availableWidth,
                  child: OperationsWorkspaceFrame(
                    layout: layout,
                    primaryContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: _view,
                          selectedEmployeeId: _selectedEmployeeId,
                          onViewChanged: _changeView,
                          onEmployeeChanged: _changeEmployee,
                          onSettings: _openSettings,
                          showSettings: permissions.canConfigureDisplay,
                          showEmployeeStrip: false,
                        ),
                        const SizedBox(height: 14),
                        _ExpensesHeading(
                          view: _view,
                          selectedDate: _selectedDate,
                          dailyTotal: _visibleExpenses.fold<double>(
                            0,
                            (sum, item) => sum + item.amount,
                          ),
                          showDailyTotal: permissions.canViewAmounts,
                          showWideActions: showInlineActions,
                          onRecordExpense: permissions.canCreate
                              ? () => _recordExpense()
                              : null,
                          onRecordFuel: permissions.canCreate
                              ? () => _recordExpense(
                                  initialCategory: ExpenseCategory.fuel,
                                )
                              : null,
                          onAttachReceipt: permissions.canAttachReceipt
                              ? _openReceiptIntake
                              : null,
                        ),
                        if (showRecurringStatus) ...[
                          const SizedBox(height: 12),
                          const RecurringExpenseRepositoryStatus(),
                        ],
                        if (showAttention) ...[
                          const SizedBox(height: 12),
                          OperationsLaneGrid(
                            key: ValueKey(
                              'expenses-${layout.columns}-column-attention',
                            ),
                            layout: layout,
                            children: [
                              OperationalAttentionPanel(
                                key: const ValueKey('expenses-needs-attention'),
                                items: attentionItems,
                                rowKeyFor: (item) => ValueKey(
                                  'expense-attention-${item.sourceId}',
                                ),
                                onOpen: _openAttentionItem,
                                onOpenAll: () => _openAttention(attentionItems),
                                onDismiss: () => attentionCenter.dismiss(
                                  attentionQuery,
                                  attentionItems,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (permissions.canAttachReceipt) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: _ReceiptDraftSummary(
                                drafts: _visibleDrafts,
                                onOpen: _openReceiptDrafts,
                              ),
                            ),
                          ),
                        ],
                        if (_view == AppViewMode.admin) ...[
                          const SizedBox(height: 14),
                          EmployeeStatusStrip(
                            employees: demoEmployees,
                            selectedId: _selectedEmployeeId,
                            onSelected: (employee) =>
                                _changeEmployee(employee.id),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _ExpenseLanes(
                          layout: layout,
                          expenses: _visibleExpenses,
                          selectedDate: _selectedDate,
                          preferences: _preferences,
                          scheduledExpenses: _visibleScheduledExpenses,
                          showScheduled: permissions.canManageScheduledExpenses,
                          showAmounts: permissions.canViewAmounts,
                          removedExpenseCount: _visibleDeletedExpenses.length,
                          onOpenScheduled: _openScheduledExpenses,
                          onAddScheduled: _addScheduledExpense,
                          onOpenExpense: _openExpense,
                          onOpenCategory: _openCategory,
                          onOpenRemoved: _openRemovedExpenses,
                        ),
                      ],
                    ),
                    followingContent: _ExpensesCalendar(
                      view: _view,
                      maximumWidth: layout.laneWidth,
                      expenses: _expenses,
                      selectedDate: _selectedDate,
                      selectedEmployeeId: _selectedEmployeeId,
                      onDaySelected: _openExpenseDay,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ExpenseRecord> get _visibleExpenses => _expenses.where((item) {
    final date = item.resolvedDate;
    if (date == null || !sameDashboardDay(date, _selectedDate)) return false;
    if (_view == AppViewMode.technician) {
      return item.paidByEmployeeId == (_selectedEmployeeId ?? 'alex');
    }
    if (_selectedEmployeeId == null) return true;
    return item.paidByEmployeeId == _selectedEmployeeId;
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
    if (mounted && result != null) setState(() => _preferences = result);
  }

  Future<void> _showExpenseActions() async {
    if (!_permissions.hasAddActions) return;
    final action = await Navigator.of(context).push<_ExpenseAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ExpenseAddActionsScreen(
          date: _selectedDate,
          permissions: _permissions,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ExpenseAction.expense:
        if (!_permissions.canCreate) return;
        await _recordExpense();
      case _ExpenseAction.fuel:
        if (!_permissions.canCreate) return;
        await _recordExpense(initialCategory: ExpenseCategory.fuel);
      case _ExpenseAction.receipt:
        if (!_permissions.canAttachReceipt) return;
        _openReceiptIntake();
    }
  }

  Future<void> _recordExpense({
    ExpenseCategory initialCategory = ExpenseCategory.materials,
  }) async {
    if (!_permissions.canCreate) return;
    ExpenseRecord? draft;
    while (mounted) {
      if (!mounted) return;
      final record = await Navigator.of(context).push<ExpenseRecord>(
        MaterialPageRoute(
          builder: (_) => ExpenseEditorScreen(
            expenseDate: _selectedDate,
            initialCategory: initialCategory,
            initialReceiptType: _preferences.receiptTypeFor(initialCategory),
            existing: draft,
            permissions: _permissions,
          ),
        ),
      );
      if (!mounted || record == null) return;
      draft = record;
      if (_injectedExpenses case final injected?) {
        setState(() => injected.insert(0, record));
        return;
      }
      final saved = await PrototypeOperationsScope.of(
        context,
      ).addExpense(record);
      if (!mounted || saved != null) return;
      if (!await showExpenseSaveFailure(context)) return;
    }
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
        builder: (_) => ScheduledExpenseEditorScreen(permissions: _permissions),
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
      final saved = await controller.create(record);
      if (mounted && saved == null) await showScheduledExpenseFailure(context);
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
