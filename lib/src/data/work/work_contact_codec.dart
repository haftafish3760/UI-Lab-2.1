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
  'companyName': value.companyName,
  'businessCategory': value.businessCategory,
  'phone': value.phone,
  'email': value.email,
  'website': value.website,
  'address': value.address,
  'logoLabel': value.logoLabel,
  'defaultTerms': value.defaultTerms,
  'defaultCurrency': value.defaultCurrency,
};

WorkCompanyProfile decodeWorkCompanyProfile(Map<String, Object?> json) =>
    WorkCompanyProfile(
      companyName: json['companyName'] as String,
      businessCategory: json['businessCategory'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String,
      address: json['address'] as String,
      logoLabel: json['logoLabel'] as String,
      defaultTerms: json['defaultTerms'] as String,
      defaultCurrency: json['defaultCurrency'] as String,
    );
