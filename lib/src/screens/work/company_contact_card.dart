import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/work/company_contact_card.dart';
import '../../shared/section_card.dart';
import 'work_contact_models.dart';

class CompanyContactCard extends StatefulWidget {
  const CompanyContactCard({
    required this.profile,
    required this.logo,
    super.key,
  });
  final WorkCompanyProfile profile;
  final Widget logo;
  @override
  State<CompanyContactCard> createState() => _CompanyContactCardState();
}

class _CompanyContactCardState extends State<CompanyContactCard> {
  bool _address = false;
  @override
  Widget build(BuildContext context) {
    final company = widget.profile;
    if (company.companyName.trim().isEmpty) return const SizedBox.shrink();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Company contact card',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              widget.logo,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  company.companyName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Customers can scan this code to view and save your business contact details. No internet connection is needed.',
          ),
          if (company.phone.isNotEmpty) Text(company.phone),
          if (company.email.isNotEmpty) Text(company.email),
          if (company.website.isNotEmpty) Text(company.website),
          if (company.address.isNotEmpty)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include business address'),
              value: _address,
              onChanged: (value) => setState(() => _address = value ?? false),
            ),
          if (_address) Text(company.address),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: AspectRatio(
                aspectRatio: 1,
                child: QrImageView(
                  data: companyContactVCard(company, includeAddress: _address),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  semanticsLabel:
                      'Scan to save ${company.companyName} contact details',
                  errorStateBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'These contact details are too long for a scannable code. Shorten them or leave out the address.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
