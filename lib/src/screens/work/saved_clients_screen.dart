import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

class SavedClientsScreen extends StatefulWidget {
  const SavedClientsScreen({
    required this.initialClients,
    required this.selectedDay,
    required this.onClientsChanged,
    super.key,
  });

  final List<WorkCustomerProfile> initialClients;
  final DateTime selectedDay;
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
    final query = _search.text.trim().toLowerCase();
    final visible = _clients.where((client) {
      if (query.isEmpty) return true;
      return client.name.toLowerCase().contains(query) ||
          client.companyName.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query);
    }).toList();
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
            final layout = AppLayoutEngine.operationsFor(
              available.toDouble(),
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Saved Clients',
                          selectedDay: widget.selectedDay,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 18),
                        _DirectoryHeading(
                          count: visible.length,
                          onAdd: _addClient,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('saved-client-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Search saved clients',
                            hintText: 'Name, company, or email',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (visible.isEmpty)
                          const SectionCard(
                            child: Text(
                              'No saved clients match this search. Change the search or add a new client.',
                            ),
                          )
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
        ),
      ),
    );
    if (!mounted || updated == null) return;
    final index = _clients.indexWhere(
      (candidate) => candidate.id == updated.id,
    );
    if (index < 0) return;
    setState(() {
      _clients[index] = updated;
      _clients.sort(_compareClients);
    });
    if (PrototypeOperationsScope.maybeOf(context)?.directorySession == null) {
      widget.onClientsChanged(List.unmodifiable(_clients));
    }
  }

  Future<void> _addClient() async {
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
  }
}

class _DirectoryHeading extends StatelessWidget {
  const _DirectoryHeading({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

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
            'Saved Clients',
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
        label: const Text('Add new client'),
      ),
    ],
  );
}

class _ClientGrid extends StatelessWidget {
  const _ClientGrid({required this.clients, required this.onSelected});

  final List<WorkCustomerProfile> clients;
  final ValueChanged<WorkCustomerProfile> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = AppLayoutEngine.operationsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      return Wrap(
        spacing: layout.gap,
        runSpacing: layout.gap,
        children: [
          for (final client in clients)
            SizedBox(
              width: layout.laneWidth,
              child: _ClientRow(
                client: client,
                onTap: () => onSelected(client),
              ),
            ),
        ],
      );
    },
  );
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client, required this.onTap});

  final WorkCustomerProfile client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      key: ValueKey('saved-client-${client.id}'),
      minTileHeight: 78,
      onTap: onTap,
      leading: CircleAvatar(child: Text(_initials(client.name))),
      title: Text(
        client.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (client.companyName.isNotEmpty) client.companyName,
          client.phone,
          '${client.locations.length} service location${client.locations.length == 1 ? '' : 's'}',
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

int _compareClients(WorkCustomerProfile a, WorkCustomerProfile b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
