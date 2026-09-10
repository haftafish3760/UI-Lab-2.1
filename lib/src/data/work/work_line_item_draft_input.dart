import 'models/work_models.dart';
import 'work_record_detail_codec.dart';

/// Raw line input and source identity, independent of controllers and widgets.
class WorkLineItemDraftInput {
  const WorkLineItemDraftInput({
    required this.lineId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.cost,
    required this.type,
    required this.unit,
    required this.billingTreatment,
    this.original,
    this.sourceExpenseId,
    this.sourceExpenseLineId,
    this.sourceReceiptId,
    this.sourceStockId,
    this.initialCost,
  });
  final String lineId, name, description, quantity, price, cost, unit;
  final WorkLineItemType type;
  final JobMaterialBillingTreatment billingTreatment;
  final WorkLineItem? original;
  final String? sourceExpenseId,
      sourceExpenseLineId,
      sourceReceiptId,
      sourceStockId,
      initialCost;

  Map<String, Object?> toPayload() => {
    'lineId': lineId,
    'original': original == null ? null : encodeWorkLineItem(original!),
    'name': name,
    'description': description,
    'quantity': quantity,
    'price': price,
    'cost': cost,
    'type': type.name,
    'unit': unit,
    'billingTreatment': billingTreatment.name,
    'sourceExpenseId': sourceExpenseId,
    'sourceExpenseLineId': sourceExpenseLineId,
    'sourceReceiptId': sourceReceiptId,
    'sourceStockId': sourceStockId,
    'initialCost': initialCost,
  };
  factory WorkLineItemDraftInput.fromPayload(Map<String, Object?> payload) =>
      WorkLineItemDraftInput(
        lineId: payload['lineId'] as String,
        original: payload['original'] == null
            ? null
            : decodeWorkLineItem(
                (payload['original'] as Map).cast<String, Object?>(),
              ),
        name: payload['name'] as String,
        description: payload['description'] as String,
        quantity: payload['quantity'] as String,
        price: payload['price'] as String,
        cost: payload['cost'] as String,
        type: WorkLineItemType.values.byName(payload['type'] as String),
        unit: payload['unit'] as String,
        billingTreatment: JobMaterialBillingTreatment.values.byName(
          payload['billingTreatment'] as String,
        ),
        sourceExpenseId: payload['sourceExpenseId'] as String?,
        sourceExpenseLineId: payload['sourceExpenseLineId'] as String?,
        sourceReceiptId: payload['sourceReceiptId'] as String?,
        sourceStockId: payload['sourceStockId'] as String?,
        initialCost: payload['initialCost'] as String?,
      );

  WorkLineItem confirmedItem({
    required bool canSetCustomerPrice,
    required bool canViewInternalCost,
    required bool jobMaterialMode,
  }) {
    if (name.trim().isEmpty) throw StateError('Enter an item name.');
    final parsedQuantity = double.tryParse(quantity);
    final parsedPrice = price.trim().isEmpty ? 0.0 : double.tryParse(price);
    final parsedCost = cost.trim().isEmpty ? null : double.tryParse(cost);
    final chargesCustomer =
        !jobMaterialMode ||
        billingTreatment != JobMaterialBillingTreatment.nonBillable;
    if (parsedQuantity == null ||
        !parsedQuantity.isFinite ||
        parsedQuantity <= 0 ||
        (canSetCustomerPrice &&
            chargesCustomer &&
            (parsedPrice == null ||
                !parsedPrice.isFinite ||
                parsedPrice < 0)) ||
        (canViewInternalCost &&
            cost.trim().isNotEmpty &&
            (parsedCost == null || !parsedCost.isFinite || parsedCost < 0))) {
      throw StateError(
        'Enter a positive quantity and valid non-negative prices.',
      );
    }
    return WorkLineItem(
      id: lineId,
      type: type,
      name: name.trim(),
      description: description.trim(),
      quantity: parsedQuantity,
      unit: unit,
      customerPrice: canSetCustomerPrice
          ? (chargesCustomer ? parsedPrice ?? 0 : 0)
          : original?.customerPrice ?? 0,
      internalUnitCost: canViewInternalCost
          ? parsedCost
          : original?.internalUnitCost ?? double.tryParse(initialCost ?? ''),
      sourceExpenseId: original?.sourceExpenseId ?? sourceExpenseId,
      sourceExpenseLineId: original?.sourceExpenseLineId ?? sourceExpenseLineId,
      sourceReceiptId: original?.sourceReceiptId ?? sourceReceiptId,
      sourceStockId: original?.sourceStockId ?? sourceStockId,
      isJobAddition: original?.isJobAddition ?? false,
      jobMaterialBillingTreatment: jobMaterialMode
          ? billingTreatment
          : original?.jobMaterialBillingTreatment,
    );
  }
}
