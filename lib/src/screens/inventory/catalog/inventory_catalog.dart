import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'inventory_catalog_database.dart';
import 'materials_catalog_text.dart';
import 'materials_trade_manifest.dart';

class InventoryCatalogItem {
  InventoryCatalogItem(Map<String, dynamic> json)
    : id = json['id'] as String,
      sourceId = json['sourceId'] as String? ?? json['id'] as String,
      name = json['name'] as String,
      unit = json['unit'] as String,
      variant = json['variant'] as String? ?? '',
      labelKey = json['labelKey'] as String? ?? '',
      aliases = List<String>.unmodifiable(json['aliases'] as List? ?? const []),
      path = List<String>.unmodifiable(
        json['path'] as List? ??
            [
              for (final key in ['trade', 'category', 'system', 'type'])
                (json[key] as String?)?.trim().isNotEmpty == true
                    ? json[key] as String
                    : 'Other items',
            ],
      );
  final String id, sourceId, name, unit, variant, labelKey;
  final List<String> aliases;
  final List<String> path;
}

class InventoryCatalog {
  InventoryCatalog(this.items, {List<String> trades = const []}) {
    _branches[jsonEncode(<String>[])] = {...trades};
    for (final item in items) {
      for (var depth = 0; depth <= item.path.length; depth++) {
        final key = jsonEncode(item.path.take(depth).toList());
        _counts[key] = (_counts[key] ?? 0) + 1;
        if (depth < item.path.length) {
          (_branches[key] ??= {}).add(item.path[depth]);
        }
      }
    }
  }
  factory InventoryCatalog.fromJson(Map<String, dynamic> json) =>
      InventoryCatalog(
        List.unmodifiable([
          for (final row in json['items'] as List)
            InventoryCatalogItem(Map<String, dynamic>.from(row as Map)),
        ]),
        trades: List<String>.from(json['trades'] as List? ?? const []),
      );
  final List<InventoryCatalogItem> items;
  final _branches = <String, Set<String>>{};
  final _counts = <String, int>{};
  int count(List<String> path) => _counts[jsonEncode(path)] ?? 0;
  static Future<InventoryCatalog>? _cached;
  static Future<InventoryCatalog> load() => _cached ??= _load();
  static Future<InventoryCatalog> _load() async {
    try {
      final bytes = await rootBundle.load(
        'assets/inventory/browse_batch.sqlite',
      );
      return await compute(_decode, bytes.buffer.asUint8List());
    } catch (_) {
      _cached = null;
      rethrow;
    }
  }

  static InventoryCatalog _decode(Uint8List bytes) =>
      InventoryCatalog.fromJson(readInventoryCatalogDatabase(bytes));
  bool _inside(InventoryCatalogItem item, List<String> path) {
    for (var i = 0; i < path.length; i++) {
      if (i >= item.path.length || item.path[i] != path[i]) return false;
    }
    return true;
  }

  List<String> branches(List<String> path) {
    final names = (_branches[jsonEncode(path)] ?? {}).toList()..sort();
    if (path.isEmpty) {
      names.sort((a, b) {
        final ai = materialsBundledTrades.indexOf(a);
        final bi = materialsBundledTrades.indexOf(b);
        if (ai >= 0 || bi >= 0)
          return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
        return a.compareTo(b);
      });
    }
    return names;
  }

  List<InventoryCatalogItem> itemsAt(List<String> path) => search(
    '',
    path,
  ).where((item) => item.path.length == path.length).toList();

  List<InventoryCatalogItem> search(String query, List<String> path) {
    final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
    return items.where((item) {
      final usableAliases = item.aliases.where(
        (alias) =>
            alias != 'es-US' &&
            alias != 'spanish' &&
            !alias.startsWith('medida '),
      );
      final text =
          '${item.name} ${item.path.join(' ')} ${item.variant} ${usableAliases.join(' ')}'
              .toLowerCase();
      return _inside(item, path) && words.every(text.contains);
    }).toList()..sort((a, b) => compareMaterialsSizes(a.name, b.name));
  }
}
