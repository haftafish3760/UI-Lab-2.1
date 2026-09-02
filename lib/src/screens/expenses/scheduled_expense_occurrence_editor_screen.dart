import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';

class ScheduledExpenseOccurrenceEditorScreen extends StatefulWidget {
  const ScheduledExpenseOccurrenceEditorScreen({
    required this.occurrence,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ScheduledExpenseOccurrence occurrence;
  final ExpensePermissions permissions;

  @override
  State<ScheduledExpenseOccurrenceEditorScreen> createState() =>
      _ScheduledExpenseOccurrenceEditorScreenState();
}

class _ScheduledExpenseOccurrenceEditorScreenState
    extends State<ScheduledExpenseOccurrenceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.occurrence.expectedAmount.toStringAsFixed(2),
  );
  late var _dueOn = widget.occurrence.dueOn;

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canManageScheduledExpenses) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('scheduled-expense-occurrence-editor-screen'),
        message: 'You do not have permission to edit this payment.',
      );
    }
    return Scaffold(
      key: const ValueKey('scheduled-expense-occurrence-editor-screen'),
      appBar: AppBar(title: const Text('Edit this payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'These changes apply only to this payment. The recurring setup '
              'and later payments stay the same.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('occurrence-due-date'),
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Due ${operationalShortDateLabel(context, _dueOn)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('occurrence-expected-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Expected amount for this payment',
                prefixText: r'$ ',
              ),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Enter an amount above zero.'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-occurrence-edit'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save this payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _dueOn,
    );
    if (chosen != null) setState(() => _dueOn = DateUtils.dateOnly(chosen));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      widget.occurrence.copyWith(
        dueOn: _dueOn,
        expectedAmount: double.parse(_amount.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }
}
