import 'work_supply_color.dart';

import 'work_supply_item_intelligence.dart';

export 'work_supply_item_intelligence.dart';

class WorkSupplyTrade {
  const WorkSupplyTrade({
    required this.name,
    required this.color,
    required this.categories,
  });

  final String name;
  final Color color;
  final List<WorkSupplyCategory> categories;
}

class WorkSupplyCategory {
  const WorkSupplyCategory({required this.name, required this.systems});

  final String name;
  final List<WorkSupplySystem> systems;
}

class WorkSupplySystem {
  const WorkSupplySystem({required this.name, required this.itemTypes});

  final String name;
  final List<WorkSupplyItemType> itemTypes;
}

class WorkSupplyItemType {
  const WorkSupplyItemType({required this.name, required this.items});

  final String name;
  final List<WorkSupplyItem> items;
}

class WorkSupplyItem {
  const WorkSupplyItem({
    required this.id,
    required this.name,
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.variant,
    required this.unit,
    this.aliases = const [],
    this.marketScopes = WorkSupplyMarketScopes.all,
    this.packTier = WorkSupplyPackTier.core,
    this.parserPriority = WorkSupplyParserPriority.common,
    this.intelligence = WorkSupplyItemIntelligence.empty,
  });

  final String id;
  final String name;
  final String trade;
  final String category;
  final String system;
  final String itemType;
  final String variant;
  final String unit;
  final List<String> aliases;
  final List<WorkSupplyMarketScope> marketScopes;
  final WorkSupplyPackTier packTier;
  final WorkSupplyParserPriority parserPriority;
  final WorkSupplyItemIntelligence intelligence;

  String get path => '$trade / $category / $system / $itemType';

  String get searchableText {
    return [
      id,
      name,
      trade,
      category,
      system,
      itemType,
      variant,
      unit,
      ...aliases,
      ...intelligence.searchableTokens,
    ].join(' ').toLowerCase();
  }
}

class WorkSupplyInventoryRecord {
  const WorkSupplyInventoryRecord({
    this.id = '',
    required this.item,
    required this.onHand,
    required this.threshold,
    required this.lastUnitCost,
    required this.storageArea,
    required this.receiptLinked,
    this.storageDetail = '',
    this.jobNumber = '',
    this.jobName = '',
    this.createdAt,
    this.updatedAt,
    this.packagesPurchased = 1,
    this.unitsPerPackage = 1,
    this.purchaseType = 'each',
    this.lineSubtotal = 0,
    this.taxRate = 0,
    this.markupRate = 0,
    this.businessUse = 'business',
    this.businessPercent = 1,
    this.loggedAt,
    this.sourceReceiptId = '',
    this.sourceReceiptLineId = '',
    this.sourceMerchantName = '',
  });

  final String id;
  final WorkSupplyItem item;
  final double onHand;
  final double threshold;
  final double lastUnitCost;
  final String storageArea;
  final bool receiptLinked;
  final String storageDetail;
  final String jobNumber;
  final String jobName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double packagesPurchased;
  final double unitsPerPackage;
  final String purchaseType;
  final double lineSubtotal;
  final double taxRate;
  final double markupRate;
  final String businessUse;
  final double businessPercent;
  final DateTime? loggedAt;
  final String sourceReceiptId;
  final String sourceReceiptLineId;
  final String sourceMerchantName;

  bool get isRunningLow => onHand <= threshold;
  double get totalUnitsPurchased => packagesPurchased * unitsPerPackage;
  double get lineTax => lineSubtotal * taxRate;
  double get lineTotal => lineSubtotal + lineTax;
  double get unitCostBeforeTax =>
      totalUnitsPurchased <= 0 ? 0 : lineSubtotal / totalUnitsPurchased;
  double get unitCostWithTax =>
      totalUnitsPurchased <= 0 ? 0 : lineTotal / totalUnitsPurchased;
  double get billableUnitCost => unitCostWithTax * (1 + markupRate);

  WorkSupplyInventoryRecord copyWith({
    String? id,
    double? onHand,
    double? threshold,
    double? lastUnitCost,
    String? storageArea,
    bool? receiptLinked,
    String? storageDetail,
    String? jobNumber,
    String? jobName,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? packagesPurchased,
    double? unitsPerPackage,
    String? purchaseType,
    double? lineSubtotal,
    double? taxRate,
    double? markupRate,
    String? businessUse,
    double? businessPercent,
    DateTime? loggedAt,
    String? sourceReceiptId,
    String? sourceReceiptLineId,
    String? sourceMerchantName,
  }) {
    return WorkSupplyInventoryRecord(
      id: id ?? this.id,
      item: item,
      onHand: onHand ?? this.onHand,
      threshold: threshold ?? this.threshold,
      lastUnitCost: lastUnitCost ?? this.lastUnitCost,
      storageArea: storageArea ?? this.storageArea,
      receiptLinked: receiptLinked ?? this.receiptLinked,
      storageDetail: storageDetail ?? this.storageDetail,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      packagesPurchased: packagesPurchased ?? this.packagesPurchased,
      unitsPerPackage: unitsPerPackage ?? this.unitsPerPackage,
      purchaseType: purchaseType ?? this.purchaseType,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      taxRate: taxRate ?? this.taxRate,
      markupRate: markupRate ?? this.markupRate,
      businessUse: businessUse ?? this.businessUse,
      businessPercent: businessPercent ?? this.businessPercent,
      loggedAt: loggedAt ?? this.loggedAt,
      sourceReceiptId: sourceReceiptId ?? this.sourceReceiptId,
      sourceReceiptLineId: sourceReceiptLineId ?? this.sourceReceiptLineId,
      sourceMerchantName: sourceMerchantName ?? this.sourceMerchantName,
    );
  }
}

class WorkSupplyStockEvent {
  const WorkSupplyStockEvent({
    required this.id,
    required this.inventoryRecordId,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.storageArea,
    required this.occurredAt,
    this.receiptLinked = false,
    this.note = '',
  });

  final String id;
  final String inventoryRecordId;
  final String itemId;
  final String itemName;
  final WorkSupplyStockEventType type;
  final double quantityChange;
  final double quantityBefore;
  final double quantityAfter;
  final String storageArea;
  final DateTime occurredAt;
  final bool receiptLinked;
  final String note;
}

enum WorkSupplyStockEventType {
  stockAdded,
  countAdjusted,
  stockConsumed,
  transfer,
}

class WorkSupplyInventoryTransaction {
  const WorkSupplyInventoryTransaction({
    required this.id,
    required this.inventoryRecordId,
    required this.item,
    required this.type,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.storageArea,
    required this.occurredAt,
    this.storageDetail = '',
    this.destinationStorageArea = '',
    this.destinationStorageDetail = '',
    this.packagesPurchased = 0,
    this.unitsPerPackage = 1,
    this.purchaseType = 'each',
    this.lineSubtotal = 0,
    this.taxRate = 0,
    this.markupRate = 0,
    this.businessUse = 'business',
    this.businessPercent = 1,
    this.receiptLinked = false,
    this.sourceReceiptId = '',
    this.sourceReceiptLineId = '',
    this.sourceMerchantName = '',
    this.jobNumber = '',
    this.jobName = '',
    this.note = '',
    this.createdAt,
    this.replacesTransactionId = '',
    this.reversedTransactionId = '',
  });

  final String id;
  final String inventoryRecordId;
  final WorkSupplyItem item;
  final WorkSupplyStockEventType type;
  final double quantityChange;
  final double quantityBefore;
  final double quantityAfter;
  final String storageArea;
  final String storageDetail;
  final String destinationStorageArea;
  final String destinationStorageDetail;
  final DateTime occurredAt;
  final double packagesPurchased;
  final double unitsPerPackage;
  final String purchaseType;
  final double lineSubtotal;
  final double taxRate;
  final double markupRate;
  final String businessUse;
  final double businessPercent;
  final bool receiptLinked;
  final String sourceReceiptId;
  final String sourceReceiptLineId;
  final String sourceMerchantName;
  final String jobNumber;
  final String jobName;
  final String note;
  final DateTime? createdAt;
  final String replacesTransactionId;
  final String reversedTransactionId;

  double get totalUnitsPurchased => packagesPurchased * unitsPerPackage;
  double get lineTax => lineSubtotal * taxRate;
  double get lineTotal => lineSubtotal + lineTax;
  double get unitCostWithTax =>
      totalUnitsPurchased <= 0 ? 0 : lineTotal / totalUnitsPurchased;
}

class WorkSupplyJob {
  const WorkSupplyJob({
    required this.name,
    required this.number,
    this.customerName = '',
    this.address = '',
    this.assignedVehicles = const [],
    this.workProfiles = const [],
    this.expenseBreakdown = const [],
    this.inventoryBreakdown = const [],
    this.receiptCount = 0,
    this.invoiceStatus = 'Draft',
    this.scheduledDate,
    this.mileage = 0,
    this.expenses = 0,
    this.inventoryItems = 0,
    this.invoiceTotal = 0,
  });

  final String name;
  final String number;
  final String customerName;
  final String address;
  final List<String> assignedVehicles;
  final List<String> workProfiles;
  final List<WorkSupplyJobCostLine> expenseBreakdown;
  final List<WorkSupplyJobCostLine> inventoryBreakdown;
  final int receiptCount;
  final String invoiceStatus;
  final DateTime? scheduledDate;
  final double mileage;
  final double expenses;
  final int inventoryItems;
  final double invoiceTotal;

  double get inventoryTotal {
    return inventoryBreakdown.fold<double>(0, (sum, line) => sum + line.total);
  }

  double get totalCost => expenses + inventoryTotal;
  double get projectedProfit => invoiceTotal - totalCost;
}

class WorkSupplyJobCostLine {
  const WorkSupplyJobCostLine({
    required this.label,
    required this.total,
    this.detail = '',
  });

  final String label;
  final double total;
  final String detail;
}
