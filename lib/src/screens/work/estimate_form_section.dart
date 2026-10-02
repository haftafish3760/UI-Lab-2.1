import 'package:flutter/material.dart';

/// Related document information grouped in one visible, editable section.
class EstimateFormSection extends StatelessWidget {
  const EstimateFormSection({
    required this.title,
    required this.child,
    this.onEdit,
    this.actionLabel = 'Edit',
    super.key,
  });
  final String title, actionLabel;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// Shared alignment for editable document fields. Labels and help precede input.
class EstimateFormField extends StatelessWidget {
  const EstimateFormField({
    required this.label,
    required this.controller,
    this.hint,
    this.inputKey,
    this.multiline = false,
    this.money = false,
    super.key,
  });
  final String label;
  final String? hint;
  final Key? inputKey;
  final TextEditingController controller;
  final bool multiline, money;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          key: inputKey,
          controller: controller,
          textAlign: money ? TextAlign.end : TextAlign.start,
          keyboardType: money
              ? const TextInputType.numberWithOptions(decimal: true)
              : multiline
              ? TextInputType.multiline
              : TextInputType.text,
          textInputAction: multiline
              ? TextInputAction.newline
              : TextInputAction.next,
          onSubmitted: multiline
              ? null
              : (_) => FocusScope.of(context).nextFocus(),
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? null : 1,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: const UnderlineInputBorder(),
            enabledBorder: const UnderlineInputBorder(),
            focusedBorder: const UnderlineInputBorder(),
          ),
        ),
      ],
    ),
  );
}
