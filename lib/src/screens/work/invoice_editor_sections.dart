part of 'invoice_editor_screen.dart';

class _InvoiceSourceSection extends StatelessWidget {
  const _InvoiceSourceSection({
    required this.jobs,
    required this.selectedValue,
    required this.directValue,
    required this.onChanged,
  });

  final List<WorkRecord> jobs;
  final String selectedValue;
  final String directValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Invoice source', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Choose the completed job this invoice belongs to, or create a direct invoice.',
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: const ValueKey('invoice-source-job'),
          initialValue: selectedValue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Invoice for'),
          items: [
            DropdownMenuItem<String>(
              value: directValue,
              child: const Text('Direct invoice without a job'),
            ),
            for (final job in jobs)
              DropdownMenuItem<String>(
                value: job.id,
                child: Text('${job.number} · ${job.client} · ${job.title}'),
              ),
          ],
          selectedItemBuilder: (context) => [
            const Text('Direct invoice'),
            for (final job in jobs) Text('${job.number} · ${job.client}'),
          ],
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _InvoiceIdentitySection extends StatelessWidget {
  const _InvoiceIdentitySection({
    required this.number,
    required this.canEditNumber,
    required this.onNumberChanged,
    this.customerOnly = false,
    required this.title,
    required this.purchaseOrder,
    required this.summary,
    required this.customers,
    required this.selectedClient,
    required this.locations,
    required this.selectedLocation,
    required this.pricing,
    required this.onClientChanged,
    required this.onLocationChanged,
    required this.onAddClient,
    required this.onPricingChanged,
  });

  final String number;
  final bool canEditNumber;
  final ValueChanged<String> onNumberChanged;
  final bool customerOnly;
  final TextEditingController title;
  final TextEditingController purchaseOrder;
  final TextEditingController summary;
  final List<WorkCustomerProfile> customers;
  final String? selectedClient;
  final List<WorkServiceLocation> locations;
  final String? selectedLocation;
  final WorkPricingModel pricing;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onAddClient;
  final ValueChanged<WorkPricingModel> onPricingChanged;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          customerOnly ? 'Client information' : 'Invoice information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text('$number · Saved as a draft until it is issued to the customer.'),
        const SizedBox(height: 10),
        if (customerOnly) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('invoice-client-${selectedClient ?? 'none'}'),
            initialValue: selectedClient,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Customer'),
            items: [
              // Preserve a recovered name even if its customer directory entry
              // is currently unavailable; recovery must not invalidate raw input.
              if (selectedClient != null &&
                  !customers.any((customer) => customer.name == selectedClient))
                DropdownMenuItem(
                  value: selectedClient!,
                  child: Text(selectedClient!),
                ),
              for (final customer in customers)
                DropdownMenuItem(
                  value: customer.name,
                  child: Text(customer.name),
                ),
            ],
            onChanged: onClientChanged,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('invoice-add-client'),
              onPressed: onAddClient,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add new customer'),
            ),
          ),
          if (locations.isNotEmpty) ...[
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              key: ValueKey('invoice-location-${selectedLocation ?? 'none'}'),
              initialValue:
                  locations.any(
                    (location) => location.address == selectedLocation,
                  )
                  ? selectedLocation
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Service location'),
              items: [
                for (final location in locations)
                  DropdownMenuItem(
                    value: location.address,
                    child: Text(location.label),
                  ),
              ],
              onChanged: onLocationChanged,
            ),
            if (selectedLocation?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                selectedLocation!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
        ],
        if (!customerOnly) ...[
          TextFormField(
            key: const ValueKey('invoice-document-number'),
            initialValue: number,
            readOnly: !canEditNumber,
            onChanged: canEditNumber ? onNumberChanged : null,
            decoration: InputDecoration(
              labelText: 'Document number',
              helperText: canEditNumber
                  ? 'You can choose a different number before saving.'
                  : null,
            ),
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
            key: const ValueKey('invoice-title'),
            controller: title,
            decoration: const InputDecoration(
              labelText: 'Invoice title',
              hintText: 'Example: Replace kitchen faucet',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('invoice-summary'),
            controller: summary,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Work completed',
              helperText: 'State what the customer is being billed for.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<WorkPricingModel>(
            key: const ValueKey('invoice-pricing'),
            initialValue: pricing,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pricing method'),
            items: const [
              DropdownMenuItem(
                value: WorkPricingModel.flatRate,
                child: Text('Flat rate'),
              ),
              DropdownMenuItem(
                value: WorkPricingModel.timeAndMaterials,
                child: Text('Time and materials'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onPricingChanged(value);
            },
          ),
        ],
      ],
    ),
  );
}

class _InvoiceItemsSection extends StatelessWidget {
  const _InvoiceItemsSection({
    required this.itemCount,
    required this.subtotal,
    required this.onOpen,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      key: const ValueKey('invoice-items'),
      minTileHeight: 60,
      leading: const Icon(Icons.format_list_bulleted_rounded),
      title: const Text('Invoice items'),
      subtitle: Text(
        itemCount == 0
            ? 'Add labor, materials, equipment, or other charges'
            : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · ${_invoiceMoney(subtotal)}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onOpen,
    ),
  );
}

class _InvoiceDatesSection extends StatelessWidget {
  const _InvoiceDatesSection({
    required this.issuedOn,
    required this.dueOn,
    required this.onIssuedOn,
    required this.onDueOn,
  });

  final DateTime issuedOn;
  final DateTime dueOn;
  final VoidCallback onIssuedOn;
  final VoidCallback onDueOn;

  @override
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Invoice dates', style: Theme.of(context).textTheme.titleMedium),
        _InvoiceValueRow(
          label: 'Invoice date',
          value: _invoiceDate(context, issuedOn),
          onTap: onIssuedOn,
        ),
        _InvoiceValueRow(
          label: 'Payment due',
          value: _invoiceDate(context, dueOn),
          onTap: onDueOn,
        ),
      ],
    ),
  );
}

class _InvoiceValueRow extends StatelessWidget {
  const _InvoiceValueRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accessible = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.35;
    if (accessible) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 52,
        title: Text(label),
        subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.edit_calendar_outlined),
        onTap: onTap,
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 52,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar_outlined),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

String _invoiceDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value);

String _invoiceMoney(double value) => '\$${value.toStringAsFixed(2)}';
