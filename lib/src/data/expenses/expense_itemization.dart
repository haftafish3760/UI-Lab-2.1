import 'package:flutter/foundation.dart';
import 'expense_optional_fields.dart';

import 'expense_money.dart';
import 'expense_decimal_value.dart';
import 'expense_unit_price.dart';

export 'expense_decimal_value.dart';
export 'expense_unit_price.dart';

enum ExpenseItemizationMode { totalOnly, itemized }

@immutable
class StoredExpenseLineItem {
  StoredExpenseLineItem({
    required this.lineItemId,
    required this.description,
    required this.categoryId,
    required this.categoryLabelSnapshot,
    required this.packagesPurchased,
    required this.packageStyleCode,
    required this.pricePerPackage,
    required this.extendedTotal,
    this.containedQuantityPerPackage,
    this.containedUnitCode,
    this.partNumber,
    this.jobId,
    this.jobLabelSnapshot,
  }) {
    _requireNonEmpty(lineItemId, 'lineItemId');
    _requireNonEmpty(description, 'description');
    validateOptionalExpenseCategory(categoryId, categoryLabelSnapshot);
    _requireNonEmpty(packageStyleCode, 'packageStyleCode');
    if (packagesPurchased.isZero) {
      throw ArgumentError.value(
        packagesPurchased.decimalValue,
        'packagesPurchased',
        'Must be above zero.',
      );
    }
    if (extendedTotal.minorUnits < 0) {
      throw const FormatException('Receipt line money cannot be negative.');
    }
    if (pricePerPackage.currencyCode != extendedTotal.currencyCode) {
      throw const FormatException('Receipt line currencies must match.');
    }
    final containedQuantity = containedQuantityPerPackage;
    if ((containedQuantity == null) != (containedUnitCode == null)) {
      throw const FormatException(
        'Contained quantity and contained unit must be confirmed together.',
      );
    }
    if (containedQuantity?.isZero ?? false) {
      throw const FormatException('Contained quantity must be above zero.');
    }
  }

  final String lineItemId;
  final String description;
  final String? categoryId;
  final String? categoryLabelSnapshot;
  final ExpenseDecimalValue packagesPurchased;
  final String packageStyleCode;
  final ExpenseUnitPrice pricePerPackage;
  final ExpenseMoney extendedTotal;
  final ExpenseDecimalValue? containedQuantityPerPackage;
  final String? containedUnitCode;
  final String? partNumber;
  final String? jobId;
  final String? jobLabelSnapshot;

  Map<String, Object?> toJson() => {
    'lineItemId': lineItemId,
    'description': description,
    'categoryId': categoryId,
    'categoryLabelSnapshot': categoryLabelSnapshot,
    'packagesPurchased': packagesPurchased.toJson(),
    'packageStyleCode': packageStyleCode,
    'pricePerPackage': pricePerPackage.toJson(),
    'extendedTotal': extendedTotal.toJson(),
    'containedQuantityPerPackage': containedQuantityPerPackage?.toJson(),
    'containedUnitCode': containedUnitCode,
    'partNumber': partNumber,
    'jobId': jobId,
    'jobLabelSnapshot': jobLabelSnapshot,
  };

  factory StoredExpenseLineItem.fromJson(Map<String, Object?> json) =>
      StoredExpenseLineItem(
        lineItemId: _requiredString(json, 'lineItemId'),
        description: _requiredString(json, 'description'),
        categoryId: readOptionalExpenseCategory(json, 'categoryId'),
        categoryLabelSnapshot: readOptionalExpenseCategory(
          json,
          'categoryLabelSnapshot',
        ),
        packagesPurchased: ExpenseDecimalValue.fromJson(
          _requiredMap(json, 'packagesPurchased'),
        ),
        packageStyleCode: _requiredString(json, 'packageStyleCode'),
        pricePerPackage: ExpenseUnitPrice.fromJson(
          _requiredMap(json, 'pricePerPackage'),
        ),
        extendedTotal: ExpenseMoney.fromJson(
          _requiredMap(json, 'extendedTotal'),
        ),
        containedQuantityPerPackage: _optionalDecimal(
          json['containedQuantityPerPackage'],
        ),
        containedUnitCode: json['containedUnitCode'] as String?,
        partNumber: json['partNumber'] as String?,
        jobId: json['jobId'] as String?,
        jobLabelSnapshot: json['jobLabelSnapshot'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is StoredExpenseLineItem &&
      lineItemId == other.lineItemId &&
      description == other.description &&
      categoryId == other.categoryId &&
      categoryLabelSnapshot == other.categoryLabelSnapshot &&
      packagesPurchased == other.packagesPurchased &&
      packageStyleCode == other.packageStyleCode &&
      pricePerPackage == other.pricePerPackage &&
      extendedTotal == other.extendedTotal &&
      containedQuantityPerPackage == other.containedQuantityPerPackage &&
      containedUnitCode == other.containedUnitCode &&
      partNumber == other.partNumber &&
      jobId == other.jobId &&
      jobLabelSnapshot == other.jobLabelSnapshot;

  @override
  int get hashCode => Object.hash(
    lineItemId,
    description,
    categoryId,
    categoryLabelSnapshot,
    packagesPurchased,
    packageStyleCode,
    pricePerPackage,
    extendedTotal,
    containedQuantityPerPackage,
    containedUnitCode,
    partNumber,
    jobId,
    jobLabelSnapshot,
  );
}

@immutable
class ExpenseItemization {
  const ExpenseItemization({
    required this.mode,
    this.lineItems = const [],
    this.subtotal,
    this.salesTax = const ExpenseMoney(minorUnits: 0),
  });

  const ExpenseItemization.totalOnly({
    this.subtotal,
    this.salesTax = const ExpenseMoney(minorUnits: 0),
  }) : mode = ExpenseItemizationMode.totalOnly,
       lineItems = const [];

  final ExpenseItemizationMode mode;
  final List<StoredExpenseLineItem> lineItems;
  final ExpenseMoney? subtotal;
  final ExpenseMoney salesTax;

  ExpenseItemization immutableCopy() => ExpenseItemization(
    mode: mode,
    lineItems: List.unmodifiable(lineItems),
    subtotal: subtotal,
    salesTax: salesTax,
  );

  int get reviewedLineTotalMinorUnits =>
      lineItems.fold(0, (total, line) => total + line.extendedTotal.minorUnits);

  int? get lineToSubtotalDifferenceMinorUnits => subtotal == null
      ? null
      : subtotal!.minorUnits - reviewedLineTotalMinorUnits;

  void validateFor(ExpenseMoney? total) {
    if (mode == ExpenseItemizationMode.totalOnly && lineItems.isNotEmpty) {
      throw const FormatException('Total-only Expenses cannot contain lines.');
    }
    if (mode == ExpenseItemizationMode.itemized && lineItems.isEmpty) {
      throw const FormatException('Itemized Expenses require a receipt line.');
    }
    final ids = lineItems.map((line) => line.lineItemId).toSet();
    if (ids.length != lineItems.length) {
      throw const FormatException('Expense line identities must be unique.');
    }
    if (total == null && mode == ExpenseItemizationMode.itemized) {
      throw const FormatException(
        'An itemized expense requires a confirmed total.',
      );
    }
    final currency = total?.currencyCode ?? salesTax.currencyCode;
    if (salesTax.minorUnits < 0 || (subtotal?.minorUnits ?? 0) < 0) {
      throw const FormatException('Expense totals cannot be negative.');
    }
    if (salesTax.currencyCode != currency ||
        (subtotal != null && subtotal!.currencyCode != currency) ||
        lineItems.any(
          (line) =>
              line.pricePerPackage.currencyCode != currency ||
              line.extendedTotal.currencyCode != currency,
        )) {
      throw const FormatException('Expense itemization currencies must match.');
    }
  }

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'lineItems': lineItems.map((line) => line.toJson()).toList(),
    'subtotal': subtotal?.toJson(),
    'salesTax': salesTax.toJson(),
  };

  factory ExpenseItemization.fromJson(Map<String, Object?> json) =>
      ExpenseItemization(
        mode: ExpenseItemizationMode.values.byName(
          _requiredString(json, 'mode'),
        ),
        lineItems: List.unmodifiable(
          _requiredList(json, 'lineItems').map(
            (value) => StoredExpenseLineItem.fromJson(
              (value as Map).cast<String, Object?>(),
            ),
          ),
        ),
        subtotal: _optionalMoney(json['subtotal']),
        salesTax: ExpenseMoney.fromJson(_requiredMap(json, 'salesTax')),
      );

  @override
  bool operator ==(Object other) =>
      other is ExpenseItemization &&
      mode == other.mode &&
      listEquals(lineItems, other.lineItems) &&
      subtotal == other.subtotal &&
      salesTax == other.salesTax;

  @override
  int get hashCode =>
      Object.hash(mode, Object.hashAll(lineItems), subtotal, salesTax);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('Missing or invalid $key.');
  return value.cast<String, Object?>();
}

Map<String, Object?>? _optionalMap(Object? value) =>
    value is Map ? value.cast<String, Object?>() : null;

ExpenseDecimalValue? _optionalDecimal(Object? value) {
  final map = _optionalMap(value);
  return map == null ? null : ExpenseDecimalValue.fromJson(map);
}

ExpenseMoney? _optionalMoney(Object? value) {
  final map = _optionalMap(value);
  return map == null ? null : ExpenseMoney.fromJson(map);
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing or invalid $key.');
  return value;
}

void _requireNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Cannot be empty.');
  }
}
