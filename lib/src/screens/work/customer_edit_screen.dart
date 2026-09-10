import '../../data/work/directory_draft_handoff.dart';
import '../../data/work/customer_confirmation.dart';
import '../../data/work/customer_draft_workflow.dart';
import '../../data/work/customer_draft_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/section_card.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

part 'customer_editor_persistence.dart';

class CustomerEditScreen extends StatefulWidget {
  const CustomerEditScreen({
    required this.selectedDay,
    this.initialCustomer,
    this.recoveredWorkflow,
    super.key,
  });

  final DateTime selectedDay;
  final WorkCustomerProfile? initialCustomer;
  final CustomerDraftController? recoveredWorkflow;

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen>
    with DraftNavigationGuard {
  DirectoryPersistenceSession? _directory;
  late CustomerDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  WorkCustomerProfile? _recoveredCustomer;
  WorkCustomerProfile? get _editingCustomer =>
      _recoveredCustomer ?? widget.initialCustomer;
  late String _customerId =
      widget.initialCustomer?.id ?? newLocalRecordIdentity('customer');
  bool _draftStarted = false;
  bool _draftReady = false;
  bool _saving = false;
  String? _saveError;
  int _baseRevision = 0;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftStarted) {
      _draftStarted = true;
      _directory = PrototypeOperationsScope.maybeOf(context)?.directorySession;
      unawaited(_openCustomerDraft());
    }
  }

  late final _name = TextEditingController(
    text: widget.initialCustomer?.name ?? '',
  );
  late final _company = TextEditingController(
    text: widget.initialCustomer?.companyName ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.initialCustomer?.phone ?? '',
  );
  late final _email = TextEditingController(
    text: widget.initialCustomer?.email ?? '',
  );
  late final _billing = TextEditingController(
    text: widget.initialCustomer?.billingAddress ?? '',
  );
  late final _notes = TextEditingController(
    text: widget.initialCustomer?.notes ?? '',
  );
  late final _locationLabel = TextEditingController(
    text: _firstLocation?.label ?? 'Primary service location',
  );
  late final _locationAddress = TextEditingController(
    text: _firstLocation?.address ?? '',
  );
  late final _accessNotes = TextEditingController(
    text: _firstLocation?.accessNotes ?? '',
  );
  late var _preferredContact =
      widget.initialCustomer?.preferredContact ?? 'Phone call';
  String? _nameError;

  WorkServiceLocation? get _firstLocation =>
      widget.initialCustomer?.locations.firstOrNull;

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    for (final controller in [
      _name,
      _company,
      _phone,
      _email,
      _billing,
      _notes,
      _locationLabel,
      _locationAddress,
      _accessNotes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialCustomer != null;
    return guardDraftNavigation(
      Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WorkDetailHeader(
                            label: editing ? 'Edit Client' : 'Add Client',
                            selectedDay: widget.selectedDay,
                            onBack: () => leaveDraftRoute(),
                          ),
                          if (_draft != null)
                            EditorDraftStatus(
                              state: _draft!.state,
                              onRetry: _draft!.retry,
                              onDiscard: _discardCustomerDraft,
                            ),
                          if (_saveError != null) Text(_saveError!),
                          if (!_draftReady && _saveError == null)
                            const Text('Opening saved input…'),
                          if (_draftReady) ...[
                            const SizedBox(height: 18),
                            Text(
                              editing
                                  ? 'Edit client information'
                                  : 'Add a new saved client',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              editing
                                  ? _draft == null
                                        ? 'The existing confirmed information is prefilled. Cancel or Back discards changes.'
                                        : 'Back keeps unfinished input on this device. Use Discard unfinished input to remove it.'
                                  : 'Save contact, billing, and service-location information once, then reuse it in Work records.',
                            ),
                            const SizedBox(height: 14),
                            _IdentityForm(
                              name: _name,
                              company: _company,
                              phone: _phone,
                              email: _email,
                              preferredContact: _preferredContact,
                              nameError: _nameError,
                              onPreferredContactChanged: (value) =>
                                  _changeCustomerInput(
                                    () => _preferredContact = value,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            _AddressForm(
                              billing: _billing,
                              locationLabel: _locationLabel,
                              locationAddress: _locationAddress,
                              accessNotes: _accessNotes,
                              additionalLocationCount: mathMax(
                                0,
                                (_editingCustomer?.locations.length ?? 0) - 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SectionCard(
                              child: TextField(
                                controller: _notes,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Client notes',
                                  helperText:
                                      'Keep sensitive notes to the minimum needed for service.',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: () => leaveDraftRoute(),
                                  child: Text(
                                    _draft == null ? 'Cancel' : 'Back',
                                  ),
                                ),
                                FilledButton.icon(
                                  key: const ValueKey('save-client-button'),
                                  onPressed: _saving ? null : _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    editing
                                        ? 'Save client changes'
                                        : 'Save client',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_draftReady || _saving) return;
    await _confirmCustomer();
  }
}

class _IdentityForm extends StatelessWidget {
  const _IdentityForm({
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.preferredContact,
    required this.nameError,
    required this.onPreferredContactChanged,
  });

  final TextEditingController name;
  final TextEditingController company;
  final TextEditingController phone;
  final TextEditingController email;
  final String preferredContact;
  final String? nameError;
  final ValueChanged<String> onPreferredContactChanged;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Client identity and contact',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _AdaptiveFieldPair(
          first: TextField(
            key: const ValueKey('client-name-field'),
            controller: name,
            decoration: InputDecoration(
              labelText: 'Client name',
              errorText: nameError,
            ),
          ),
          second: TextField(
            key: const ValueKey('client-company-field'),
            controller: company,
            decoration: const InputDecoration(
              labelText: 'Company name (optional)',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdaptiveFieldPair(
          first: TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          second: TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: preferredContact,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Preferred contact'),
          items: const ['Phone call', 'Text message', 'Email']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onPreferredContactChanged(value);
          },
        ),
      ],
    ),
  );
}

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.billing,
    required this.locationLabel,
    required this.locationAddress,
    required this.accessNotes,
    required this.additionalLocationCount,
  });

  final TextEditingController billing;
  final TextEditingController locationLabel;
  final TextEditingController locationAddress;
  final TextEditingController accessNotes;
  final int additionalLocationCount;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Billing and service location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: billing,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Billing address'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: locationLabel,
          decoration: const InputDecoration(labelText: 'Location name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: locationAddress,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Service address'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accessNotes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Access instructions or site notes',
          ),
        ),
        if (additionalLocationCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            '$additionalLocationCount additional saved location${additionalLocationCount == 1 ? '' : 's'} will remain unchanged.',
          ),
        ],
      ],
    ),
  );
}

class _AdaptiveFieldPair extends StatelessWidget {
  const _AdaptiveFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      )) {
        return Column(children: [first, const SizedBox(height: 12), second]);
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

int mathMax(int left, int right) => left > right ? left : right;
