part of '../../work_supply_receipt_parser.dart';

WorkSupplyItem? _directUnscopedHvacEvidenceMatch(String text) {
  final wantsAcrCopperTubing =
      RegExp(r'\bacr\b').hasMatch(text) &&
      RegExp(r'\b(copper|cop|cu)\b').hasMatch(text) &&
      RegExp(r'\b(tubing|tube|coil)\b').hasMatch(text);
  if (wantsAcrCopperTubing) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(const [
      'acr',
      'copper',
      'tubing',
    ])) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('acr copper tubing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsCondensateCoupling =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cond|condensate)\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler|coup|acople)\b').hasMatch(text);
  if (wantsCondensateCoupling) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('condensate pvc coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsCondensatePump = RegExp(
    r'\b(little\s+pump|condensate\s+pump|cond\s+pump|bomba\s+condensado)\b',
  ).hasMatch(text);
  if (!wantsCondensatePump) return null;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'HVAC' && name.contains('condensate pump')) return item;
  }
  return null;
}
