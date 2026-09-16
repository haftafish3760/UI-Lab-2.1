import '../../data/prototype_operations_store.dart';
import '../../data/work/directory_persistence_session.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'inventory_models.dart';

// Reuse the current record access boundary; display filters never grant access.
List<InventoryStockRecord> visibleInventoryStock(
  PrototypeOperationsStore store,
  OperationalScopeController scope,
) => store.inventoryStock.where((record) {
  final permissions = store.workSession?.permissions;
  if (permissions != null &&
      !permissions.visibleCreatorIds.contains(record.ownerEmployeeId)) {
    return false;
  }
  if (scope.view == AppViewMode.technician) {
    return record.ownerEmployeeId == scope.selectedEmployeeId &&
        record.locationId == scope.selectedVehicleId;
  }
  return true;
}).toList();

Map<String, String> inventoryLocations(
  PrototypeOperationsStore store,
  OperationalScopeController scope,
) {
  final locations = <String, String>{
    for (final vehicle in store.directorySession?.vehicles ?? [])
      if (vehicle.active &&
          (scope.view == AppViewMode.admin ||
              vehicle.id == scope.selectedVehicleId))
        vehicle.id: vehicle.name,
    for (final record in visibleInventoryStock(store, scope))
      record.locationId: record.locationLabel,
  };
  if (scope.view == AppViewMode.technician) {
    locations.putIfAbsent(scope.selectedVehicleId, () => 'Assigned vehicle');
  }
  return locations;
}
