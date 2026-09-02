import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';

class ScheduledExpenseEditorScreen extends StatefulWidget {
  const ScheduledExpenseEditorScreen({
    this.initial,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ScheduledExpenseRecord? initial;
  final ExpensePermissions permissions;

  @override
  State<ScheduledExpenseEditorScreen> createState() =>
      _ScheduledExpenseEditorScreenState();
}

class _ScheduledExpenseEditorScreenState
    extends State<ScheduledExpenseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _amount = TextEditingController(
    text: widget.initial?.amount.toStringAsFixed(2),
  );
  late var _category = widget.initial?.category ?? ExpenseCategory.office;
  late var _kind = widget.initial?.kind ?? ExpenseScheduleKind.monthly;
  late var _amountKind =
      widget.initial?.amountKind ?? ScheduledExpenseAmountKind.fixed;
  late var _dueDate =
      widget.initial?.nextDueOn ??
      DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7)));
  late var _dueDay = widget.initial?.dueDay ?? _dueDate.day;
  late final _reminders = {...?widget.initial?.reminderDaysBefore};
  late var _inApp = widget.initial?.inAppReminder ?? true;
  late var _push = widget.initial?.pushReminder ?? true;
  late var _sound = widget.initial?.soundReminder ?? true;
  late var _receiptRequired = widget.initial?.receiptRequired ?? false;

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canManageScheduledExpenses) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('scheduled-expense-editor-screen'),
        message: 'You do not have permission to manage planned expenses.',
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null
              ? 'Add planned expense'
              : 'Edit planned expense',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 32),
          children: [
            TextFormField(
              key: const ValueKey('scheduled-expense-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Expense title'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a title.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('scheduled-expense-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Usual or expected amount',
                prefixText: r'$ ',
              ),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Enter an amount above zero.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ScheduledExpenseAmountKind>(
              initialValue: _amountKind,
              decoration: const InputDecoration(labelText: 'Amount handling'),
              items: [
                for (final item in ScheduledExpenseAmountKind.values)
                  DropdownMenuItem(value: item, child: Text(item.label)),
              ],
              onChanged: (value) =>
                  setState(() => _amountKind = value ?? _amountKind),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final item in ExpenseCategory.values)
                  DropdownMenuItem(value: item, child: Text(item.label)),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ExpenseScheduleKind>(
              segments: const [
                ButtonSegment(
                  value: ExpenseScheduleKind.oneTime,
                  label: Text('One time'),
                ),
                ButtonSegment(
                  value: ExpenseScheduleKind.monthly,
                  label: Text('Every month'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.first),
            ),
            const SizedBox(height: 12),
            if (_kind == ExpenseScheduleKind.monthly)
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: const InputDecoration(
                  labelText: 'Day of the month',
                ),
                items: [
                  for (var day = 1; day <= 31; day++)
                    DropdownMenuItem(value: day, child: Text('$day')),
                ],
                onChanged: (value) =>
                    setState(() => _dueDay = value ?? _dueDay),
              )
            else
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  'Due ${operationalShortDateLabel(context, _dueDate)}',
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Set up reminders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose up to five reminders before this expense is due.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in const [1, 3, 7, 14, 30])
                  FilterChip(
                    label: Text('$day day${day == 1 ? '' : 's'} before'),
                    selected: _reminders.contains(day),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _reminders.add(day)
                          : _reminders.remove(day),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('In-app reminder'),
              value: _inApp,
              onChanged: (value) => setState(() => _inApp = value),
            ),
            SwitchListTile(
              title: const Text('Device notification'),
              subtitle: const Text(
                'Show this reminder even when Maintainiac is closed.',
              ),
              value: _push,
              onChanged: (value) => setState(() {
                _push = value;
                if (!value) _sound = false;
              }),
            ),
            SwitchListTile(
              title: const Text('Play a sound'),
              value: _sound,
              onChanged: _push
                  ? (value) => setState(() => _sound = value)
                  : null,
            ),
            SwitchListTile(
              title: const Text('Require a receipt each time'),
              subtitle: const Text(
                'Each paid occurrence stays open until its expense has receipt evidence.',
              ),
              value: _receiptRequired,
              onChanged: (value) => setState(() => _receiptRequired = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('save-scheduled-expense'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save upcoming expense'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _dueDate,
    );
    if (chosen != null) setState(() => _dueDate = chosen);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final monthlyDate = DateTime(
      now.year,
      now.month + (_dueDay < now.day ? 1 : 0),
      _dueDay,
    );
    Navigator.pop(
      context,
      ScheduledExpenseRecord(
        id: widget.initial?.id ?? 'scheduled-${now.microsecondsSinceEpoch}',
        title: _title.text.trim(),
        category: _category,
        amount: double.parse(_amount.text.trim()),
        nextDueOn: _kind == ExpenseScheduleKind.monthly
            ? monthlyDate
            : _dueDate,
        kind: _kind,
        ownerEmployeeId: widget.initial?.ownerEmployeeId ?? 'alex',
        owner: widget.initial?.owner ?? 'Alex Morgan',
        reminderDaysBefore: _reminders.toList()..sort(),
        inAppReminder: _inApp,
        pushReminder: _push,
        soundReminder: _sound,
        amountKind: _amountKind,
        state: widget.initial?.state ?? ScheduledExpenseState.active,
        receiptRequired: _receiptRequired,
        dueDay: _kind == ExpenseScheduleKind.monthly ? _dueDay : null,
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }
}
