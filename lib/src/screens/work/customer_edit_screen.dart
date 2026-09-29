import '../../../l10n/app_localizations_extension.dart';
import '../../shared/us_phone_input_formatter.dart';
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
import '../../shared/utility_form_section.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

part 'customer_editor_persistence.dart';

class CustomerEditScreen extends StatefulWidget {
  const CustomerEditScreen({
    required this.selectedDay,
    this.initialCustomer,
    this.offerEstimateOnly = false,
    this.embedded = false,
    this.onSaved,
    this.onCancelled,
    this.recoveredWorkflow,
    super.key,
  });

  final DateTime selectedDay;
  final bool offerEstimateOnly;
  final bool embedded;
  final VoidCallback? onCancelled;
  final Future<void> Function(WorkCustomerProfile)? onSaved;
  final WorkCustomerProfile? initialCustomer;
  final CustomerDraftController? recoveredWorkflow;

  @override
  State<CustomerEditScreen> createState() => CustomerEditScreenState();
}

class CustomerEditScreenState extends State<CustomerEditScreen>
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
    text: _firstLocation?.label ?? '',
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
    if (widget.embedded) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      return Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: false,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
          ),
        ),
        child: AbsorbPointer(absorbing: _saving, child: _buildForm()),
      );
    }
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
                      constraints: BoxConstraints(
                        maxWidth: AppLayoutEngine.formWorkspaceWidthFor(
                          constraints.maxWidth - insets.horizontal,
                        ),
                      ),
                      child: _buildForm(),
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

  Future<void> flushPendingInput() async {
    if (_saving) throw StateError('Wait for the client to finish saving.');
    _captureCustomerInput();
    await _draft?.flush();
  }

  Widget _buildForm() {
    final editing = widget.initialCustomer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          WorkDetailHeader(
            label: editing
                ? context.l10n.clientEdit
                : context.l10n.clientAddNew,
            selectedDay: widget.selectedDay,
            onBack: () => leaveDraftRoute(),
          ),
        if (_draft != null &&
            (!widget.embedded || _draft!.state == DraftSaveState.notSaved))
          EditorDraftStatus(
            state: _draft!.state,
            onRetry: _draft!.retry,
            onDiscard: widget.embedded ? null : _discardCustomerDraft,
          ),
        if (_saveError != null) Text(_saveError!),
        if (!_draftReady && _saveError == null) Text('Opening saved input…'),
        if (_draftReady) ...[
          const SizedBox(height: 20),
          _IdentityForm(
            name: _name,
            company: _company,
            phone: _phone,
            email: _email,
            preferredContact: _preferredContact,
            nameError: _nameError,
            onPreferredContactChanged: (value) =>
                _changeCustomerInput(() => _preferredContact = value),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          UtilityFormSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.clientNotesHint),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n.clientNotes,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!widget.embedded)
                OutlinedButton(
                  onPressed: () => leaveDraftRoute(),
                  child: Text(_draft == null ? 'Cancel' : 'Back'),
                ),
              FilledButton.icon(
                key: const ValueKey('save-client-button'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  editing
                      ? context.l10n.clientSaveChanges
                      : widget.embedded
                      ? context.l10n.clientSaveUse
                      : widget.offerEstimateOnly
                      ? 'Use customer'
                      : context.l10n.clientSave,
                ),
              ),
            ],
          ),
        ],
      ],
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
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.clientDetails,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        _AdaptiveFieldPair(
          first: TextField(
            key: const ValueKey('client-name-field'),
            controller: name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.clientName,
              hintText: context.l10n.clientNameHint,
              errorText: nameError,
            ),
          ),
          second: TextField(
            key: const ValueKey('client-company-field'),
            controller: company,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.l10n.clientBusiness),
          ),
        ),
        const SizedBox(height: 20),
        _AdaptiveFieldPair(
          first: TextField(
            controller: phone,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: const [UsPhoneInputFormatter()],
            decoration: InputDecoration(labelText: context.l10n.clientPhone),
          ),
          second: TextField(
            controller: email,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: context.l10n.clientEmail),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: preferredContact,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.clientPreferredContact,
          ),
          items: const ['Phone call', 'Text message', 'Email']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(switch (value) {
                    'Phone call' => context.l10n.clientCall,
                    'Text message' => context.l10n.clientText,
                    _ => context.l10n.clientEmailMethod,
                  }),
                ),
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
  Widget build(BuildContext context) => UtilityFormSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.clientLocations,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: billing,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.clientBilling),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: locationLabel,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.clientAddressLabel,
            hintText: context.l10n.clientAddressHint,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: locationAddress,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.clientServiceAddress,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: accessNotes,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.clientAccess,
            hintText: context.l10n.clientAccessHint,
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
        return Column(children: [first, const SizedBox(height: 20), second]);
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
