import 'work_service_price.dart';
import 'estimate_draft_controller.dart';
import 'models/work_models.dart';

/// Only a dedicated service-price line can be edited by the simple price field.
/// A detailed breakdown is never collapsed or replaced by switching styles.
bool canUseEstimateServicePrice(String estimateId, List<WorkLineItem> items) =>
    canUseWorkServicePrice(estimateId, items);

List<WorkLineItem> estimatePricedItems(EstimateDraftInput input) {
  if (input.servicePrice.trim().isEmpty) {
    if (input.items.isNotEmpty &&
        canUseEstimateServicePrice(input.estimateId, input.items)) {
      throw const FormatException('Enter the price for the work.');
    }
    return input.items;
  }
  return workServicePricedItems(
    recordId: input.estimateId,
    title: input.title,
    description: input.scope,
    priceText: input.servicePrice,
    items: input.items,
  );
}
