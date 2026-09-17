import 'dart:convert';
import 'dart:io';
import '../../lib/src/screens/inventory/catalog/materials_trade_manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import '../inventory/legacy_reference/data/work_supply_catalog.dart';
import '../inventory/legacy_reference/data/work_supply_models.dart';
import '../inventory/legacy_reference/data/work_supply_catalog_pack_payload.dart';
import '../inventory/browse_batch_sqlite.dart';

/// A bounded real-source UI review slice, not acceptance of the whole catalog.
/// Reads the captured reference only; never executes inside protected 5.7.
void main() {
  final type = plumbingFittingsCopperSystem.itemTypes.singleWhere(
    (type) => type.name == '90 Elbows',
  );
  if (type.items.length != 8) {
    throw StateError(
      'Source family changed; review before replacing this batch',
    );
  }
  final items = <Map<String, Object?>>[];
  for (var index = 0; index < type.items.length; index++) {
    final raw = type.items[index];
    final sourceId = 'MI-${(index + 1).toString().padLeft(3, '0')}';
    final item = WorkSupplyItem(
      id: sourceId,
      name: raw.name,
      unit: raw.unit,
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'Copper',
      itemType: type.name,
      variant: raw.variant,
      aliases: raw.aliases,
      marketScopes: raw.marketScopes,
      packTier: raw.packTier,
      parserPriority: raw.parserPriority,
      intelligence: raw.intelligence,
    );
    final payload = buildWorkSupplyCatalogPackItemPayload(item).toMap();
    items.add({
      'id': 'Plumbing::$sourceId',
      'sourceId': sourceId,
      'name': raw.name,
      'labelKey': 'copper_solder_90',
      'unit': raw.unit,
      'variant': raw.variant,
      'aliases': raw.aliases,
      'sourceAliases': raw.aliases,
      'path': ['Plumbing', 'Fittings', 'Copper', type.name],
      'sourcePayload': payload,
      'sourcePayloadSha256': sha256
          .convert(utf8.encode(jsonEncode(payload)))
          .toString(),
      'reviewStatus': 'source-preserved UI slice; not full semantic acceptance',
    });
  }
  final batch = {
    'batch': 'materials-copper-90-review-001',
    'status':
        'UI review slice; wider fittings and independent semantic review pending',
    'trades': materialsTradeNames,
    'items': items,
  };
  final report = File(
    'docs/inventory_migration/materials_copper_review_001.json',
  );
  report.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(batch));
  final staging = File('assets/inventory/materials_staging.sqlite');
  if (staging.existsSync())
    throw StateError('Existing staging file requires inspection');
  final db = sqlite3.open(staging.path);
  try {
    writeBrowseBatch(db, batch);
    if (db.select('PRAGMA integrity_check').single.values.single != 'ok') {
      throw StateError('Catalog integrity failed');
    }
    for (final expected in items) {
      final actual = jsonDecode(
        db.select('SELECT payload FROM items WHERE id = ?', [
              expected['id'],
            ]).single['payload']
            as String,
      );
      if (jsonEncode(actual) != jsonEncode(expected)) {
        throw StateError('Item changed in SQLite: ${expected['id']}');
      }
    }
  } finally {
    db.close();
  }
  staging.renameSync('assets/inventory/browse_batch.sqlite');
  stdout.writeln(
    'Eight source records preserved for Copper 90 elbow UI review.',
  );
}
