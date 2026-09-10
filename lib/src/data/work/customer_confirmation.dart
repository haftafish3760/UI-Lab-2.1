import 'customer_draft_controller.dart';
import 'models/work_contact_models.dart';

class CustomerInputValidation implements Exception {
  const CustomerInputValidation(this.message);
  final String message;
}

/// Edit the primary location while retaining all other confirmed locations.
WorkCustomerProfile buildConfirmedCustomer(CustomerDraftInput input) {
  if (input.name.trim().isEmpty) {
    throw const CustomerInputValidation('Enter the client name.');
  }
  final location = WorkServiceLocation(
    label: input.locationLabel.trim().isEmpty
        ? 'Primary service location'
        : input.locationLabel.trim(),
    address: input.locationAddress.trim(),
    accessNotes: input.accessNotes.trim(),
  );
  return WorkCustomerProfile(
    id: input.customerId,
    name: input.name.trim(),
    companyName: input.company.trim(),
    phone: input.phone.trim(),
    email: input.email.trim(),
    preferredContact: input.preferredContact,
    billingAddress: input.billing.trim(),
    locations: [location, ...?input.existingCustomer?.locations.skip(1)],
    notes: input.notes.trim(),
    linkedRecordCount: input.existingCustomer?.linkedRecordCount ?? 0,
  );
}
