part of 'estimate_editor_screen.dart';

class _EstimateDraftBanner extends StatelessWidget {
  const _EstimateDraftBanner({required this.number, required this.createdOn});

  final String number;
  final DateTime createdOn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      backgroundColor: colors.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Draft · $number',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Started ${_date(context, createdOn)} · Not shared'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _EstimateWorkBuildingSection extends StatelessWidget {
  const _EstimateWorkBuildingSection({
    required this.laborCount,
    required this.laborTotal,
    required this.materialCount,
    required this.materialTotal,
    required this.onLabor,
    required this.onMaterials,
  });

  final int laborCount;
  final double laborTotal;
  final int materialCount;
  final double materialTotal;
  final VoidCallback onLabor;
  final VoidCallback onMaterials;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Text(
            'Build the price',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _EstimateBuilderRow(
          key: const ValueKey('estimate-labor-section'),
          icon: Icons.engineering_outlined,
          title: 'Labor',
          detail: laborCount == 0
              ? 'Add work and hours'
              : '$laborCount ${laborCount == 1 ? 'entry' : 'entries'} · ${_currency(laborTotal)}',
          onTap: onLabor,
        ),
        const Divider(height: 1),
        _EstimateBuilderRow(
          key: const ValueKey('estimate-materials-section'),
          icon: Icons.inventory_2_outlined,
          title: 'Materials and other charges',
          detail: materialCount == 0
              ? 'Add materials, linked expenses, or other charges'
              : '$materialCount ${materialCount == 1 ? 'entry' : 'entries'} · ${_currency(materialTotal)}',
          onTap: onMaterials,
        ),
      ],
    ),
  );
}

class _EstimateBuilderRow extends StatelessWidget {
  const _EstimateBuilderRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 60,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _EstimateIdentitySection extends StatelessWidget {
  const _EstimateIdentitySection({
    required this.number,
    required this.title,
    required this.scope,
    required this.customers,
    required this.selectedClient,
    required this.pricing,
    required this.onClientChanged,
    required this.onAddClient,
    required this.onPricingChanged,
  });

  final String number;
  final TextEditingController title;
  final TextEditingController scope;
  final List<WorkCustomerProfile> customers;
  final String? selectedClient;
  final WorkPricingModel pricing;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onAddClient;
  final ValueChanged<WorkPricingModel> onPricingChanged;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Customer and scope',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '$number · This number stays with the estimate through every revision.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey('estimate-client-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey('estimate-client-value-${selectedClient ?? 'none'}'),
            initialValue: selectedClient,
            isExpanded: true,
            itemHeight: null,
            decoration: const InputDecoration(
              labelText: 'Client',
              helperText: 'The estimate remains linked to this client history.',
              helperMaxLines: 4,
            ),
            items: [
              if (selectedClient != null &&
                  !customers.any((customer) => customer.name == selectedClient))
                DropdownMenuItem<String>(
                  value: selectedClient,
                  child: Text(selectedClient!),
                ),
              for (final customer in customers)
                DropdownMenuItem<String>(
                  value: customer.name,
                  child: Text(customer.name),
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
        SegmentedButton<WorkPricingModel>(
          segments: const [
            ButtonSegment(
              value: WorkPricingModel.flatRate,
              label: Text('Flat rate'),
            ),
            ButtonSegment(
              value: WorkPricingModel.timeAndMaterials,
              label: Text('Time and materials'),
            ),
          ],
          selected: {pricing},
          onSelectionChanged: (value) => onPricingChanged(value.first),
        ),
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
  });

  final DateTime createdOn;
  final DateTime expiresOn;
  final DateTime? followUpOn;
  final DateTime? proposedServiceOn;
  final VoidCallback onExpires;
  final VoidCallback onFollowUp;
  final VoidCallback onProposedService;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dates and follow-up',
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
      ],
    ),
  );
}

class _EstimatePricingSection extends StatelessWidget {
  const _EstimatePricingSection({
    required this.subtotal,
    required this.total,
    required this.discount,
    required this.tax,
    required this.template,
    required this.terms,
    required this.onTemplate,
  });

  final double subtotal;
  final double total;
  final TextEditingController discount;
  final TextEditingController tax;
  final String template;
  final TextEditingController terms;
  final VoidCallback onTemplate;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Price and customer copy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        _DateRow(label: 'Subtotal', value: _currency(subtotal)),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: const Text('Customer template'),
          subtitle: Text(template),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTemplate,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _MoneyField(label: 'Discount', controller: discount),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyField(label: 'Tax', controller: tax),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: terms,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Terms and conditions',
            helperText: 'Include validity, deposit, and payment expectations.',
            helperMaxLines: 4,
          ),
        ),
        const Divider(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            const Text(
              'Estimate total',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _currency(total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
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

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, prefixText: '\$'),
  );
}

String _date(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatMediumDate(date);

String _currency(double value) => '\$${value.toStringAsFixed(2)}';
