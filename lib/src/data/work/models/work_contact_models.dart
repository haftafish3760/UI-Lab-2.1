import 'package:flutter/foundation.dart';

@immutable
class WorkCompanyProfile {
  const WorkCompanyProfile({
    required this.companyName,
    required this.businessCategory,
    required this.phone,
    required this.email,
    required this.website,
    required this.address,
    required this.logoLabel,
    this.logoReference = '',
    this.licenseNumber = '',
    this.businessIdentifier = '',
    this.documentFooter = '',
    this.documentAccentColor,
    required this.defaultTerms,
    required this.defaultCurrency,
    this.requireEstimateApproval = false,
  });

  final String companyName;
  final String businessCategory;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String logoLabel,
      logoReference,
      licenseNumber,
      businessIdentifier,
      documentFooter;
  final int? documentAccentColor;
  final String defaultTerms;
  final String defaultCurrency;
  final bool requireEstimateApproval;

  WorkCompanyProfile copyWith({
    String? companyName,
    String? businessCategory,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? logoLabel,
    String? logoReference,
    String? licenseNumber,
    String? businessIdentifier,
    String? documentFooter,
    int? documentAccentColor,
    String? defaultTerms,
    String? defaultCurrency,
    bool? requireEstimateApproval,
  }) => WorkCompanyProfile(
    requireEstimateApproval:
        requireEstimateApproval ?? this.requireEstimateApproval,
    companyName: companyName ?? this.companyName,
    businessCategory: businessCategory ?? this.businessCategory,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    website: website ?? this.website,
    address: address ?? this.address,
    logoLabel: logoLabel ?? this.logoLabel,
    logoReference: logoReference ?? this.logoReference,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    businessIdentifier: businessIdentifier ?? this.businessIdentifier,
    documentFooter: documentFooter ?? this.documentFooter,
    documentAccentColor: documentAccentColor ?? this.documentAccentColor,
    defaultTerms: defaultTerms ?? this.defaultTerms,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
  );
}

@immutable
class WorkServiceLocation {
  const WorkServiceLocation({
    required this.label,
    required this.address,
    this.accessNotes = '',
  });

  final String label;
  final String address;
  final String accessNotes;
}

@immutable
class WorkCustomerProfile {
  const WorkCustomerProfile({
    required this.id,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.preferredContact,
    required this.billingAddress,
    required this.locations,
    required this.notes,
    required this.linkedRecordCount,
  });

  final String id;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String preferredContact;
  final String billingAddress;
  final List<WorkServiceLocation> locations;
  final String notes;
  final int linkedRecordCount;

  WorkCustomerProfile copyWith({
    String? name,
    String? companyName,
    String? phone,
    String? email,
    String? preferredContact,
    String? billingAddress,
    List<WorkServiceLocation>? locations,
    String? notes,
  }) => WorkCustomerProfile(
    id: id,
    name: name ?? this.name,
    companyName: companyName ?? this.companyName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    preferredContact: preferredContact ?? this.preferredContact,
    billingAddress: billingAddress ?? this.billingAddress,
    locations: locations ?? this.locations,
    notes: notes ?? this.notes,
    linkedRecordCount: linkedRecordCount,
  );
}

const demoWorkCompany = WorkCompanyProfile(
  companyName: 'Blue Ridge Service Company',
  businessCategory: 'General contractor and handyman services',
  phone: '(555) 014-2274',
  email: 'office@blueridgeservice.example',
  website: 'blueridgeservice.example',
  address: '1840 Service Road\nRoanoke, VA 24012',
  logoLabel: 'Blue Ridge company logo',
  defaultTerms: 'Payment due within 14 days of invoice date.',
  defaultCurrency: 'USD · United States dollar',
);

const demoWorkCustomers = <WorkCustomerProfile>[
  WorkCustomerProfile(
    id: 'customer-garcia',
    name: 'Elena Garcia',
    companyName: 'Garcia Electric',
    phone: '(555) 014-1198',
    email: 'elena.garcia@example.com',
    preferredContact: 'Text message',
    billingAddress: '18 Pine Way\nRoanoke, VA 24018',
    locations: [
      WorkServiceLocation(
        label: 'Main office',
        address: '18 Pine Way\nRoanoke, VA 24018',
        accessNotes: 'Call on arrival. Electrical room is behind reception.',
      ),
    ],
    notes:
        'Commercial customer. Send estimates for approval before scheduling.',
    linkedRecordCount: 4,
  ),
  WorkCustomerProfile(
    id: 'customer-miller',
    name: 'Jordan Miller',
    companyName: 'Miller Property',
    phone: '(555) 014-6620',
    email: 'jmiller@example.com',
    preferredContact: 'Phone call',
    billingAddress: '48 River Road\nSalem, VA 24153',
    locations: [
      WorkServiceLocation(
        label: 'Rental property',
        address: '48 River Road\nSalem, VA 24153',
        accessNotes: 'Tenant contact is stored with the scheduled job.',
      ),
    ],
    notes: 'Confirm access window before dispatch.',
    linkedRecordCount: 7,
  ),
  WorkCustomerProfile(
    id: 'customer-thompson',
    name: 'Maya Thompson',
    companyName: '',
    phone: '(555) 014-3048',
    email: 'maya.thompson@example.com',
    preferredContact: 'Text message',
    billingAddress: '212 Oak Street\nRoanoke, VA 24016',
    locations: [
      WorkServiceLocation(
        label: 'Home',
        address: '212 Oak Street\nRoanoke, VA 24016',
        accessNotes: 'Dog will be secured. Use the side driveway.',
      ),
      WorkServiceLocation(
        label: 'Rental home',
        address: '906 Elm Avenue\nVinton, VA 24179',
      ),
    ],
    notes: 'Prefers afternoon appointment reminders.',
    linkedRecordCount: 9,
  ),
];
