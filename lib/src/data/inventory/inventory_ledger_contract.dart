import 'stock_quantity.dart';

/// A fresh scoped grant supplied by the owning application permission service.
/// The repository never supplies a permissive default or trusts a widget flag.
class InventoryLedgerAccess {
  InventoryLedgerAccess({
    required this.organizationId,
    required this.actorId,
    required this.revision,
    required Set<String> readableLocations,
    required Set<String> writableLocations,
  }) : readableLocations = Set.unmodifiable(readableLocations),
       writableLocations = Set.unmodifiable(writableLocations);
  final String organizationId, actorId;
  final int revision;
  final Set<String> readableLocations, writableLocations;
}

/// Resolved from the catalog/custom-item boundary, never inferred from a label.
class InventoryLedgerItem {
  const InventoryLedgerItem({
    required this.id,
    required this.label,
    required this.stockUnit,
    required this.allowsFractional,
  });
  final String id, label, stockUnit;
  final bool allowsFractional;
}

class InventoryLedgerLocation {
  const InventoryLedgerLocation({
    required this.id,
    required this.label,
    required this.active,
  });
  final String id, label;
  final bool active;
}

enum InventoryLedgerAction { receive, consume }

class InventoryTransferRequest {
  const InventoryTransferRequest({
    required this.commandId,
    required this.itemId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.quantity,
    required this.expectedFromRevision,
    required this.expectedToRevision,
  });
  final String commandId, itemId, fromLocationId, toLocationId;
  final StockQuantity quantity;
  final int expectedFromRevision, expectedToRevision;
}

class InventoryLedgerRequest {
  const InventoryLedgerRequest({
    required this.commandId,
    required this.itemId,
    required this.locationId,
    required this.quantity,
    required this.action,
    required this.expectedRevision,
    this.sourceReference,
  });
  final String commandId, itemId, locationId;
  final StockQuantity quantity;
  final InventoryLedgerAction action;
  final int expectedRevision;
  final String? sourceReference;
}

class InventoryLedgerBalance {
  const InventoryLedgerBalance({
    required this.itemId,
    required this.locationId,
    required this.stockUnit,
    required this.quantity,
    required this.revision,
  });
  final String itemId, locationId, stockUnit;
  final StockQuantity quantity;
  final int revision;
}
