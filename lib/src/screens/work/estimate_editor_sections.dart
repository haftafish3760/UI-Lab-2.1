part of 'estimate_editor_screen.dart';

class _EstimateIdentitySection extends StatelessWidget {
  const _EstimateIdentitySection({
    required this.number,
    required this.canEditNumber,
    required this.onNumberChanged,
    required this.title,
    required this.purchaseOrder,
  });

  final String number;
  final bool canEditNumber;
  final ValueChanged<String> onNumberChanged;
  final TextEditingController title;
  final TextEditingController purchaseOrder;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estimate information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...[
          _labeledField(
            context,
            'Estimate title',
            TextField(
              key: const ValueKey('estimate-title'),
              controller: title,
              textInputAction: TextInputAction.next,
              decoration: _lineDecoration(
                hintText: 'Example: Replace kitchen faucet',
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final numberField = _labeledField(
                context,
                'Document number',
                TextFormField(
                  key: const ValueKey('estimate-document-number'),
                  initialValue: number,
                  readOnly: !canEditNumber,
                  textInputAction: TextInputAction.next,
                  onChanged: canEditNumber ? onNumberChanged : null,
                  decoration: _lineDecoration().copyWith(
                    helperText: canEditNumber
                        ? 'You can choose a different number before saving.'
                        : null,
                  ),
                ),
              );
              final purchaseOrderField = _labeledField(
                context,
                'Purchase order number (optional)',
                TextField(
                  controller: purchaseOrder,
                  textInputAction: TextInputAction.next,
                  decoration: _lineDecoration(),
                ),
              );
              if (AppLayoutEngine.stackFormFieldsFor(
                constraints.maxWidth,
                textScaler: MediaQuery.textScalerOf(context),
              )) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    numberField,
                    const SizedBox(height: 14),
                    purchaseOrderField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: numberField),
                  const SizedBox(width: 12),
                  Expanded(child: purchaseOrderField),
                ],
              );
            },
          ),
        ],
      ],
    ),
  );

  Widget _labeledField(BuildContext context, String label, Widget field) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(context, label),
          const SizedBox(height: 4),
          field,
        ],
      );

  Widget _fieldLabel(BuildContext context, String label) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  InputDecoration _lineDecoration({
    String? hintText,
    String? helperText,
    int? helperMaxLines,
  }) => InputDecoration(
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: helperMaxLines,
    isDense: true,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    border: const UnderlineInputBorder(),
    enabledBorder: const UnderlineInputBorder(),
    focusedBorder: const UnderlineInputBorder(),
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        );
        final valueWidget = Text(value);
        if (MediaQuery.textScalerOf(context).scale(16) > 24) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              valueWidget,
              if (onTap != null)
                TextButton(onPressed: onTap, child: const Text('Edit')),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: valueWidget,
              ),
            ),
            if (onTap != null)
              TextButton(onPressed: onTap, child: const Text('Edit')),
          ],
        );
      },
    ),
  );
}

String _date(BuildContext context, DateTime date) =>
    '${MaterialLocalizations.of(context).formatMediumDate(date)}, ${date.year}';

String _currency(double value) => '\$${value.toStringAsFixed(2)}';
