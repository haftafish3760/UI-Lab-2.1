import 'models/work_models.dart';

bool canUseWorkServicePrice(String recordId, List<WorkLineItem> items) =>
    items.isEmpty ||
    (items.length == 1 &&
        items.single.id == '$recordId-service-price' &&
        items.single.type == WorkLineItemType.service &&
        items.single.quantity == 1 &&
        items.single.workerCount == 1 &&
        items.single.internalUnitCost == null &&
        items.single.sourceExpenseId == null &&
        items.single.sourceExpenseLineId == null &&
        items.single.sourceStockId == null &&
        items.single.sourceReceiptId == null);

List<WorkLineItem> workServicePricedItems({
  required String recordId,
  required String title,
  required String description,
  required String priceText,
  required List<WorkLineItem> items,
}) {
  if (!canUseWorkServicePrice(recordId, items)) {
    throw const FormatException(
      'Review the existing items before changing the overall price.',
    );
  }
  final raw = priceText.trim();
  final price = double.tryParse(raw.replaceAll(',', '.'));
  if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(raw) ||
      price == null ||
      !price.isFinite) {
    throw const FormatException(
      'Enter a valid price with no more than two decimal places.',
    );
  }
  return [
    WorkLineItem(
      id: '$recordId-service-price',
      type: WorkLineItemType.service,
      name: title.trim().isEmpty ? 'Proposed work' : title.trim(),
      description: description.trim(),
      quantity: 1,
      unit: 'service',
      customerPrice: price,
    ),
  ];
}
