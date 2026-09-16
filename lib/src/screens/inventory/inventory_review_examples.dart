import 'package:flutter/foundation.dart';

import 'inventory_models.dart';

/// Explicit, debug-only layout examples. Never written to business storage.
const inventoryReviewExamplesEnabled =
    kDebugMode && bool.fromEnvironment('INVENTORY_REVIEW_EXAMPLES');

List<MaterialCostRecord> inventoryReviewCosts() => [
  for (final record in demoMaterialCosts)
    MaterialCostRecord(
      id: 'review-${record.id}',
      materialId: record.materialId,
      materialName: record.materialName,
      trade: record.trade,
      vendor: 'Sample supplier',
      purchasedOn: record.purchasedOn,
      unitCostCents: record.unitCostCents,
      unitLabel: record.unitLabel,
      ownerEmployeeId: record.ownerEmployeeId,
      currencyCode: record.currencyCode,
      confirmedBy: 'Layout example',
    ),
];

List<InventoryStockRecord> inventoryReviewStock() => [...demoInventoryStock];
