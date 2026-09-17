part of 'work_supply_receipt_parser.dart';

WorkSupplyItem? _directElectricalServiceRepairMatch(
  String text, {
  String? tradeScope,
}) {
  if (!_isElectricalTradeScope(tradeScope)) return null;
  final receiptSaysWireNut = RegExp(
    r'\b(wire\s*nut|wirenut|tuerca\s+cable|conector\s+cable)\b',
  ).hasMatch(text);
  if (receiptSaysWireNut) {
    final style = RegExp(r'\bwinged\b').hasMatch(text) ? 'winged' : null;
    final colorToken = RegExp(
      r'\b(yellow|red|blue|tan|orange|gray|amarillo|rojo|azul|gris|naranja)\b',
    ).firstMatch(text)?.group(1);
    final color = switch (colorToken) {
      'amarillo' => 'yellow',
      'rojo' => 'red',
      'azul' => 'blue',
      'gris' => 'gray',
      'naranja' => 'orange',
      _ => colorToken,
    };
    final pack = RegExp(
      r'\b(25|50|100|250)\s*(?:pk|pack)\b',
    ).firstMatch(text)?.group(1);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Electrical' || !name.contains('wire connector')) {
        continue;
      }
      if (style != null && !name.contains(style)) continue;
      if (color != null && !name.contains(color)) continue;
      if (pack != null && !name.contains('$pack pack')) continue;
      return item;
    }
  }
  final wantedName = switch (text) {
    _ when receiptSaysWireNut => 'wire connector',
    final value when RegExp(r'\bground\s+screw\b').hasMatch(value) =>
      'ground screw',
    final value
        when RegExp(r'\b(romex|nm|nm-b)\b').hasMatch(value) &&
            RegExp(r'\b(connector|conn|clamp)\b').hasMatch(value) =>
      'romex connector',
    final value when RegExp(r'\binsulated\s+bushing\b').hasMatch(value) =>
      'insulated bushing',
    final value when RegExp(r'\b(conduit\s+)?locknut\b').hasMatch(value) =>
      'conduit locknut',
    final value when RegExp(r'\blever\s+connector\b').hasMatch(value) =>
      'lever connector',
    final value
        when RegExp(r'\bconector\s+(de\s+)?palanca\b').hasMatch(value) =>
      'lever connector',
    final value
        when RegExp(r'\bpush[\s-]?in\s+wire\s+connector\b').hasMatch(value) =>
      'push-in wire connector',
    final value when RegExp(r'\bbutt\s+splice\b').hasMatch(value) =>
      'butt splice connector',
    final value
        when RegExp(
          r'\b(empalme\s+tope|conector\s+empalme)\b',
        ).hasMatch(value) =>
      'butt splice connector',
    final value when RegExp(r'\bclosed\s+end\s+splice\b').hasMatch(value) =>
      'closed end splice connector',
    final value
        when RegExp(
          r'\bcompact\s+splic(e|ing)\s+connector\b',
        ).hasMatch(value) =>
      'compact splicing connector',
    final value when RegExp(r'\banti[\s-]?short\b').hasMatch(value) =>
      'anti short bushing',
    final value
        when RegExp(
          r'\b(anti\s+corto|bushing\s+anti\s+corto)\b',
        ).hasMatch(value) =>
      'anti short bushing',
    final value when RegExp(r'\bground\s+pigtail\b').hasMatch(value) =>
      'ground pigtail',
    final value when RegExp(r'\bgfci\s+tester\b').hasMatch(value) =>
      'gfci tester',
    final value when RegExp(r'\bvoltage\s+detector\b').hasMatch(value) =>
      'voltage detector',
    final value when RegExp(r'\bwire\s+marker\b').hasMatch(value) =>
      'wire marker',
    final value when RegExp(r'\bcircuit\s+directory\b').hasMatch(value) =>
      'circuit directory',
    final value when RegExp(r'\bfuse\b').hasMatch(value) => 'fuse',
    final value when RegExp(r'\b(surge|spd)\b').hasMatch(value) =>
      'surge protector',
    final value
        when RegExp(r'\b(panel|load\s*center)\b').hasMatch(value) &&
            RegExp(r'\b(ground|neutral)\s+bar\b').hasMatch(value) =>
      'bar kit',
    final value when RegExp(r'\bsplit\s+bolt\b').hasMatch(value) =>
      'split bolt',
    final value when RegExp(r'\bporcelain\s+lampholder\b').hasMatch(value) =>
      'porcelain lampholder',
    final value
        when RegExp(
          r'\b(keyless|pull\s+chain|weatherproof)\s+lampholder\b|'
          r'\b(porcln|porcelain|keyless|pull\s+chain|weatherproof)\s+'
          r'(lamp\s*hldr|lamphldr)\b',
        ).hasMatch(value) =>
      'lampholder',
    final value when RegExp(r'\b(photo\s*eye|photocell)\b').hasMatch(value) =>
      'photocell control',
    _ => null,
  };
  if (wantedName == null) return null;
  final size =
      {
        'bar kit',
        'fuse',
        'ground screw',
        'photo',
        'split bolt',
        'surge protector',
      }.contains(wantedName)
      ? null
      : _nominalReceiptSize(text);
  WorkSupplyItem? fallback;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Electrical') continue;
    if (wantedName == 'photocell control') {
      final searchable = item.searchableText.toLowerCase();
      if (!name.contains('photocell') && !name.contains('photo eye')) continue;
      if (!searchable.contains('control')) continue;
    } else if (!name.contains(wantedName)) {
      continue;
    }
    if (size != null && !_nameMatchesReceiptSize(name, size)) continue;
    if (name.contains('electrical service repair part') ||
        item.category.toLowerCase() == 'connectors and consumables') {
      return item;
    }
    fallback ??= item;
  }
  return fallback;
}

WorkSupplyItem? _directElectricalLowVoltageCableMatch(
  String text, {
  String? tradeScope,
}) {
  if (!_isElectricalTradeScope(tradeScope) ||
      !RegExp(
        r'\b(low voltage|low volt|lv|stat wire|thermostat wire|control wire|doorbell wire)\b',
      ).hasMatch(text) ||
      RegExp(r'\b(bracket|mud ring|box extender)\b').hasMatch(text)) {
    return null;
  }
  final size = RegExp(
    r'\b(18/2|18/4|18/5|18/7|16/2|14/2)\b',
  ).firstMatch(text)?.group(1);
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' &&
        name.contains('low voltage cable') &&
        (size == null || name.startsWith('$size x '))) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directElectricalWireCableMatch(
  String text, {
  String? tradeScope,
}) {
  if (!_isElectricalTradeScope(tradeScope) ||
      RegExp(r'\b(conn|connector|staple|clamp)\b').hasMatch(text)) {
    return null;
  }
  final wantedName = switch (text) {
    final value
        when RegExp(
          r'\b(uf-b|ufb|uf cable|underground feeder|direct burial)\b',
        ).hasMatch(value) =>
      'uf-b cable',
    final value
        when RegExp(
          r'\b(romex|nm-b|nmb|nm cable|house wire)\b',
        ).hasMatch(value) =>
      'nm-b cable',
    final value when RegExp(r'\b(thhn|thwn|building wire)\b').hasMatch(value) =>
      'thhn copper wire',
    _ => null,
  };
  if (wantedName == null) return null;
  final cableSize = RegExp(
    r'\b(14[/-]2|14[/-]3|12[/-]2|12[/-]3|10[/-]2)\b',
  ).firstMatch(text)?.group(1)?.replaceAll('-', '/');
  final wireGauge = RegExp(
    r'\b(14|12|10)\s*(awg|ga)\b',
  ).firstMatch(text)?.group(1);
  final wireColor = RegExp(
    r'\b(black|red|blue|white|green|yellow|orange|brown|gray|purple)\b',
  ).firstMatch(text)?.group(1);
  WorkSupplyItem? fallback;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Electrical' || !name.contains(wantedName)) continue;
    if (cableSize != null && !name.contains(cableSize)) continue;
    if (wireGauge != null && !name.contains('$wireGauge awg')) continue;
    if (wireColor != null && !name.contains(wireColor)) continue;
    if (item.packTier == WorkSupplyPackTier.core) return item;
    fallback ??= item;
  }
  return fallback;
}

WorkSupplyItem? _directElectricalDeviceMatch(
  String text, {
  String? tradeScope,
}) {
  if (!_isElectricalTradeScope(tradeScope)) return null;
  final wantedName = switch (text) {
    final value
        when RegExp(r'\b(gfci|gfi|ground fault)\b').hasMatch(value) &&
            RegExp(r'\b(recpt|recept|receptacle|outlet)\b').hasMatch(value) =>
      'gfci outlet',
    final value
        when RegExp(r'\bduplex\b').hasMatch(value) &&
            RegExp(r'\b(recpt|recept|receptacle|outlet)\b').hasMatch(value) =>
      'duplex receptacle',
    final value
        when RegExp(r'\b(dimmer|dimr)\b').hasMatch(value) &&
            RegExp(r'\b(switch|sw)\b').hasMatch(value) =>
      'dimmer switch',
    final value
        when RegExp(r'\b(3\s*way|3-way|three way)\b').hasMatch(value) &&
            RegExp(r'\b(switch|sw)\b').hasMatch(value) =>
      '3-way toggle switch',
    final value
        when RegExp(r'\b(single pole|1p)\b').hasMatch(value) &&
            RegExp(r'\b(switch|sw)\b').hasMatch(value) =>
      'single pole toggle switch',
    _ => null,
  };
  if (wantedName == null) return null;
  final amperage = RegExp(
    r'\b(15|20)\s*(?:a|amp)\b',
  ).firstMatch(text)?.group(1);
  final packCount = RegExp(
    r'\b(2|5|10)\s*(?:pk|pack)\b',
  ).firstMatch(text)?.group(1);
  if (packCount != null) {
    final bulkDeviceStyle = switch (wantedName) {
      'gfci outlet' => 'gfci receptacle',
      'duplex receptacle' => 'duplex receptacle',
      'dimmer switch' => 'dimmer',
      '3-way toggle switch' => '3-way switch',
      'single pole toggle switch' => 'single-pole switch',
      _ => null,
    };
    if (bulkDeviceStyle != null) {
      final color = RegExp(
        r'\b(white|ivory|black|gray|brown|almond)\b',
      ).firstMatch(text)?.group(1);
      for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(const [
        'wiring',
        'device',
      ])) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Electrical' &&
            name.contains('wiring device') &&
            name.contains(bulkDeviceStyle) &&
            name.contains('$packCount pack') &&
            (amperage == null || name.contains('$amperage amp')) &&
            (color == null || name.contains(color))) {
          return item;
        }
      }
    }
  }
  final requiredNameTokens = switch (wantedName) {
    'gfci outlet' => const ['gfci'],
    'duplex receptacle' => const ['duplex', 'receptacle'],
    'dimmer switch' => const ['dimmer'],
    '3-way toggle switch' => const ['3-way'],
    'single pole toggle switch' => const ['single-pole'],
    _ => [wantedName],
  };
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
    requiredNameTokens,
  )) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' &&
        (name.contains(wantedName) ||
            (wantedName == 'gfci outlet' &&
                name.contains('gfci receptacle'))) &&
        (amperage == null || name.contains('$amperage amp'))) {
      return item;
    }
  }
  return null;
}

bool _isElectricalTradeScope(String? tradeScope) =>
    tradeScope == null ||
    tradeScope.trim().isEmpty ||
    tradeScope.trim().toLowerCase() == 'electrical';
