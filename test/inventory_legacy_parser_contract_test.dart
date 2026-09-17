import 'package:flutter_test/flutter_test.dart';
import '../tool/inventory/legacy_reference/data/inventory_parser.dart';
import '../tool/inventory/legacy_reference/data/work_supply_models.dart';
import '../tool/inventory/legacy_reference/data/work_supply_trade_pack_runtime_loader.dart';

// Adapted from 5.7 test/inventory_parser_entry_point_test.dart. Executes only
// the isolated extraction, not the protected repository or the production app.
// These expectations establish a narrow contract, NOT receipt/OCR accuracy.
const coupling = WorkSupplyItem(
  id: 'fixture-pvc-coupling-075',
  name: '3/4 in PVC Schedule 40 Coupling',
  trade: 'Plumbing',
  category: 'Fittings',
  system: 'PVC Schedule 40',
  itemType: 'Couplings',
  variant: '3/4 in',
  unit: 'each',
  aliases: ['pvc coupling', 'coupler'],
);

WorkSupplyTradePackRuntimeLoadResult pack(List<WorkSupplyItem> items) =>
    WorkSupplyTradePackRuntimeLoadResult(
      status: WorkSupplyTradePackRuntimeLoadStatus.ready,
      items: items,
      issues: const [],
    );

void main() {
  test('legacy: loaded catalog matching stays inside supplied pack', () {
    const parser = InventoryParser(catalogItems: [coupling]);
    final match = parser.matchReceiptLine(
      '3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );
    expect(match?.item.id, coupling.id);
  });
  test(
    'legacy: explicitly empty catalog cannot fall back to compiled catalog',
    () {
      const parser = InventoryParser(catalogItems: []);
      expect(
        parser.matchReceiptLine(
          '3/4 PVC SCH40 COUPLING',
          tradeScope: 'Plumbing',
        ),
        isNull,
      );
    },
  );
  test('legacy: repeated loaded pack does not duplicate rows', () {
    final parser = InventoryParser.fromLoadedTradePacks([
      pack([coupling]),
      pack([coupling]),
    ]);
    expect(parser.catalogItems, hasLength(1));
    expect(
      parser
          .matchReceiptLine('3/4 PVC SCH40 COUPLING', tradeScope: 'Plumbing')
          ?.item
          .id,
      coupling.id,
    );
  });
  test('independent: conflicting identities must reject the whole merge', () {
    const changed = WorkSupplyItem(
      id: coupling.id,
      name: 'Different fitting',
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'ABS DWV',
      itemType: 'Tees',
      variant: '3 in',
      unit: 'each',
    );
    expect(
      () => InventoryParser.fromLoadedTradePacks([
        pack([coupling]),
        pack([changed]),
      ]),
      throwsArgumentError,
    );
  });
  test('independent: wrong trade scope cannot select a plumbing item', () {
    const parser = InventoryParser(catalogItems: [coupling]);
    expect(
      parser.matchReceiptLine(
        '3/4 PVC SCH40 COUPLING',
        tradeScope: 'Electrical',
      ),
      isNull,
    );
  });
}
