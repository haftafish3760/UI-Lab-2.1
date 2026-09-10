import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/expenses/expense_line_draft_input.dart';
import '../../data/storage/local_record_identity.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/nested_editor_draft_status.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'expense_input_validation.dart';
import 'expense_models.dart';

part 'expense_line_item_fields.dart';
part 'expense_line_item_draft_recovery.dart';

Future<ExpenseLineItem?> showExpenseLineItemEditor(
  BuildContext context, {
  ExpenseLineItem? initial,
  required ExpenseCategory defaultCategory,
  String? jobId,
  String? jobLabel,
  DraftAutosaveSession? draftSession,
  ExpenseLineDraftInput? recoveryInput,
  ValueChanged<ExpenseLineDraftInput>? onDraftChanged,
}) => Navigator.of(context).push<ExpenseLineItem>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ExpenseLineItemEditorScreen(
      initial: initial,
      defaultCategory: defaultCategory,
      jobId: jobId,
      jobLabel: jobLabel,
      draftSession: draftSession,
      recoveryInput: recoveryInput,
      onDraftChanged: onDraftChanged,
    ),
  ),
);

class ExpenseLineItemEditorScreen extends StatefulWidget {
  const ExpenseLineItemEditorScreen({
    required this.defaultCategory,
    this.initial,
    this.jobId,
    this.jobLabel,
    this.draftSession,
    this.recoveryInput,
    this.onDraftChanged,
    super.key,
  });

  final ExpenseLineItem? initial;
  final ExpenseCategory defaultCategory;
  final String? jobId;
  final String? jobLabel;
  final DraftAutosaveSession? draftSession;
  final ExpenseLineDraftInput? recoveryInput;
  final ValueChanged<ExpenseLineDraftInput>? onDraftChanged;

  @override
  State<ExpenseLineItemEditorScreen> createState() =>
      _ExpenseLineItemEditorScreenState();
}

class _ExpenseLineItemEditorScreenState
    extends State<ExpenseLineItemEditorScreen>
    with DraftNavigationGuard {
  @override
  DraftAutosaveSession? get navigationDraft => widget.draftSession;
  bool _savingLine = false;
  @override
  bool get blockDraftNavigation => _savingLine;
  late String _itemId;
  void _refreshDraft(VoidCallback change) => setState(change);
  static const _units = [
    'each',
    'pack',
    'package',
    'box',
    'roll',
    'foot',
    'gallon',
    'pound',
    'hour',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _partNumber;
  late final TextEditingController _quantity;
  late final TextEditingController _unitsPerPackage;
  late final TextEditingController _unitPrice;
  late ExpenseCategory _category;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _description = TextEditingController(text: item?.description ?? '');
    _partNumber = TextEditingController(text: item?.partNumber ?? '');
    _quantity = TextEditingController(
      text: item == null ? '1' : _formatNumber(item.quantity),
    );
    _unitsPerPackage = TextEditingController(
      text: item == null ? '1' : _formatNumber(item.unitsPerPackage),
    );
    _unitPrice = TextEditingController(
      text: item == null ? '' : item.unitPrice.toStringAsFixed(2),
    );
    _category = item?.category ?? widget.defaultCategory;
    _unit = item?.unit ?? 'each';
    _itemId = item?.id ?? newLocalRecordIdentity('EXP-LINE');
    _restoreLineDraft();
    for (final field in _rawFields) {
      field.addListener(_captureLineDraft);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureLineDraft();
    });
    _quantity.addListener(_refresh);
    _unitPrice.addListener(_refresh);
  }

  @override
  void dispose() {
    _quantity.removeListener(_refresh);
    _unitPrice.removeListener(_refresh);
    _description.dispose();
    _partNumber.dispose();
    _quantity.dispose();
    _unitsPerPackage.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double get _lineTotal {
    final quantity = double.tryParse(_quantity.text.trim()) ?? 0;
    final price = double.tryParse(_unitPrice.text.trim()) ?? 0;
    return quantity * price;
  }

  bool get _usesPackageDetails =>
      _unit == 'pack' || _unit == 'package' || _unit == 'box';

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('expense-line-item-editor-screen'),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => leaveDraftRoute(),
          tooltip: widget.draftSession == null
              ? 'Cancel item changes'
              : 'Keep unfinished item',
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.initial == null ? 'Add receipt item' : 'Edit receipt item',
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final formWidth = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: insets.copyWith(top: 12, bottom: 110),
              children: [
                Center(
                  child: SizedBox(
                    width: formWidth,
                    child: Form(
                      key: _formKey,
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.draftSession != null)
                              NestedEditorDraftStatus(
                                session: widget.draftSession!,
                              ),
                            const Text(
                              'Receipt item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Use the wording printed on the receipt. You can change every field.',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const ValueKey('expense-line-description'),
                              controller: _description,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Item or material',
                                hintText: 'Example: 20-in faucet connector',
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Enter the item shown on the receipt.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const ValueKey('expense-line-part-number'),
                              controller: _partNumber,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Part or item number (optional)',
                                helperText:
                                    'Use the SKU, model, or part number printed on the receipt.',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<ExpenseCategory>(
                              key: const ValueKey('expense-line-category'),
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Expense category',
                              ),
                              items: [
                                for (final category in ExpenseCategory.values)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(category.label),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                  _captureLineDraft();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _ResponsiveFieldPair(
                              first: _PriceField(controller: _unitPrice),
                              second: _UnitField(
                                value: _unit,
                                units: {..._units, _unit}.toList(),
                                onChanged: (value) => _changeLineUnit(value),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ResponsiveFieldPair(
                              first: _QuantityField(
                                controller: _quantity,
                                onChanged: _refresh,
                              ),
                              second: _usesPackageDetails
                                  ? _PackageField(controller: _unitsPerPackage)
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _LineTotal(
                              total: _lineTotal,
                              quantity:
                                  double.tryParse(_quantity.text.trim()) ?? 0,
                              unit: _unit,
                              unitsPerPackage:
                                  double.tryParse(
                                    _unitsPerPackage.text.trim(),
                                  ) ??
                                  0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => leaveDraftRoute(),
                  child: Text(
                    widget.draftSession == null ? 'Cancel' : 'Keep unfinished',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('save-expense-line-item'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save item'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (_savingLine) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _captureLineDraft();
    setState(() => _savingLine = true);
    try {
      await widget.draftSession?.flush();
    } on Object {
      if (mounted) setState(() => _savingLine = false);
      return;
    }
    if (!mounted) return;
    await finishDraftRoute(
      ExpenseLineItem(
        id: _itemId,
        description: _description.text.trim(),
        category: _category,
        quantity: double.parse(_quantity.text.replaceAll(',', '').trim()),
        unit: _unit,
        unitPrice: double.parse(_unitPrice.text.replaceAll(',', '').trim()),
        confirmedLineTotal: double.parse(_lineTotal.toStringAsFixed(2)),
        partNumber: _partNumber.text.trim().isEmpty
            ? null
            : _partNumber.text.trim(),
        unitsPerPackage: _usesPackageDetails
            ? double.parse(_unitsPerPackage.text.replaceAll(',', '').trim())
            : 1,
        jobId:
            widget.recoveryInput?.jobId ??
            widget.initial?.jobId ??
            widget.jobId,
        jobLabel:
            widget.recoveryInput?.jobLabel ??
            widget.initial?.jobLabel ??
            widget.jobLabel,
      ),
    );
  }
}
