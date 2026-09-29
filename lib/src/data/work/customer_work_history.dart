import 'models/work_contact_models.dart';
import 'models/work_models.dart';

/// Filters an already-authorized Work projection. Snapshot identity wins over
/// names, including when a client has since changed their name. Legacy records
/// without an identity may match a name only when the directory is unambiguous.
List<WorkRecord> customerWorkHistory({
  required WorkCustomerProfile customer,
  required Iterable<WorkCustomerProfile> directory,
  required Iterable<WorkRecord> visibleRecords,
}) {
  final sameNameIds = directory
      .where((entry) => entry.name == customer.name)
      .map((entry) => entry.id)
      .toSet();
  final canMatchLegacyName =
      sameNameIds.length == 1 && sameNameIds.contains(customer.id);
  return visibleRecords.where((record) {
    final snapshotId = record.customerSnapshot?.id;
    if (snapshotId != null && snapshotId.isNotEmpty) {
      return snapshotId == customer.id;
    }
    return canMatchLegacyName && record.client == customer.name;
  }).toList()..sort((a, b) {
    final dateOrder = (b.createdOn ?? DateTime(0)).compareTo(
      a.createdOn ?? DateTime(0),
    );
    return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
  });
}
