import 'models/work_contact_models.dart';

Map<String, Object?> encodeWorkCustomerProfile(WorkCustomerProfile value) => {
  'id': value.id,
  'name': value.name,
  'companyName': value.companyName,
  'phone': value.phone,
  'email': value.email,
  'preferredContact': value.preferredContact,
  'billingAddress': value.billingAddress,
  'locations': value.locations
      .map((item) => encodeWorkServiceLocation(item))
      .toList(),
  'notes': value.notes,
  'linkedRecordCount': value.linkedRecordCount,
};

WorkCustomerProfile decodeWorkCustomerProfile(Map<String, Object?> json) =>
    WorkCustomerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      companyName: json['companyName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      preferredContact: json['preferredContact'] as String,
      billingAddress: json['billingAddress'] as String,
      locations: List.unmodifiable(
        (json['locations'] as List).map(
          (item) =>
              decodeWorkServiceLocation((item as Map).cast<String, Object?>()),
        ),
      ),
      notes: json['notes'] as String,
      linkedRecordCount: json['linkedRecordCount'] as int,
    );

Map<String, Object?> encodeWorkServiceLocation(WorkServiceLocation value) => {
  'label': value.label,
  'address': value.address,
  'accessNotes': value.accessNotes,
};

WorkServiceLocation decodeWorkServiceLocation(Map<String, Object?> json) =>
    WorkServiceLocation(
      label: json['label'] as String,
      address: json['address'] as String,
      accessNotes: json['accessNotes'] as String,
    );

Map<String, Object?> encodeWorkCompanyProfile(WorkCompanyProfile value) => {
  'requireEstimateApproval': value.requireEstimateApproval,
  'companyName': value.companyName,
  'businessCategory': value.businessCategory,
  'phone': value.phone,
  'email': value.email,
  'website': value.website,
  'address': value.address,
  'addressParts': value.addressParts,
  'logoLabel': value.logoLabel,
  'logoReference': value.logoReference,
  'licenseNumber': value.licenseNumber,
  'businessIdentifier': value.businessIdentifier,
  'documentFooter': value.documentFooter,
  'documentAccentColor': value.documentAccentColor,
  'defaultTerms': value.defaultTerms,
  'estimateTermsTemplates': value.estimateTermsTemplates,
  'defaultEstimateTerms': value.defaultEstimateTerms,
  'defaultCurrency': value.defaultCurrency,
};

WorkCompanyProfile decodeWorkCompanyProfile(
  Map<String, Object?> json,
) => WorkCompanyProfile(
  requireEstimateApproval: json['requireEstimateApproval'] as bool? ?? false,
  companyName: json['companyName'] as String,
  businessCategory: json['businessCategory'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  website: json['website'] as String,
  address: json['address'] as String,
  addressParts: Map.unmodifiable(
    (json['addressParts'] as Map? ?? const {}).cast<String, String>(),
  ),
  logoLabel: json['logoLabel'] as String,
  logoReference: json['logoReference'] as String? ?? '',
  licenseNumber: json['licenseNumber'] as String? ?? '',
  businessIdentifier: json['businessIdentifier'] as String? ?? '',
  documentFooter: json['documentFooter'] as String? ?? '',
  documentAccentColor: json['documentAccentColor'] as int?,
  defaultTerms: json['defaultTerms'] as String,
  estimateTermsTemplates: Map.unmodifiable(
    (json['estimateTermsTemplates'] as Map? ?? const {}).cast<String, String>(),
  ),
  defaultEstimateTerms: json['defaultEstimateTerms'] as String? ?? '',
  defaultCurrency: json['defaultCurrency'] as String,
);
