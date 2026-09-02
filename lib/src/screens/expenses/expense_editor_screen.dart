import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_line_item_editor.dart';
import 'expense_line_items_editor.dart';
import 'expense_input_validation.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'expense_receipt_form_widgets.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

part 'expense_purchase_fields.dart';

class ExpenseEditorScreen extends StatefulWidget {
  const ExpenseEditorScreen({
    required this.expenseDate,
    this.initialCategory = ExpenseCategory.materials,
    this.initialReceiptType = ExpenseReceiptType.basic,
    this.initialReceiptImageCount = 0,
    this.initialJobId,
    this.initialJobLabel,
    this.existing,
    this.permissions = const ExpensePermissions.development(),
    this.purpose = ExpenseEditorPurpose.manualEntry,
    this.existingRecordIsOwn = true,
    super.key,
  });

  final DateTime expenseDate;
  final ExpenseCategory initialCategory;
  final ExpenseReceiptType initialReceiptType;
  final int initialReceiptImageCount;
  final String? initialJobId;
  final String? initialJobLabel;
  final ExpenseRecord? existing;
  final ExpensePermissions permissions;
  final ExpenseEditorPurpose purpose;
  final bool existingRecordIsOwn;

  @override
  State<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends State<ExpenseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendor = TextEditingController();
  final _amount = TextEditingController();
  final _subtotal = TextEditingController();
  final _salesTax = TextEditingController(text: '0.00');
  final _job = TextEditingController();
  late var _category = widget.existing?.category ?? widget.initialCategory;
  late var _receiptType =
      widget.existing?.receiptType ?? widget.initialReceiptType;
  late var _expenseDate = DateUtils.dateOnly(
    widget.existing?.resolvedDate ?? widget.expenseDate,
  );
  late var _prepareMaterialsReview =
      widget.existing?.prepareMaterialsReview ?? false;
  late final List<ExpenseLineItem> _lineItems = [
    ...?widget.existing?.lineItems,
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _vendor.text = existing.vendor;
      _amount.text = existing.amount.toStringAsFixed(2);
      _subtotal.text = existing.resolvedReceiptSubtotal.toStringAsFixed(2);
      _salesTax.text = existing.salesTax.toStringAsFixed(2);
      _job.text = existing.job ?? '';
    } else {
      _job.text = widget.initialJobLabel ?? '';
    }
  }

  @override
  void dispose() {
    _vendor.dispose();
    _amount.dispose();
    _subtotal.dispose();
    _salesTax.dispose();
    _job.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canUseEditor(
      isExisting: widget.existing != null,
      isOwn: widget.existingRecordIsOwn,
      purpose: widget.purpose,
    )) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('expense-editor-screen'),
        message: 'You do not have permission to change this expense.',
      );
    }
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('expense-editor-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final formWidth = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              key: const ValueKey('expense-editor-scroll'),
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
              children: [
                Center(
                  child: SizedBox(
                    width: formWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: _openSettings,
                          showSettings: widget.permissions.canConfigureDisplay,
                          workspaceLabel: 'Expense Entry',
                          showBackButton: true,
                          onBack: () => Navigator.of(context).pop(),
                          showEmployeeStrip: false,
                          contextKey: const ValueKey(
                            'expense-editor-context-selector',
                          ),
                          viewKey: const ValueKey(
                            'expense-editor-view-selector',
                          ),
                          settingsKey: const ValueKey(
                            'expense-editor-settings-button',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.existing == null
                              ? 'Record an expense'
                              : widget.existing!.receiptImageCount > 0
                              ? 'Correct receipt'
                              : 'Edit expense',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(operationalDateLabel(context, _expenseDate)),
                        const SizedBox(height: 14),
                        SectionCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PurchaseFields(
                                  vendorController: _vendor,
                                  jobController: _job,
                                  expenseDate: _expenseDate,
                                  category: _category,
                                  onChooseDate: _chooseDate,
                                  onCategoryChanged: (value) =>
                                      setState(() => _category = value),
                                ),
                                const SizedBox(height: 12),
                                ReceiptDetailChoice(
                                  value: _receiptType,
                                  onChanged: (value) => setState(() {
                                    _receiptType = value;
                                    if (value == ExpenseReceiptType.basic) {
                                      _prepareMaterialsReview = false;
                                    }
                                  }),
                                ),
                                if (_receiptType ==
                                    ExpenseReceiptType.detailed) ...[
                                  const SizedBox(height: 12),
                                  ExpenseLineItemsEditor(
                                    items: _lineItems,
                                    onAdd: _addLine,
                                    onEdit: _editLine,
                                    onDelete: _deleteLine,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ReceiptTotalsFields(
                                  lineSubtotal: _lineSubtotal,
                                  subtotalController: _subtotal,
                                  salesTaxController: _salesTax,
                                  totalController: _amount,
                                  onComponentsChanged:
                                      _updateFinalTotalFromComponents,
                                  totalValidator: _validateAmount,
                                ),
                                if (_receiptType ==
                                    ExpenseReceiptType.detailed) ...[
                                  const SizedBox(height: 12),
                                  MaterialsFollowupChoice(
                                    prepareMaterialsReview:
                                        _prepareMaterialsReview,
                                    onChanged: (value) => setState(
                                      () => _prepareMaterialsReview = value,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  key: const ValueKey('save-expense-button'),
                                  onPressed: _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    widget.existing == null
                                        ? 'Save expense'
                                        : widget.existing!.receiptImageCount > 0
                                        ? 'Review correction'
                                        : 'Save changes',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    return validateRequiredExpenseMoney(value);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_receiptType == ExpenseReceiptType.detailed && _lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one receipt item, or choose Save the receipt total.',
          ),
        ),
      );
      return;
    }
    final scope = OperationalScope.of(context);
    final ownerId = scope.view == AppViewMode.technician
        ? demoEmployees.first.id
        : scope.selectedEmployeeId;
    final owner = demoEmployees
        .firstWhere(
          (employee) => employee.id == ownerId,
          orElse: () => demoEmployees.first,
        )
        .name;
    final existing = widget.existing;
    final amount = double.parse(_amount.text.replaceAll(',', '').trim());
    final subtotal = _optionalMoney(_subtotal.text) ?? _lineSubtotal;
    final salesTax = _optionalMoney(_salesTax.text) ?? 0;
    final job = _job.text.trim().isEmpty ? null : _job.text.trim();
    final result = existing == null
        ? ExpenseRecord(
            id: 'EXP-${DateTime.now().microsecondsSinceEpoch}',
            vendor: _vendor.text.trim(),
            category: _category,
            amount: amount,
            date: _expenseDate,
            owner: owner,
            paidByEmployeeId: ownerId ?? demoEmployees.first.id,
            job: job,
            jobId: widget.initialJobId,
            receiptStatus: widget.initialReceiptImageCount > 0
                ? 'Receipt attached'
                : 'No receipt attached',
            receiptType: _receiptType,
            receiptImageCount: widget.initialReceiptImageCount,
            lineItems: List.unmodifiable(_lineItems),
            receiptSubtotal: subtotal > 0 ? subtotal : null,
            salesTax: salesTax,
            prepareMaterialsReview: _prepareMaterialsReview,
          )
        : existing.copyWith(
            vendor: _vendor.text.trim(),
            category: _category,
            amount: amount,
            job: job,
            receiptType: _receiptType,
            lineItems: List.unmodifiable(_lineItems),
            receiptSubtotal: subtotal > 0 ? subtotal : null,
            salesTax: salesTax,
            prepareMaterialsReview:
                _receiptType == ExpenseReceiptType.detailed &&
                _prepareMaterialsReview,
            requiresSubmitterAttention: false,
            submitterAttentionReason: null,
            receiptStatus: existing.requiresSubmitterAttention
                ? 'Receipt reviewed'
                : existing.receiptStatus,
          );
    Navigator.of(context).pop(result);
  }

  Future<void> _addLine() async {
    final line = await showExpenseLineItemEditor(
      context,
      defaultCategory: _category,
      jobId: widget.existing?.jobId ?? widget.initialJobId,
      jobLabel: _job.text.trim().isEmpty ? null : _job.text.trim(),
    );
    if (line != null) {
      setState(() => _lineItems.add(line));
      _syncTotalsFromLines();
    }
  }

  Future<void> _editLine(ExpenseLineItem item) async {
    final updated = await showExpenseLineItemEditor(
      context,
      initial: item,
      defaultCategory: _category,
    );
    if (updated == null) return;
    setState(() {
      final index = _lineItems.indexWhere(
        (candidate) => candidate.id == item.id,
      );
      if (index >= 0) _lineItems[index] = updated;
    });
    _syncTotalsFromLines();
  }

  void _deleteLine(ExpenseLineItem item) {
    setState(
      () => _lineItems.removeWhere((candidate) => candidate.id == item.id),
    );
    _syncTotalsFromLines();
  }

  double get _lineSubtotal =>
      _lineItems.fold(0, (sum, item) => sum + item.total);

  double? _optionalMoney(String value) {
    final clean = value.replaceAll(',', '').trim();
    return clean.isEmpty ? null : double.tryParse(clean);
  }

  void _syncTotalsFromLines() {
    if (_lineItems.isEmpty) return;
    _subtotal.text = _lineSubtotal.toStringAsFixed(2);
    _updateFinalTotalFromComponents();
  }

  void _updateFinalTotalFromComponents() {
    final subtotal = _optionalMoney(_subtotal.text);
    final tax = _optionalMoney(_salesTax.text) ?? 0;
    if (subtotal != null) _amount.text = (subtotal + tax).toStringAsFixed(2);
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(_expenseDate.year - 10),
      lastDate: DateTime(_expenseDate.year + 2),
      helpText: 'Choose receipt date',
    );
    if (selected != null && mounted) {
      setState(() => _expenseDate = DateUtils.dateOnly(selected));
    }
  }

  void _openSettings() {
    if (!widget.permissions.canConfigureDisplay) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExpensesSettingsScreen()),
    );
  }
}
