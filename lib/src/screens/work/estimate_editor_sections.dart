part of 'estimate_editor_screen.dart';

class _EstimateSitePhotosSection extends StatelessWidget {
  const _EstimateSitePhotosSection({
    required this.photoCount,
    required this.onOpen,
  });

  final int photoCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DocumentFormSection(
    borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
    key: const ValueKey('estimate-site-photos'),
    title: 'Photos',
    summary: photoCount == 0
        ? 'Add photos'
        : '$photoCount ${photoCount == 1 ? 'photo' : 'photos'} · Add or review',
    icon: Icons.add_a_photo_outlined,
    onTap: onOpen,
  );
}

class _EstimateIdentitySection extends StatelessWidget {
  const _EstimateIdentitySection({
    required this.number,
    required this.canEditNumber,
    required this.onNumberChanged,
    required this.title,
    required this.purchaseOrder,
    required this.scope,
  });

  final String number;
  final bool canEditNumber;
  final ValueChanged<String> onNumberChanged;
  final TextEditingController title;
  final TextEditingController purchaseOrder;
  final TextEditingController scope;

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
                'Estimate number',
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
          const SizedBox(height: 14),
          _fieldLabel(context, 'Description of work'),
          const SizedBox(height: 4),
          TextField(
            key: const ValueKey('estimate-work-description'),
            controller: scope,
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: null,
            decoration: _lineDecoration(
              hintText: 'Describe the work to be completed.',
            ),
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
    border: const UnderlineInputBorder(),
    enabledBorder: const UnderlineInputBorder(),
    focusedBorder: const UnderlineInputBorder(),
  );
}

class _EstimateTimingSection extends StatelessWidget {
  const _EstimateTimingSection({
    required this.createdOn,
    required this.expiresOn,
    required this.followUpOn,
    required this.proposedServiceOn,
    required this.onExpires,
    required this.onFollowUp,
    required this.onProposedService,
    this.onProposedTime,
  });

  final DateTime createdOn;
  final DateTime expiresOn;
  final DateTime? followUpOn;
  final DateTime? proposedServiceOn;
  final VoidCallback onExpires;
  final VoidCallback onFollowUp;
  final VoidCallback onProposedService;
  final VoidCallback? onProposedTime;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Proposed schedule and dates',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'A proposed service date is not a booked job. Scheduling happens only after approval and job creation.',
        ),
        const SizedBox(height: 10),
        _DateRow(label: 'Created', value: _date(context, createdOn)),
        _DateRow(
          label: 'Estimate valid through',
          value: _date(context, expiresOn),
          onTap: onExpires,
        ),
        _DateRow(
          label: 'Follow up',
          value: followUpOn == null ? 'Not set' : _date(context, followUpOn!),
          onTap: onFollowUp,
        ),
        _DateRow(
          label: 'Proposed service date',
          value: proposedServiceOn == null
              ? 'Not proposed'
              : _date(context, proposedServiceOn!),
          onTap: onProposedService,
        ),
        if (onProposedTime != null)
          _DateRow(
            label: 'Proposed start time',
            value:
                proposedServiceOn == null ||
                    (proposedServiceOn!.hour == 0 &&
                        proposedServiceOn!.minute == 0)
                ? 'Not proposed'
                : MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(TimeOfDay.fromDateTime(proposedServiceOn!)),
            onTap: onProposedTime,
          ),
      ],
    ),
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
    trailing: onTap == null ? null : const Icon(Icons.edit_calendar_outlined),
    onTap: onTap,
  );
}

String _date(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatMediumDate(date);

String _currency(double value) => '\$${value.toStringAsFixed(2)}';
