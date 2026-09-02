import 'package:flutter/material.dart';

Future<double?> showScheduledExpensePaymentAmountDialog(
  BuildContext context, {
  required double expectedAmount,
}) => showDialog<double>(
  context: context,
  builder: (_) =>
      _ScheduledExpensePaymentAmountDialog(expectedAmount: expectedAmount),
);

class _ScheduledExpensePaymentAmountDialog extends StatefulWidget {
  const _ScheduledExpensePaymentAmountDialog({required this.expectedAmount});

  final double expectedAmount;

  @override
  State<_ScheduledExpensePaymentAmountDialog> createState() =>
      _ScheduledExpensePaymentAmountDialogState();
}

class _ScheduledExpensePaymentAmountDialogState
    extends State<_ScheduledExpensePaymentAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.expectedAmount.toStringAsFixed(2),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('scheduled-expense-payment-amount-dialog'),
    title: const Text('Enter amount paid'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        key: const ValueKey('scheduled-expense-actual-amount'),
        controller: _amount,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Actual amount',
          prefixText: r'$ ',
        ),
        validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
            ? 'Enter an amount above zero.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('confirm-scheduled-expense-payment'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, double.parse(_amount.text.trim()));
        },
        child: const Text('Continue'),
      ),
    ],
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }
}
