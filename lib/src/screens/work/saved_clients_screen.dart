import '../../../l10n/app_localizations_extension.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';

import '../../layout/app_layout_engine.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

class SavedClientsScreen extends StatefulWidget {
  const SavedClientsScreen({
    required this.initialClients,
    required this.selectedDay,
    required this.onClientsChanged,
    this.selectForDocument = false,
    super.key,
  });

  final List<WorkCustomerProfile> initialClients;
  final DateTime selectedDay;
  final bool selectForDocument;
  final ValueChanged<List<WorkCustomerProfile>> onClientsChanged;

  @override
  State<SavedClientsScreen> createState() => _SavedClientsScreenState();
}

class _SavedClientsScreenState extends State<SavedClientsScreen> {
  late final _clients = [...widget.initialClients]..sort(_compareClients);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.maybeOf(context);
    final directory = store?.directorySession;
    final canView = directory?.permissions.canViewCustomers ?? true;
    final canAdd =
        canView && (directory?.permissions.canManageCustomers ?? true);
    final clients = directory == null ? _clients : store!.customers;
    final query = _search.text.trim().toLowerCase();
    final visible = (canView ? clients : <WorkCustomerProfile>[]).where((
      client,
    ) {
      if (query.isEmpty) return true;
      return client.name.toLowerCase().contains(query) ||
          client.companyName.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query);
    }).toList()..sort(_compareClients);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = math.max(
              0,
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: AppLayoutEngine.formWorkspaceWidthFor(
                      available.toDouble(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: context.l10n.workSavedClients,
                          selectedDay: widget.selectedDay,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 18),
                        _DirectoryHeading(
                          count: visible.length,
                          onAdd: canAdd ? _addClient : null,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('saved-client-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: context.l10n.workSearchClients,
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!canView)
                          Text(context.l10n.workClientsUnavailable)
                        else if (visible.isEmpty)
                          Text(context.l10n.workNoMatchingClients)
                        else
                          _ClientGrid(
                            clients: visible,
                            onSelected: _openClient,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openClient(WorkCustomerProfile client) async {
    final updated = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(
          initialCustomer: client,
          selectedDay: widget.selectedDay,
          selectForDocument: widget.selectForDocument,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    if (PrototypeOperationsScope.maybeOf(context)?.directorySession == null) {
      final index = _clients.indexWhere(
        (candidate) => candidate.id == updated.id,
      );
      if (index < 0) return;
      setState(() {
        _clients[index] = updated;
        _clients.sort(_compareClients);
      });
      widget.onClientsChanged(List.unmodifiable(_clients));
    }
    if (widget.selectForDocument) Navigator.of(context).pop(updated);
  }

  Future<void> _addClient() async {
    final permissions = PrototypeOperationsScope.of(
      context,
    ).directorySession?.permissions;
    if (permissions != null &&
        (!permissions.canViewCustomers || !permissions.canManageCustomers)) {
      return;
    }
    final created = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: widget.selectedDay),
      ),
    );
    if (!mounted || created == null) return;
    setState(() {
      _clients.add(created);
      _clients.sort(_compareClients);
    });
    if (PrototypeOperationsScope.maybeOf(context)?.directorySession == null) {
      widget.onClientsChanged(List.unmodifiable(_clients));
    }
    if (widget.selectForDocument) Navigator.of(context).pop(created);
  }
}

class _DirectoryHeading extends StatelessWidget {
  const _DirectoryHeading({required this.count, required this.onAdd});

  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 10,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.workSavedClients,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 3),
          Text('$count clients shown in alphabetical order'),
        ],
      ),
      FilledButton.icon(
        key: const ValueKey('add-saved-client-button'),
        onPressed: onAdd,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(context.l10n.workAddClient),
      ),
    ],
  );
}

class _ClientGrid extends StatelessWidget {
  const _ClientGrid({required this.clients, required this.onSelected});

  final List<WorkCustomerProfile> clients;
  final ValueChanged<WorkCustomerProfile> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final client in clients) ...[
        ListTile(
          key: ValueKey('saved-client-${client.id}'),
          contentPadding: EdgeInsets.zero,
          title: Text(client.name),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onSelected(client),
        ),
        if (client != clients.last) const Divider(height: 1),
      ],
    ],
  );
}

int _compareClients(WorkCustomerProfile a, WorkCustomerProfile b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());
