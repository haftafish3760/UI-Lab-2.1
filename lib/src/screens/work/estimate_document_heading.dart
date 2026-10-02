import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';

/// Reads the existing company directory; never supplies sample business data.
class EstimateDocumentHeading extends StatelessWidget {
  const EstimateDocumentHeading({
    required this.number,
    required this.status,
    this.onEditCompany,
    super.key,
  });
  final String number, status;
  final VoidCallback? onEditCompany;

  @override
  Widget build(BuildContext context) {
    final directory = PrototypeOperationsScope.of(context).directorySession;
    final company = directory != null && directory.permissions.canViewCompany
        ? directory.company
        : null;
    final theme = Theme.of(context);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          company == null
              ? 'Company information unavailable'
              : company.companyName.trim().isEmpty
              ? 'Your company information'
              : company.companyName,
          key: const ValueKey('estimate-company-heading'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onEditCompany != null)
          TextButton.icon(
            onPressed: onEditCompany,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              company?.companyName.trim().isEmpty == true
                  ? 'Add company information'
                  : 'Edit company information',
            ),
          ),
        if (company != null)
          for (final value in [
            company.address,
            company.phone,
            company.email,
            company.website,
          ])
            if (value.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(value),
              ),
      ],
    );
    final reference = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Text(status, textAlign: TextAlign.end)],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (AppLayoutEngine.stackFormFieldsFor(
                constraints.maxWidth,
                textScaler: MediaQuery.textScalerOf(context),
              )) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [identity, const SizedBox(height: 16), reference],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: identity),
                  const SizedBox(width: 24),
                  Expanded(child: reference),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.primary, thickness: 2, height: 2),
        ],
      ),
    );
  }
}
