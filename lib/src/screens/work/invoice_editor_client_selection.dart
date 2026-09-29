part of 'invoice_editor_screen.dart';

extension _InvoiceClientSelection on _InvoiceEditorScreenState {
  Widget _clientSelection() {
    final grants = _store.directorySession?.permissions;
    final canView = grants?.canViewCustomers ?? true;
    final canAdd = canView && (grants?.canManageCustomers ?? true);
    final customer = _customerSnapshot;
    final locations = customer?.locations ?? const <WorkServiceLocation>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            TextButton(
              key: const ValueKey('invoice-saved-clients'),
              onPressed: canView ? _chooseSavedClient : null,
              child: Text(context.l10n.workSavedClients),
            ),
            TextButton(
              key: const ValueKey('invoice-add-client'),
              onPressed: canAdd ? _addClient : null,
              child: Text(context.l10n.workAddClient),
            ),
          ],
        ),
        if (_client != null) ...[
          const SizedBox(height: 12),
          Text(_client!, key: const ValueKey('invoice-selected-client')),
          if (customer?.phone.isNotEmpty == true) Text(customer!.phone),
        ],
        if (locations.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('invoice-location-${customer?.id}-$_location'),
            initialValue: locations.any((l) => l.address == _location)
                ? locations.indexWhere((l) => l.address == _location)
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Service location'),
            items: [
              for (var index = 0; index < locations.length; index++)
                DropdownMenuItem(
                  value: index,
                  child: Text(locations[index].label),
                ),
            ],
            onChanged: (index) {
              if (index != null) {
                _updateInput(() => _location = locations[index].address);
              }
            },
          ),
        ],
        if (_location?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(_location!),
        ],
        if (!canView) Text(context.l10n.workClientsUnavailable),
      ],
    );
  }

  Future<void> _chooseSavedClient() async {
    if (_store.directorySession?.permissions.canViewCustomers == false) return;
    await _draft?.flush();
    if (!mounted) return;
    final selected = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => SavedClientsScreen(
          initialClients: _store.customers,
          selectedDay: _issuedOn,
          selectForDocument: true,
          onClientsChanged: _store.replaceCustomers,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (_store.directorySession?.permissions.canViewCustomers == false) return;
    final current = _store.customers
        .where((client) => client.id == selected.id)
        .firstOrNull;
    if (current == null) return;
    _applyClient(current);
    await _draft?.flush();
  }

  void _applyClient(WorkCustomerProfile customer) {
    _updateInput(() {
      final sameClient = _customerSnapshot?.id == customer.id;
      _client = customer.name;
      _customerSnapshot = customer;
      if (!sameClient || _location == null) {
        _location = customer.locations.firstOrNull?.address;
      }
    });
  }

  Future<void> _addClient() async {
    final grants = _store.directorySession?.permissions;
    if (grants != null &&
        (!grants.canViewCustomers || !grants.canManageCustomers)) {
      return;
    }
    await _draft?.flush();
    if (!mounted) return;
    final customer = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: _issuedOn),
      ),
    );
    if (!mounted || customer == null) return;
    if (_store.directorySession?.permissions.canViewCustomers == false) return;
    final current = _store.customers
        .where((client) => client.id == customer.id)
        .firstOrNull;
    if (current == null) return;
    _applyClient(current);
    await _draft?.flush();
  }
}
