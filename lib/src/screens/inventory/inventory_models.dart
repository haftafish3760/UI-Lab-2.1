import 'package:flutter/foundation.dart';

enum InventoryStockConfidence { verified, reported, unknown }

extension InventoryStockConfidenceLabel on InventoryStockConfidence {
  String get label => switch (this) {
    InventoryStockConfidence.verified => 'Count verified',
    InventoryStockConfidence.reported => 'Reported amount',
    InventoryStockConfidence.unknown => 'Count unknown',
  };
}

@immutable
class MaterialCostRecord {
  const MaterialCostRecord({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.trade,
    required this.vendor,
    required this.purchasedOn,
    required this.unitCostCents,
    required this.unitLabel,
    required this.ownerEmployeeId,
    required this.currencyCode,
    required this.confirmedBy,
    this.sourceExpenseId,
    this.sourceReceiptId,
  });

  final String id;
  final String materialId;
  final String materialName;
  final String trade;
  final String vendor;
  final DateTime purchasedOn;
  final int unitCostCents;
  final String unitLabel;
  final String ownerEmployeeId;
  final String currencyCode;
  final String confirmedBy;
  final String? sourceExpenseId;
  final String? sourceReceiptId;

  bool get hasReceiptEvidence => sourceReceiptId != null;
  bool get hasExpenseSource => sourceExpenseId != null;
}

@immutable
class InventoryStockRecord {
  const InventoryStockRecord({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.locationId,
    required this.locationLabel,
    required this.quantity,
    required this.unitLabel,
    required this.confidence,
    required this.updatedOn,
    required this.ownerEmployeeId,
    this.lowAt,
  });

  final String id;
  final String materialId;
  final String materialName;
  final String locationId;
  final String locationLabel;
  final double quantity;
  final String unitLabel;
  final InventoryStockConfidence confidence;
  final DateTime updatedOn;
  final String ownerEmployeeId;
  final double? lowAt;

  bool get isLow =>
      confidence != InventoryStockConfidence.unknown &&
      lowAt != null &&
      quantity <= lowAt!;

  InventoryStockRecord copyWith({
    double? quantity,
    InventoryStockConfidence? confidence,
    DateTime? updatedOn,
  }) => InventoryStockRecord(
    id: id,
    materialId: materialId,
    materialName: materialName,
    locationId: locationId,
    locationLabel: locationLabel,
    quantity: quantity ?? this.quantity,
    unitLabel: unitLabel,
    confidence: confidence ?? this.confidence,
    updatedOn: updatedOn ?? this.updatedOn,
    ownerEmployeeId: ownerEmployeeId,
    lowAt: lowAt,
  );
}

DateTime inventoryDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool sameInventoryDay(DateTime left, DateTime right) =>
    inventoryDay(left) == inventoryDay(right);

String inventoryMoney(int cents, {String currencyCode = 'USD'}) {
  final value = (cents / 100).toStringAsFixed(2);
  return currencyCode == 'USD' ? '\$$value' : '$currencyCode $value';
}

final inventoryDemoToday = inventoryDay(DateTime.now());

final demoMaterialCosts = <MaterialCostRecord>[
  MaterialCostRecord(
    id: 'cost-1001',
    materialId: 'faucet-supply-line',
    materialName: 'Braided faucet supply line',
    trade: 'Plumbing',
    vendor: 'Central Supply',
    purchasedOn: inventoryDemoToday,
    unitCostCents: 1875,
    unitLabel: 'each',
    ownerEmployeeId: 'alex',
    currencyCode: 'USD',
    confirmedBy: 'Alex Morgan',
    sourceExpenseId: 'EXP-1048',
    sourceReceiptId: 'receipt-1048',
  ),
  MaterialCostRecord(
    id: 'cost-1002',
    materialId: 'faucet-supply-line',
    materialName: 'Braided faucet supply line',
    trade: 'Plumbing',
    vendor: 'Builders Market',
    purchasedOn: inventoryDemoToday.subtract(const Duration(days: 24)),
    unitCostCents: 1698,
    unitLabel: 'each',
    ownerEmployeeId: 'alex',
    currencyCode: 'USD',
    confirmedBy: 'Alex Morgan',
  ),
  MaterialCostRecord(
    id: 'cost-1003',
    materialId: 'ptfe-tape',
    materialName: 'PTFE thread seal tape',
    trade: 'Plumbing',
    vendor: 'Central Supply',
    purchasedOn: inventoryDemoToday,
    unitCostCents: 248,
    unitLabel: 'roll',
    ownerEmployeeId: 'alex',
    currencyCode: 'USD',
    confirmedBy: 'Alex Morgan',
    sourceExpenseId: 'EXP-1048',
    sourceReceiptId: 'receipt-1048',
  ),
  MaterialCostRecord(
    id: 'cost-1004',
    materialId: 'air-filter-20x25',
    materialName: '20 × 25 pleated air filter',
    trade: 'HVAC',
    vendor: 'Regional HVAC Supply',
    purchasedOn: inventoryDemoToday.subtract(const Duration(days: 1)),
    unitCostCents: 1180,
    unitLabel: 'each',
    ownerEmployeeId: 'jordan',
    currencyCode: 'USD',
    confirmedBy: 'Jordan Lee',
  ),
];

final demoInventoryStock = <InventoryStockRecord>[
  InventoryStockRecord(
    id: 'stock-1001',
    materialId: 'faucet-supply-line',
    materialName: 'Braided faucet supply line',
    locationId: 'transit-12',
    locationLabel: 'Transit 12',
    quantity: 2,
    unitLabel: 'each',
    confidence: InventoryStockConfidence.verified,
    updatedOn: inventoryDemoToday,
    ownerEmployeeId: 'alex',
    lowAt: 2,
  ),
  InventoryStockRecord(
    id: 'stock-1002',
    materialId: 'ptfe-tape',
    materialName: 'PTFE thread seal tape',
    locationId: 'transit-12',
    locationLabel: 'Transit 12',
    quantity: 7,
    unitLabel: 'rolls',
    confidence: InventoryStockConfidence.reported,
    updatedOn: inventoryDemoToday.subtract(const Duration(days: 3)),
    ownerEmployeeId: 'alex',
    lowAt: 3,
  ),
  InventoryStockRecord(
    id: 'stock-1003',
    materialId: 'air-filter-20x25',
    materialName: '20 × 25 pleated air filter',
    locationId: 'service-van-4',
    locationLabel: 'Service Van 4',
    quantity: 0,
    unitLabel: 'each',
    confidence: InventoryStockConfidence.unknown,
    updatedOn: inventoryDemoToday.subtract(const Duration(days: 35)),
    ownerEmployeeId: 'jordan',
    lowAt: 2,
  ),
];
