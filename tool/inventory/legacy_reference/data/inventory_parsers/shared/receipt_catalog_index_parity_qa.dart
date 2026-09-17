part of '../../work_supply_receipt_parser.dart';

/// QA-only evidence that indexed candidate narrowing preserves the legacy
/// full-scan candidate set and deterministic catalog order.
({
  List<String> indexedIds,
  List<String> fullScanIds,
  int indexedMicroseconds,
  int fullScanMicroseconds,
})
receiptCatalogIndexParityForQa({
  required List<WorkSupplyItem> catalogItems,
  required Iterable<String> requiredNameParts,
  String? tradeScope,
}) {
  return _runWithReceiptCatalogItems(
    catalogItems,
    tradeScope: tradeScope,
    action: () {
      final requiredTokens = {
        for (final part in requiredNameParts)
          ..._receiptCandidateTokens(_normalize(part)),
      };
      final indexedTimer = Stopwatch()..start();
      final indexedIds = [
        for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
          requiredNameParts,
        ))
          item.id,
      ];
      indexedTimer.stop();
      final fullScanTimer = Stopwatch()..start();
      if (requiredTokens.isEmpty ||
          requiredTokens.any(
            (token) => !_receiptCatalogTokenIndex.containsKey(token),
          )) {
        fullScanTimer.stop();
        return (
          indexedIds: indexedIds,
          fullScanIds: [
            for (final item in _activeWorkSupplyCatalogItems) item.id,
          ],
          indexedMicroseconds: indexedTimer.elapsedMicroseconds,
          fullScanMicroseconds: fullScanTimer.elapsedMicroseconds,
        );
      }
      final fullScanIds = <String>[];
      for (final item in _activeWorkSupplyCatalogItems) {
        final itemTokens = _receiptCandidateTokens(
          _normalize('${item.searchableText} ${item.aliases.join(' ')}'),
        ).toSet();
        if (requiredTokens.every(itemTokens.contains)) fullScanIds.add(item.id);
      }
      fullScanTimer.stop();
      return (
        indexedIds: indexedIds,
        fullScanIds: fullScanIds,
        indexedMicroseconds: indexedTimer.elapsedMicroseconds,
        fullScanMicroseconds: fullScanTimer.elapsedMicroseconds,
      );
    },
  );
}
