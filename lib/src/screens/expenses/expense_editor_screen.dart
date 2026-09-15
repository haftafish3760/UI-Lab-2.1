import 'dart:async';
import '../../data/receipts/receipt_field_proposals.dart';

import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../shared/local_draft_scope.dart';
import '../../shared/editor_draft_status.dart';
import '../../data/receipts/receipt_submission_session.dart';
import '../../shared/draft_navigation_guard.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/utility_form_section.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_line_item_editor.dart';
import 'expense_line_items_editor.dart';
import 'expense_input_validation.dart';
import 'expense_models.dart';
import '../../data/expenses/expense_draft_input.dart';
import '../../data/expenses/expense_draft_workflow.dart';
import '../../data/receipts/receipt_review_draft_workflow.dart';
import '../../data/storage/draft_workflow_controller.dart';
import '../../data/storage/draft_recovery_query.dart';
import '../../data/expenses/expense_line_draft_input.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';
import 'expense_receipt_form_widgets.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

part 'expense_purchase_fields.dart';
part 'expense_editor_draft_recovery.dart';
part 'expense_editor_confirmation.dart';
part 'expense_editor_line_recovery.dart';
part 'receipt_review_draft_recovery.dart';

class ExpenseEditorScreen extends StatefulWidget {
  const ExpenseEditorScreen({
    required this.expenseDate,
    this.suggestedDetails,
    this.startNewExpense = false,
    this.initialCategory = ExpenseCategory.uncategorized,
    this.initialReceiptType = ExpenseReceiptType.basic,
    this.initialReceiptImageCount = 0,
    this.initialJobId,
    this.initialJobLabel,
    this.initialLineId,
    this.receiptDraftId,
    this.existing,
    this.recoveredExpenseWorkflow,
    this.recoveredReceiptWorkflow,
    this.onConfirm,
    this.permissions = const ExpensePermissions.development(),
    this.purpose = ExpenseEditorPurpose.manualEntry,
    this.existingRecordIsOwn = true,
    super.key,
  });

  final DateTime expenseDate;
  final ReceiptFieldProposals? suggestedDetails;
  final bool startNewExpense;
  final ExpenseCategory initialCategory;
  final ExpenseReceiptType initialReceiptType;
  final int initialReceiptImageCount;
  final String? initialJobId;
  final String? initialJobLabel;
  final String? initialLineId;
  final String? receiptDraftId;
  final Future<ExpenseRecord?> Function(ExpenseRecord)? onConfirm;
  final ExpenseRecord? existing;

  /// The editor owns and closes a transferred workflow, retaining saved input.
  final ExpenseDraftController? recoveredExpenseWorkflow;
  final ReceiptReviewDraftController? recoveredReceiptWorkflow;
  final ExpensePermissions permissions;
  final ExpenseEditorPurpose purpose;
  final bool existingRecordIsOwn;

  @override
  State<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends State<ExpenseEditorScreen>
    with DraftNavigationGuard {
  int? _receiptSourceRevision;
  late int _draftImageCount =
      widget.existing?.receiptImageCount ?? widget.initialReceiptImageCount;
  ExpenseRecord? _editingBase;
  int? _baseRevision;
  final _correctionReason = TextEditingController();
  PendingExpenseLineInput? _pendingLine;
  late DraftAutosaveSession? _draft =
      widget.recoveredExpenseWorkflow?.session ??
      widget.recoveredReceiptWorkflow?.session;
  ExpenseDraftController? _expenseWorkflow;
  ReceiptReviewDraftController? _receiptWorkflow;
  DraftWorkflowController<ExpenseDraftInput>? _inputWorkflow;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  ExpenseUiRepositoryController? _expenseController;
  bool _draftOpening = true;
  bool _draftStarted = false;
  String? _draftOwnerId;
  String? _draftOwnerLabel;
  late String? _draftJobId = widget.initialJobId;
  void _refresh(VoidCallback change) => setState(change);
  bool _saving = false;
  String? _confirmationError;
  late var _expenseId = widget.existing?.id ?? newLocalRecordIdentity('EXP');
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;

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
      _amount.text = existing.amount?.toStringAsFixed(2) ?? '';
      _subtotal.text = existing.resolvedReceiptSubtotal.toStringAsFixed(2);
      _salesTax.text = existing.salesTax.toStringAsFixed(2);
      _job.text = existing.job ?? '';
    } else {
      _job.text = widget.initialJobLabel ?? '';
      final suggested = widget.suggestedDetails;
      if (suggested != null) {
        String amount(int minor) =>
            '${minor < 0 ? '-' : ''}${minor.abs() ~/ 100}.${(minor.abs() % 100).toString().padLeft(2, '0')}';
        _vendor.text = suggested.merchant ?? '';
        if (suggested.date case final date?) _expenseDate = date;
        if (suggested.totalMinor case final total?) {
          _amount.text = amount(total);
        }
        if (suggested.subtotalMinor case final subtotal?) {
          _subtotal.text = amount(subtotal);
        }
        if (suggested.taxMinor case final tax?) _salesTax.text = amount(tax);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draftStarted) return;
    _draftStarted = true;
    _expenseController = ExpenseUiScope.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openExpenseDraft());
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _correctionReason.dispose();
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
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('expense-editor-screen'),
        body: _draftOpening && _confirmationError == null
            ? const Center(child: Text('Opening saved input…'))
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final insets = AppLayoutEngine.pageInsetsFor(
                      constraints.maxWidth,
                    );
                    final formWidth = AppLayoutEngine.formWorkspaceWidthFor(
                      constraints.maxWidth - insets.horizontal,
                    );
                    return ListView(
                      key: const ValueKey('expense-editor-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        insets.left,
                        10,
                        insets.right,
                        96,
                      ),
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
                                  onViewChanged: (view) {
                                    scope.setView(view);
                                    _updateExpenseDraftOwner();
                                  },
                                  onEmployeeChanged: (employee) {
                                    scope.selectEmployee(employee);
                                    _updateExpenseDraftOwner();
                                  },
                                  onSettings: _openSettings,
                                  showSettings:
                                      widget.permissions.canConfigureDisplay,
                                  workspaceLabel: 'Expense Entry',
                                  showBackButton: true,
                                  onBack: () => leaveDraftRoute(),
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
                                if (_draft != null)
                                  EditorDraftStatus(
                                    state: _draft!.state,
                                    onRetry: _draft!.retry,
                                    onDiscard: _saving
                                        ? null
                                        : _discardExpenseDraft,
                                  ),
                                if (_confirmationError != null)
                                  Text(_confirmationError!),
                                const SizedBox(height: 14),
                                Text(
                                  widget.existing == null
                                      ? 'Record an expense'
                                      : widget.existing!.receiptImageCount > 0
                                      ? 'Correct receipt'
                                      : 'Edit expense',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  operationalDateLabel(context, _expenseDate),
                                ),
                                const SizedBox(height: 14),
                                UtilityFormSection(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _PurchaseFields(
                                          vendorController: _vendor,
                                          requireVendor:
                                              _receiptType ==
                                              ExpenseReceiptType.detailed,
                                          jobController: _job,
                                          expenseDate: _expenseDate,
                                          category: _category,
                                          onChooseDate: _chooseDate,
                                          onCategoryChanged: (value) =>
                                              _changeExpenseInput(
                                                () => _category = value,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        ReceiptDetailChoice(
                                          value: _receiptType,
                                          onChanged: (value) =>
                                              _changeExpenseInput(() {
                                                _receiptType = value;
                                                if (value ==
                                                    ExpenseReceiptType.basic) {
                                                  _prepareMaterialsReview =
                                                      false;
                                                }
                                              }),
                                        ),
                                        if (_pendingLine != null) ...[
                                          TextButton(
                                            onPressed: _addLine,
                                            child: const Text(
                                              'Continue unfinished item',
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                _discardPendingExpenseLine,
                                            child: const Text(
                                              'Discard unfinished item',
                                            ),
                                          ),
                                        ],
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
                                          simple:
                                              _receiptType ==
                                              ExpenseReceiptType.basic,
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
                                            onChanged: (value) =>
                                                _changeExpenseInput(
                                                  () =>
                                                      _prepareMaterialsReview =
                                                          value,
                                                ),
                                          ),
                                        ],
                                        if (_draft != null &&
                                            _editingBase != null &&
                                            _expenseController
                                                    ?.receiptIdForExpense(
                                                      _expenseId,
                                                    ) !=
                                                null)
                                          TextFormField(
                                            key: const ValueKey(
                                              'expense-editor-correction-reason',
                                            ),
                                            controller: _correctionReason,
                                            decoration: InputDecoration(
                                              labelText: 'Correction reason',
                                              helperText:
                                                  _editingBase!
                                                          .approvalStatus !=
                                                      ExpenseApprovalStatus
                                                          .notRequired
                                                  ? 'Changing receipt values sends this expense back for approval.'
                                                  : 'This reason is retained with the expense history.',
                                            ),
                                            validator: (value) =>
                                                (value ?? '').trim().isEmpty
                                                ? 'Explain why this receipt is being corrected.'
                                                : null,
                                          ),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                          key: const ValueKey(
                                            'save-expense-button',
                                          ),
                                          onPressed: _saving || _draftOpening
                                              ? null
                                              : _save,
                                          icon: const Icon(Icons.save_outlined),
                                          label: Text(
                                            widget.existing == null
                                                ? 'Save expense'
                                                : widget
                                                          .existing!
                                                          .receiptImageCount >
                                                      0
                                                ? 'Review correction'
                                                : 'Save changes',
                                          ),
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              48,
                                            ),
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
      ),
    );
  }

  String? _validateAmount(String? value) {
    return _receiptType == ExpenseReceiptType.basic
        ? validateOptionalExpenseMoney(value)
        : validateRequiredExpenseMoney(value);
  }

  Future<void> _addLine() => _openExpenseLine();
  Future<void> _editLine(ExpenseLineItem item) => _openExpenseLine(item);

  void _deleteLine(ExpenseLineItem item) {
    if (_pendingLine != null) return;
    setState(
      () => _lineItems.removeWhere((candidate) => candidate.id == item.id),
    );
    _syncTotalsFromLines();
    _captureExpenseInput();
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
      _changeExpenseInput(() => _expenseDate = DateUtils.dateOnly(selected));
    }
  }

  void _openSettings() {
    if (!widget.permissions.canConfigureDisplay) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExpensesSettingsScreen()),
    );
  }
}
