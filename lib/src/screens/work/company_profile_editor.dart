import '../../shared/company_logo_field.dart';
import '../../data/work/company_document_branding.dart';
import '../../data/work/directory_draft_handoff.dart';
import '../../data/work/directory_draft_workflows.dart';
import '../../data/work/company_draft_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/section_card.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

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
  int _baseRevision = 0;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
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
  late final _address = TextEditingController(text: _editingProfile.address);
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
      _address,
      _terms,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Edit My Info',
                          selectedDay: widget.selectedDay,
                          onBack: () => leaveDraftRoute(),
                        ),
                        if (_draft != null)
                          EditorDraftStatus(
                            state: _draft!.state,
                            onRetry: _draft!.retry,
                            onDiscard: _discardCompanyDraft,
                          ),
                        if (_saveError != null) Text(_saveError!),
                        if (!_draftReady && _saveError == null)
                          const Text('Opening saved input…'),
                        if (_draftReady) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Edit company information',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _draft == null
                                ? 'These confirmed details appear on estimates and invoices. Cancel or Back discards changes.'
                                : 'Back keeps unfinished input on this device. Saved changes apply to company information; unfinished input does not change saved documents.',
                          ),
                          const SizedBox(height: 14),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _field(_name, 'Company name'),
                                _field(_category, 'Business category'),
                                _field(_phone, 'Business phone'),
                                _field(_email, 'Business email'),
                                _field(_website, 'Website'),
                                _field(_address, 'Business address', lines: 3),
                                CompanyLogoField(reference: _logoReference,
                                  service: _directory == null ? null : CompanyDocumentBrandingService(_directory!),
                                  onChanged: (reference) => _changeCompanyInput(() {
                                    _logoReference = reference;
                                    _logoLabel = reference.isEmpty ? 'No company logo' : 'Company logo uploaded';
                                  })),
                                const SizedBox(height: 12),
                                _field(
                                  _terms,
                                  'Default payment terms',
                                  lines: 3,
                                ),
                                const SizedBox(height: 4),
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
                                      key: const ValueKey(
                                        'save-company-profile-button',
                                      ),
                                      onPressed: _saving ? null : _save,
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text(
                                        'Save company information',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _save() async {
    if (_saving || !_draftReady) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _saveError = 'Enter the company name.');
      return;
    }
    await _confirmCompany();
  }
}

