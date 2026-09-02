import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({
    required this.initialProfile,
    required this.selectedDay,
    required this.onSaved,
    super.key,
  });

  final WorkCompanyProfile initialProfile;
  final DateTime selectedDay;
  final ValueChanged<WorkCompanyProfile> onSaved;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late var _profile = widget.initialProfile;

  @override
  Widget build(BuildContext context) {
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
            final layout = AppLayoutEngine.detailWorkspaceFor(
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
                          label: 'My Info',
                          selectedDay: widget.selectedDay,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 18),
                        _CompanyIdentity(
                          profile: _profile,
                          onEdit: _editProfile,
                        ),
                        const SizedBox(height: 14),
                        _CompanyDetailLanes(profile: _profile, layout: layout),
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

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<WorkCompanyProfile>(
      MaterialPageRoute(
        builder: (_) => CompanyProfileEditScreen(
          initialProfile: _profile,
          selectedDay: widget.selectedDay,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _profile = updated);
    widget.onSaved(updated);
  }
}

class _CompanyIdentity extends StatelessWidget {
  const _CompanyIdentity({required this.profile, required this.onEdit});

  final WorkCompanyProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 27,
              child: Text(
                _initials(profile.companyName),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.companyName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(profile.businessCategory),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            key: const ValueKey('edit-company-profile-button'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit company information'),
          ),
        ),
      ],
    ),
  );
}

class _CompanyDetailLanes extends StatelessWidget {
  const _CompanyDetailLanes({required this.profile, required this.layout});

  final WorkCompanyProfile profile;
  final DetailWorkspaceLayout layout;

  @override
  Widget build(BuildContext context) {
    final contact = _DetailSection(
      title: 'Contact and address',
      icon: Icons.contact_phone_outlined,
      rows: [
        ('Phone', profile.phone),
        ('Email', profile.email),
        ('Website', profile.website),
        ('Business address', profile.address),
      ],
    );
    final documents = _DetailSection(
      title: 'Customer document defaults',
      icon: Icons.description_outlined,
      rows: [
        ('Company logo', profile.logoLabel),
        ('Currency', profile.defaultCurrency),
        ('Default payment terms', profile.defaultTerms),
      ],
    );
    if (layout.columns == 1) {
      return Column(
        children: [
          contact,
          SizedBox(height: layout.gap),
          documents,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: layout.columnWidth, child: contact),
        SizedBox(width: layout.gap),
        SizedBox(width: layout.columnWidth, child: documents),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

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
        for (final (label, value) in rows) ...[
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          if ((label, value) != rows.last) const Divider(height: 20),
        ],
      ],
    ),
  );
}

class CompanyProfileEditScreen extends StatefulWidget {
  const CompanyProfileEditScreen({
    required this.initialProfile,
    required this.selectedDay,
    super.key,
  });

  final WorkCompanyProfile initialProfile;
  final DateTime selectedDay;

  @override
  State<CompanyProfileEditScreen> createState() =>
      _CompanyProfileEditScreenState();
}

class _CompanyProfileEditScreenState extends State<CompanyProfileEditScreen> {
  late final _name = TextEditingController(
    text: widget.initialProfile.companyName,
  );
  late final _category = TextEditingController(
    text: widget.initialProfile.businessCategory,
  );
  late final _phone = TextEditingController(text: widget.initialProfile.phone);
  late final _email = TextEditingController(text: widget.initialProfile.email);
  late final _website = TextEditingController(
    text: widget.initialProfile.website,
  );
  late final _address = TextEditingController(
    text: widget.initialProfile.address,
  );
  late final _terms = TextEditingController(
    text: widget.initialProfile.defaultTerms,
  );
  late var _logoLabel = widget.initialProfile.logoLabel;

  @override
  void dispose() {
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
  Widget build(BuildContext context) => Scaffold(
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
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Edit company information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'These confirmed details appear on estimates and invoices. Cancel or Back discards changes.',
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
                            _LogoSelector(
                              label: _logoLabel,
                              onChanged: (value) =>
                                  setState(() => _logoLabel = value),
                            ),
                            const SizedBox(height: 12),
                            _field(_terms, 'Default payment terms', lines: 3),
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'save-company-profile-button',
                                  ),
                                  onPressed: _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Save company information'),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      widget.initialProfile.copyWith(
        companyName: _name.text.trim(),
        businessCategory: _category.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        website: _website.text.trim(),
        address: _address.text.trim(),
        logoLabel: _logoLabel,
        defaultTerms: _terms.text.trim(),
      ),
    );
  }
}

class _LogoSelector extends StatelessWidget {
  const _LogoSelector({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Company logo', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 5),
      Text(label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => onChanged('Logo selected from photos'),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from photos'),
          ),
          OutlinedButton.icon(
            onPressed: () => onChanged('Logo captured with camera'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take logo photo'),
          ),
          OutlinedButton.icon(
            onPressed: () => onChanged('Logo selected from files'),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Choose logo file'),
          ),
        ],
      ),
    ],
  );
}

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
