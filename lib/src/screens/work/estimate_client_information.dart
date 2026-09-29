import '../../../l10n/app_localizations_extension.dart';
import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import '../../data/work/customer_draft_controller.dart';
import '../../data/work/customer_draft_workflow.dart';
import 'unfinished_client_forms.dart';

enum _ClientView { choices, saved, adding }

/// Client selection and creation stay inside the estimate's client section.
/// Reuses the directory editor and its durable save/recovery implementation.
class EstimateClientInformation extends StatefulWidget {
  const EstimateClientInformation({
    required this.selectedDay,
    required this.selectedClient,
    required this.onSelected,
    super.key,
  });

  final DateTime selectedDay;
  final WorkCustomerProfile? selectedClient;
  final ValueChanged<WorkCustomerProfile> onSelected;

  @override
  State<EstimateClientInformation> createState() =>
      EstimateClientInformationState();
}

class EstimateClientInformationState extends State<EstimateClientInformation> {
  final _search = TextEditingController();
  var _editor = GlobalKey<CustomerEditScreenState>();
  CustomerDraftController? _recoveredWorkflow;
  int _recoveryVersion = 0;
  bool _openingRecovery = false;
  _ClientView _view = _ClientView.choices;
  final _history = <_ClientView>[];
  bool get _adding => _view == _ClientView.adding;
  bool _hasEditor = false;

  void _show(_ClientView view) {
    if (_view == view) return;
    setState(() {
      _history.add(_view);
      _view = view;
      if (_adding) _hasEditor = true;
    });
  }

  Future<bool> backStep() async {
    if (_history.isEmpty) return false;
    await flushPendingInput();
    if (!mounted) return true;
    FocusScope.of(context).unfocus();
    setState(() {
      _view = _history.removeLast();
      _recoveryVersion++;
    });
    return true;
  }

  Future<void> _resume(String draftId) async {
    if (_openingRecovery) return;
    _openingRecovery = true;
    try {
      await flushPendingInput();
      if (!mounted) return;
      final directory = PrototypeOperationsScope.of(context).directorySession;
      if (directory == null) throw StateError('Client storage unavailable.');
      final recovered = await directory.openCustomerDraft(
        recoveryDraftId: draftId,
      );
      if (!mounted) {
        await recovered.session.close();
        return;
      }
      setState(() {
        _editor = GlobalKey<CustomerEditScreenState>();
        _recoveredWorkflow = recovered;
        _hasEditor = true;
      });
      _show(_ClientView.adding);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.clientRecoveryFailed)),
        );
      }
    } finally {
      _openingRecovery = false;
    }
  }

  Future<void> flushPendingInput() async {
    await _editor.currentState?.flushPendingInput();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(WorkCustomerProfile client) {
    final store = PrototypeOperationsScope.of(context);
    if (store.directorySession?.permissions.canViewCustomers == false) return;
    final current = store.customers.where((c) => c.id == client.id).firstOrNull;
    if (current != null) widget.onSelected(current);
  }

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final grants = store.directorySession?.permissions;
    final canView = grants?.canViewCustomers ?? true;
    final canAdd = canView && (grants?.canManageCustomers ?? true);
    final clients = canView ? [...store.customers] : <WorkCustomerProfile>[];
    clients.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    final query = _search.text.trim().toLowerCase();
    final matches = clients
        .where(
          (client) =>
              client.name.toLowerCase().contains(query) ||
              client.companyName.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query) ||
              client.phone.contains(query),
        )
        .toList();
    final selected = widget.selectedClient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('estimate-saved-clients'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onPressed: canView ? () => _show(_ClientView.saved) : null,
                child: Text(
                  context.l10n.clientSaved,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('estimate-add-client'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onPressed: canAdd ? () => _show(_ClientView.adding) : null,
                child: Text(
                  context.l10n.clientAddNew,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (canAdd && _view == _ClientView.choices)
          UnfinishedClientForms(
            key: ValueKey(_recoveryVersion),
            onResume: _resume,
          ),
        if (!canView)
          Text(context.l10n.clientViewDenied)
        else ...[
          if (selected != null && !_adding) ...[
            Text(
              context.l10n.clientForEstimate,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              selected.name,
              key: const ValueKey('estimate-selected-client'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (selected.phone.isNotEmpty) Text(selected.phone),
            if (selected.email.isNotEmpty) Text(selected.email),
            if (selected.billingAddress.isNotEmpty)
              Text(selected.billingAddress),
            const SizedBox(height: 20),
          ],
          if (_view == _ClientView.saved) ...[
            if (clients.isEmpty)
              Text(
                context.l10n.clientNoSaved,
                key: ValueKey('no-saved-clients'),
              )
            else ...[
              TextField(
                key: const ValueKey('saved-client-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.l10n.clientSearch,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.clientSelectForEstimate),
              const SizedBox(height: 8),
              if (matches.isEmpty) Text(context.l10n.clientNoMatches),
              for (final client in matches)
                ListTile(
                  key: ValueKey('saved-client-${client.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(client.name),
                  selected: selected?.id == client.id,
                  trailing: selected?.id == client.id
                      ? const Icon(Icons.check_circle_outline)
                      : const Icon(Icons.person_outline),
                  onTap: () => _select(client),
                ),
            ],
          ],
        ],
        if (_hasEditor)
          Offstage(
            offstage: !_adding || !canAdd,
            child: CustomerEditScreen(
              key: _editor,
              selectedDay: widget.selectedDay,
              embedded: true,
              recoveredWorkflow: _recoveredWorkflow,
              onCancelled: () => setState(() {
                _view = _history.isEmpty
                    ? _ClientView.choices
                    : _history.removeLast();
                _hasEditor = false;
              }),
              onSaved: (client) async {
                _select(client);
                if (mounted) {
                  setState(() {
                    _view = _ClientView.choices;
                    _history.clear();
                    _hasEditor = false;
                    _recoveredWorkflow = null;
                    _recoveryVersion++;
                    _search.clear();
                  });
                }
              },
            ),
          ),
      ],
    );
  }
}
