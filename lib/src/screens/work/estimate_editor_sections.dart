part of 'estimate_editor_screen.dart';

class _EstimateSitePhotosSection extends StatelessWidget {
  const _EstimateSitePhotosSection({
    required this.photoCount,
    required this.onOpen,
  });

  final int photoCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      key: const ValueKey('estimate-site-photos'),
      minTileHeight: 60,
      leading: const Icon(Icons.photo_camera_outlined),
      title: const Text('Job-site photos and notes'),
      subtitle: Text(
        photoCount == 0
            ? 'Add pictures for later pricing and field reference'
            : '$photoCount ${photoCount == 1 ? 'photo' : 'photos'} saved internally',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onOpen,
    ),
  );
}

class _EstimateIdentitySection extends StatelessWidget {
  const _EstimateIdentitySection({
    required this.number,
    this.customerOnly = false,
    required this.title,
    required this.purchaseOrder,
    required this.scope,
    required this.customers,
    required this.selectedClient,
    required this.pricing,
    required this.onClientChanged,
    required this.onAddClient,
    required this.onPricingChanged,
  });

  final String number;
  final bool customerOnly;
  final TextEditingController title;
  final TextEditingController purchaseOrder;
  final TextEditingController scope;
  final List<WorkCustomerProfile> customers;
  final String? selectedClient;
  final WorkPricingModel pricing;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onAddClient;
  final ValueChanged<WorkPricingModel> onPricingChanged;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          customerOnly ? 'Client information' : 'Estimate information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (customerOnly) ...[
          KeyedSubtree(
            key: const ValueKey('estimate-client-field'),
            child: DropdownButtonFormField<String>(
              key: ValueKey(
                'estimate-client-value-${selectedClient ?? 'none'}',
              ),
              initialValue: selectedClient,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(
                labelText: 'Client',
                helperText:
                    'The estimate remains linked to this client history.',
                helperMaxLines: 4,
              ),
              items: [
                if (selectedClient != null &&
                    !customers.any((customer) => customer.id == selectedClient))
                  DropdownMenuItem<String>(
                    value: selectedClient,
                    child: Text(selectedClient!),
                  ),
                for (final customer in customers)
                  DropdownMenuItem<String>(
                    value: customer.id,
                    child: Text(
                      '${customer.name}${customer.companyName.isEmpty ? '' : ' · ${customer.companyName}'}${customer.phone.isEmpty ? '' : ' · ${customer.phone}'}',
                    ),
                  ),
              ],
              onChanged: onClientChanged,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('estimate-add-client'),
              onPressed: onAddClient,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add new client'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!customerOnly) ...[
          TextFormField(
            initialValue: number,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Document number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: purchaseOrder,
            decoration: const InputDecoration(
              labelText: 'Purchase order number (optional)',
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            key: const ValueKey('estimate-title'),
            controller: title,
            decoration: const InputDecoration(
              labelText: 'Estimate title',
              hintText: 'Example: Replace kitchen faucet',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: scope,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Proposed work',
              helperText: 'State what is included, excluded, and expected.',
              helperMaxLines: 4,
            ),
          ),
          const SizedBox(height: 10),
          DocumentChoiceField(
            label: 'Pricing method',
            value: pricing == WorkPricingModel.flatRate
                ? 'Flat rate'
                : 'Time and materials',
            options: const ['Flat rate', 'Time and materials'],
            onChanged: (value) => onPricingChanged(
              value == 'Flat rate'
                  ? WorkPricingModel.flatRate
                  : WorkPricingModel.timeAndMaterials,
            ),
          ),
        ],
      ],
    ),
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
