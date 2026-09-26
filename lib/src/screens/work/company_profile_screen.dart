import 'company_contact_card.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../data/work/company_document_branding.dart';

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../data/prototype_operations_store.dart';
import '../../shared/section_card.dart';
import 'work_contact_models.dart';
import 'company_profile_editor.dart';

export 'company_profile_editor.dart';
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
                          label: 'Company profile',
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
                        const SizedBox(height: 14),
                        CompanyContactCard(
                          profile: _profile,
                          logo: _CompanyLogo(profile: _profile),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Company information saved.')));
    if (PrototypeOperationsScope.maybeOf(context)?.directorySession == null) {
      widget.onSaved(updated);
    }
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
            _CompanyLogo(profile: profile),
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

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.profile});
  final WorkCompanyProfile profile;
  @override
  Widget build(BuildContext context) {
    final directory = PrototypeOperationsScope.maybeOf(
      context,
    )?.directorySession;
    final fallback = CircleAvatar(
      radius: 27,
      child: Text(
        _initials(profile.companyName),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    if (directory == null || profile.logoReference.isEmpty) return fallback;
    return FutureBuilder<Uint8List?>(
      future: CompanyDocumentBrandingService(
        directory,
      ).readLogo(profile.logoReference),
      builder: (_, snapshot) => snapshot.hasData
          ? SizedBox(
              width: 72,
              height: 72,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                semanticLabel: 'Company logo',
                errorBuilder: (_, _, _) => fallback,
              ),
            )
          : fallback,
    );
  }
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

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
