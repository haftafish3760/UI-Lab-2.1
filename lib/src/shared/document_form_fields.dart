import 'package:flutter/material.dart';

class DocumentAmountField extends StatelessWidget {
  const DocumentAmountField({
    required this.label,
    required this.controller,
    super.key,
  });
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      prefixText: r'$ ',
      helperText: 'Enter an amount with up to two decimal places.',
      helperMaxLines: 4,
    ),
  );
}

class DocumentChoiceField extends StatelessWidget {
  const DocumentChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final option in {...options, value})
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => onChanged(option),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    option == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option)),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class DocumentTermsField extends StatelessWidget {
  const DocumentTermsField({required this.controller, super.key});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    minLines: 6,
    maxLines: null,
    decoration: const InputDecoration(
      labelText: 'Terms and conditions',
      helperText:
          'These are the terms for this document. Review them before sharing.',
      helperMaxLines: 4,
    ),
  );
}
