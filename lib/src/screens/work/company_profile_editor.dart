import '../../shared/company_logo_field.dart';
import '../../shared/business_form_section.dart';
import '../../data/work/company_document_branding.dart';
import '../../data/work/directory_draft_handoff.dart';
import '../../data/work/directory_draft_workflows.dart';
import '../../data/work/company_draft_controller.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../shared/us_phone_input_formatter.dart';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/draft_navigation_guard.dart';
import 'work_contact_models.dart';
import '../../data/work/company_address.dart';

part 'company_profile_draft_recovery.dart';

class CompanyProfileEditScreen extends StatefulWidget {
  const CompanyProfileEditScreen({
    required this.initialProfile,
    required this.selectedDay,
    this.recoveredWorkflow,
    super.key,
  });

  final WorkCompanyProfile initialProfile;
  final DateTime selectedDay;
  final CompanyDraftController? recoveredWorkflow;

  @override
  State<CompanyProfileEditScreen> createState() =>
      _CompanyProfileEditScreenState();
}

class _CompanyProfileEditScreenState extends State<CompanyProfileEditScreen>
    with DraftNavigationGuard {
  DirectoryPersistenceSession? _directory;
  late CompanyDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  WorkCompanyProfile? _draftBaseProfile;
  bool _draftReady = false;
  String? _saveError;
  void _refresh(VoidCallback change) => setState(change);
  WorkCompanyProfile get _editingProfile =>
      _draftBaseProfile ?? _directory?.company ?? widget.initialProfile;
  bool _initialized = false;
  bool _saving = false;
  bool _logoBusy = false;
  bool _askingToLeave = false;
  final _formKey = GlobalKey<FormState>();
  final _fieldKeys =
      <TextEditingController, GlobalKey<FormFieldState<String>>>{};
  final _fieldFocus = <TextEditingController, FocusNode>{};
  bool get _firstSetup => _directory != null
      ? _baseRevision == 0
      : widget.initialProfile.companyName.trim().isEmpty;
  String get _saveLabel =>
      _firstSetup ? 'Save company information' : 'Save changes';
  int _baseRevision = 0;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving || _logoBusy;
  @override
  bool get requiresDraftPopGuard => true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _directory = PrototypeOperationsScope.maybeOf(context)?.directorySession;
      _baseRevision = _directory?.companyRevision ?? 0;
      unawaited(_openCompanyDraft());
    }
  }

  late final _name = TextEditingController(text: _editingProfile.companyName);
  late final _category = TextEditingController(
    text: _editingProfile.businessCategory,
  );
  late final _phone = TextEditingController(text: _editingProfile.phone);
  late final _email = TextEditingController(text: _editingProfile.email);
  late final _website = TextEditingController(text: _editingProfile.website);
  late final _originalAddress = _editingProfile.addressParts.isEmpty
      ? CompanyAddress.fromLegacy(_editingProfile.address)
      : CompanyAddress.fromMap(_editingProfile.addressParts);
  late final _street = TextEditingController(text: _originalAddress.street);
  late final _unit = TextEditingController(text: _originalAddress.unit);
  late final _city = TextEditingController(text: _originalAddress.city);
  late final _state = TextEditingController(text: _originalAddress.state);
  late final _zip = TextEditingController(text: _originalAddress.zip);
  late String _legacyAddress = _originalAddress.legacy;
  CompanyAddress get _companyAddress => CompanyAddress(
    street: _street.text,
    unit: _unit.text,
    city: _city.text,
    state: _state.text,
    zip: _zip.text,
    legacy: _legacyAddress,
  );
  bool get _addressChanged =>
      _street.text != _originalAddress.street ||
      _unit.text != _originalAddress.unit ||
      _city.text != _originalAddress.city ||
      _state.text != _originalAddress.state ||
      _zip.text != _originalAddress.zip;
  late String _logoReference = _editingProfile.logoReference;
  late final _terms = TextEditingController(text: _editingProfile.defaultTerms);
  late var _logoLabel = _editingProfile.logoLabel;

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    for (final controller in [
      _name,
      _category,
      _phone,
      _email,
      _website,
      _street,
      _unit,
      _city,
      _state,
      _zip,
      _terms,
    ]) {
      controller.dispose();
    }
    for (final focus in _fieldFocus.values) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,

      body: Form(
        key: _formKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => leaveDraftRoute(),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _firstSetup
                                      ? 'Add company information'
                                      : 'Edit company information',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          if (!_draftReady)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _saveError ?? 'Opening company information…',
                              ),
                            ),
                          if (_draftReady) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Your business details appear on estimates, quotes, and invoices.',
                            ),
                            if (_draft != null && _hasCompanyChanges)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: EditorDraftStatus(
                                  state: _draft!.state,
                                  onRetry: _draft!.retry,
                                ),
                              ),
                            const SizedBox(height: 16),
                            BusinessFormSection(
                              title: 'Business identity',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _pair(
                                    _field(_name, 'Company name'),
                                    _field(_category, 'Business category'),
                                  ),
                                  CompanyLogoField(
                                    reference: _logoReference,
                                    onBusyChanged: (busy) =>
                                        setState(() => _logoBusy = busy),
                                    service: _directory == null
                                        ? null
                                        : CompanyDocumentBrandingService(
                                            _directory!,
                                          ),
                                    onChanged: (reference) =>
                                        _changeCompanyInput(() {
                                          _logoReference = reference;
                                          _logoLabel = reference.isEmpty
                                              ? 'No company logo'
                                              : 'Company logo uploaded';
                                        }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            BusinessFormSection(
                              title: 'Business address',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_legacyAddress.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Previously saved address: $_legacyAddress\nEnter the individual fields below to update it.',
                                      ),
                                    ),
                                  _field(
                                    _street,
                                    'Street address',
                                    hints: const [
                                      AutofillHints.streetAddressLine1,
                                    ],
                                  ),
                                  _field(
                                    _unit,
                                    'Apartment or suite (optional)',
                                    hints: const [
                                      AutofillHints.streetAddressLine2,
                                    ],
                                  ),
                                  _field(
                                    _city,
                                    'City',
                                    hints: const [AutofillHints.addressCity],
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final fields = [
                                        _field(
                                          _state,
                                          'State',
                                          formatters: [
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                          hints: const [
                                            AutofillHints.addressState,
                                          ],
                                        ),
                                        _field(
                                          _zip,
                                          'ZIP code',
                                          keyboard: TextInputType.number,
                                          formatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9-]'),
                                            ),
                                            LengthLimitingTextInputFormatter(
                                              10,
                                            ),
                                          ],
                                          hints: const [
                                            AutofillHints.postalCode,
                                          ],
                                        ),
                                      ];
                                      if (AppLayoutEngine.stackCompactFieldsFor(
                                        constraints.maxWidth,
                                        textScaler: MediaQuery.textScalerOf(
                                          context,
                                        ),
                                      )) {
                                        return Column(children: fields);
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: fields[0]),
                                          const SizedBox(width: 12),
                                          Expanded(child: fields[1]),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            BusinessFormSection(
                              title: 'Contact details',
                              child: Column(
                                children: [
                                  _pair(
                                    _field(
                                      _phone,
                                      'Business phone',
                                      keyboard: TextInputType.phone,
                                      formatters: const [
                                        UsPhoneInputFormatter(),
                                      ],
                                      hints: const [
                                        AutofillHints.telephoneNumberNational,
                                      ],
                                    ),
                                    _field(
                                      _email,
                                      'Business email',
                                      keyboard: TextInputType.emailAddress,
                                      hints: const [AutofillHints.email],
                                    ),
                                  ),
                                  _field(
                                    _website,
                                    'Website',
                                    keyboard: TextInputType.url,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  (_draftReady
                          ? SafeArea(
                              top: false,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Center(
                                  heightFactor: 1,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 720,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_saveError != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Semantics(
                                              liveRegion: true,
                                              child: Text(
                                                _saveError!,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () =>
                                                  leaveDraftRoute(),
                                              child: const Text('Cancel'),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FilledButton.icon(
                                                key: const ValueKey(
                                                  'save-company-profile-button',
                                                ),
                                                onPressed: _saving || _logoBusy
                                                    ? null
                                                    : _save,
                                                icon: const Icon(
                                                  Icons.save_outlined,
                                                ),
                                                label: Text(
                                                  _saving
                                                      ? 'Saving…'
                                                      : _saveLabel,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : null) ??
                      const SizedBox.shrink(),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (AppLayoutEngine.stackFormFieldsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      )) {
        return Column(children: [first, second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    List<String>? hints,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: _fieldKeys.putIfAbsent(
        controller,
        () => GlobalKey<FormFieldState<String>>(),
      ),
      focusNode: _fieldFocus.putIfAbsent(controller, FocusNode.new),
      controller: controller,
      maxLines: lines,
      keyboardType:
          keyboard ??
          (lines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters: formatters,
      autofillHints: hints,
      autocorrect: keyboard == null,
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      validator: (value) {
        final text = (value ?? '').trim();
        if (controller == _name && text.isEmpty) {
          return 'Enter the company name.';
        }
        if (controller == _phone &&
            text.isNotEmpty &&
            UsPhoneInputFormatter.digits(text).length != 10) {
          return 'Enter a 10-digit phone number, including the area code.';
        }
        if (controller == _email &&
            text.isNotEmpty &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Enter a valid email address.';
        }
        if (_addressChanged &&
            [_street, _city, _state, _zip].contains(controller)) {
          if (text.isEmpty) return 'Enter ${label.toLowerCase()}.';
          if (controller == _state &&
              !RegExp(r'^[A-Za-z]{2}$').hasMatch(text)) {
            return 'Use two letters, such as VA.';
          }
          if (controller == _zip &&
              !RegExp(r'^\d{5}(-\d{4})?$').hasMatch(text)) {
            return 'Enter a 5-digit ZIP or ZIP+4.';
          }
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    ),
  );

  bool get _hasCompanyChanges {
    final base = _editingProfile;
    return _name.text != base.companyName ||
        _category.text != base.businessCategory ||
        UsPhoneInputFormatter.digits(_phone.text) !=
            UsPhoneInputFormatter.digits(base.phone) ||
        _email.text != base.email ||
        _website.text != base.website ||
        _addressChanged ||
        _terms.text != base.defaultTerms ||
        _logoReference != base.logoReference;
  }

  @override
  Future<void> leaveDraftRoute([Object? result]) async {
    if (_askingToLeave || blockDraftNavigation) return;
    _askingToLeave = true;
    try {
      if (_hasCompanyChanges) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              _firstSetup
                  ? 'Save your company information?'
                  : 'Save company changes?',
            ),
            content: const Text(
              'Your company information or logo has changed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: const Text('Discard changes'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Text('Save changes'),
              ),
            ],
          ),
        );
        if (!mounted || choice == null) return;
        if (choice == 'save') {
          await _save();
          return;
        }
      }
      setState(() => _saving = true);
      await _draft?.discard();
      if (mounted) await finishDraftRoute(result);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError =
              'Could not finish leaving. Your input has been kept. Please retry.';
        });
      }
    } finally {
      _askingToLeave = false;
    }
  }

  Future<void> _save() async {
    if (_saving || _logoBusy || !_draftReady) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      await WidgetsBinding.instance.endOfFrame;
      for (final entry in _fieldKeys.entries) {
        if (entry.value.currentState?.hasError ?? false) {
          _fieldFocus[entry.key]?.requestFocus();
          final target = entry.value.currentContext;
          if (target != null && target.mounted) {
            await Scrollable.ensureVisible(
              target,
              duration: const Duration(milliseconds: 200),
              alignment: .15,
            );
          }
          break;
        }
      }
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _saveError = 'Enter the company name.');
      return;
    }
    await _confirmCompany();
  }
}
