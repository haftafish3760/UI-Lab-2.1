part of 'customer_detail_screen.dart';

class _CustomerEstimates extends StatelessWidget {
  const _CustomerEstimates({
    required this.estimates,
    required this.onOpen,
    required this.onCreate,
  });

  final List<WorkRecord> estimates;
  final ValueChanged<WorkRecord> onOpen;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${estimates.length} records · Newest first'),
                ],
              ),
              FilledButton.tonalIcon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New estimate'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimates.isEmpty)
            const Text('No work is linked to this customer yet.')
          else
            for (final estimate in estimates) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(estimate.title),
                subtitle: Text(
                  '${estimate.number} · ${estimate.status.label}\n${estimate.createdOn == null ? '' : MaterialLocalizations.of(context).formatMediumDate(estimate.createdOn!)}',
                ),
                trailing: Text('\$${estimate.total.toStringAsFixed(2)}'),
                onTap: () => onOpen(estimate),
              ),
              if (estimate != estimates.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _CustomerIdentity extends StatelessWidget {
  const _CustomerIdentity({
    required this.customer,
    required this.recordCount,
    required this.onEdit,
  });

  final WorkCustomerProfile customer;
  final int recordCount;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
            if (customer.companyName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(customer.companyName),
            ],
            const SizedBox(height: 3),
            Text('$recordCount linked Work records'),
          ],
        ),
        FilledButton.icon(
          key: const ValueKey('edit-customer-button'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit client information'),
        ),
      ],
    ),
  );
}

class _CustomerDetailLanes extends StatelessWidget {
  const _CustomerDetailLanes({
    required this.customer,
    required this.recordCount,
    required this.layout,
  });

  final WorkCustomerProfile customer;
  final int recordCount;
  final DetailWorkspaceLayout layout;

  @override
  Widget build(BuildContext context) {
    final contact = _CustomerSection(
      title: 'Contact and billing',
      icon: Icons.contact_phone_outlined,
      children: [
        _DetailValue(label: 'Phone', value: customer.phone),
        _DetailValue(label: 'Email', value: customer.email),
        _DetailValue(
          label: 'Preferred contact',
          value: customer.preferredContact,
        ),
        _DetailValue(label: 'Billing address', value: customer.billingAddress),
      ],
    );
    final locations = _CustomerSection(
      title: 'Service locations',
      icon: Icons.location_on_outlined,
      children: [
        for (final location in customer.locations)
          _LocationDetail(location: location),
      ],
    );
    final notes = _CustomerSection(
      title: 'Notes and history',
      icon: Icons.history_rounded,
      children: [
        _DetailValue(label: 'Client notes', value: customer.notes),
        _DetailValue(
          label: 'Linked history',
          value: '$recordCount visible estimates, jobs, or invoices',
        ),
      ],
    );
    if (layout.columns == 1) {
      return Column(
        children: [
          contact,
          SizedBox(height: layout.gap),
          locations,
          SizedBox(height: layout.gap),
          notes,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: layout.columnWidth,
          child: Column(
            children: [
              contact,
              SizedBox(height: layout.gap),
              notes,
            ],
          ),
        ),
        SizedBox(width: layout.gap),
        SizedBox(width: layout.columnWidth, child: locations),
      ],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const Divider(height: 20),
        ],
      ],
    ),
  );
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _LocationDetail extends StatelessWidget {
  const _LocationDetail({required this.location});

  final WorkServiceLocation location;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(location.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(location.address),
      if (location.accessNotes.isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          'Access: ${location.accessNotes}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
