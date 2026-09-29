import 'models/work_contact_models.dart';
import 'models/work_models.dart';

/// A saved document keeps its selected customer's snapshot. Legacy documents
/// may use a unique exact-name match, but never guess between different clients.
WorkCustomerProfile? resolveWorkDocumentCustomer(
  WorkRecord record,
  Iterable<WorkCustomerProfile> customers,
) {
  if (record.customerSnapshot != null) return record.customerSnapshot;
  if (record.client.trim().isEmpty) return null;
  WorkCustomerProfile? match;
  for (final candidate in customers) {
    if (candidate.name != record.client) continue;
    if (match != null) return null;
    match = candidate;
  }
  return match;
}
