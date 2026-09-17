part of 'work_supply_catalog.dart';

String _resolveElectricalMaterial(WorkSupplyItem item, String text) {
  final source =
      '${item.category} ${item.system} ${item.itemType} '
              '${item.variant} ${item.name} ${item.aliases.join(' ')}'
          .toLowerCase();
  for (final entry in _electricalMaterialSignals.entries) {
    if (source.contains(entry.key) || text.contains(entry.key)) {
      return entry.value;
    }
  }
  return _firstMatched(text, _materialSignals);
}

String _resolveElectricalSize(WorkSupplyItem item, String text) {
  final source = '${item.variant} ${item.name}'.toLowerCase();
  final cable = RegExp(
    r'\b(?:14|12|10|8|6|4|2|1|1/0|2/0)/(?:2|3|4)\b',
  ).firstMatch(source);
  if (cable != null) return cable.group(0)!.trim();
  final gauge = RegExp(
    r'\b(?:18|16|14|12|10|8|6|4|2|1|1/0|2/0)\s*awg\b',
  ).firstMatch(source);
  if (gauge != null) return gauge.group(0)!.trim();
  final amps = RegExp(
    r'\b(?:15|20|30|40|50|60|100|125|150|200)\s*amp\b',
  ).firstMatch(source);
  if (amps != null) return amps.group(0)!.trim();
  final gang = RegExp(r'\b(?:1|2|3|4)\s*gang\b').firstMatch(source);
  if (gang != null) return gang.group(0)!.trim();
  final wordGang = RegExp(
    r'\b(?:single|double|triple|quad|one|two|three|four)\s*gang\b',
  ).firstMatch(source);
  if (wordGang != null) return wordGang.group(0)!.trim();
  final pole = RegExp(
    r'\b(?:single|double|tandem|dual|1|2)\s*[- ]?pole\b',
  ).firstMatch(source);
  if (pole != null) return pole.group(0)!.trim();
  final conduit = RegExp(
    r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2)\s*in\b',
  ).firstMatch(source);
  if (conduit != null) return conduit.group(0)!.trim();
  final feet = RegExp(
    r'\b(?:25|50|100|250|500|1000)\s*ft\b',
  ).firstMatch(source);
  if (feet != null) return feet.group(0)!.trim();
  return _extractSize(text);
}

String _resolveElectricalShape(WorkSupplyItem item, String text) {
  final source =
      '${item.category} ${item.system} ${item.itemType} '
              '${item.variant} ${item.name} ${item.aliases.join(' ')}'
          .toLowerCase();
  for (final entry in _electricalShapeSignals.entries) {
    if (source.contains(entry.key) || text.contains(entry.key)) {
      return entry.value;
    }
  }
  return _firstMatched(text, _shapeSignals);
}

bool _electricalNeedsManualReview(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isElectricalCoreMetadataTarget(item)) {
    return material.isEmpty || size.isEmpty || shape.isEmpty;
  }
  final text = item.searchableText;
  return shape.isEmpty ||
      (size.isEmpty && !_hasAny(text, _electricalNaturallyUnsizedSignals));
}

List<String> _electricalCoreAliasTermsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isElectricalCoreMetadataTarget(item)) return const [];
  final family = _electricalCoreFamilyTermsFor(item, shape);
  final compact = _electricalCompactFamilyTermsFor(item, shape);
  final spanish = _electricalSpanishCoreFamilyTermsFor(item, shape);
  final sizeToken = size.isEmpty ? item.variant : size;
  return _cleanList([
    '$sizeToken ${family.join(' ')}',
    '$sizeToken ${compact.join(' ')}',
    '$material ${family.join(' ')}',
    for (final term in family) '$sizeToken $term',
    for (final term in compact) '$sizeToken $term',
    for (final term in spanish) '$term $sizeToken',
  ]);
}

List<String> _electricalCoreReceiptPatternsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isElectricalCoreMetadataTarget(item)) return const [];
  final family = _electricalCoreFamilyTermsFor(item, shape);
  final compact = _electricalCompactFamilyTermsFor(item, shape);
  final spanish = _electricalSpanishCoreFamilyTermsFor(item, shape);
  final sizeToken = size.isEmpty ? item.variant : size;
  return _cleanList([
    item.name,
    '$sizeToken ${item.itemType}',
    '$material $sizeToken ${family.join(' ')}',
    for (final term in family) '$sizeToken $term',
    for (final term in compact) '$sizeToken $term',
    for (final term in compact) 'HD $sizeToken $term',
    for (final term in compact) 'LOWES $sizeToken $term',
    for (final term in compact) 'ACE $sizeToken $term',
    for (final term in compact) 'SUPPLY $sizeToken $term',
    for (final term in compact) 'ELEC $sizeToken $term',
    for (final term in spanish) '$sizeToken $term',
  ]);
}

List<String> _electricalCoreAttributeTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (!_isElectricalCoreMetadataTarget(item)) return const [];
  return _cleanList([
    'electrical-core',
    'residential-service',
    'service-truck',
    'hardware-store-stock',
    'box-store-stock',
    'user-review-required',
    'english-us',
    'spanish-us',
    item.path,
    material,
    size,
    shape,
    ..._electricalCoreFamilyTermsFor(item, shape),
    ..._electricalCompactFamilyTermsFor(item, shape),
    ..._electricalSpanishCoreFamilyTermsFor(item, shape),
  ]);
}

List<String> _electricalCoreHighImportanceTokensFor(
  WorkSupplyItem item,
  String material,
  String size,
  String connectionType,
  String shape,
) {
  if (!_isElectricalCoreMetadataTarget(item)) return const [];
  return _cleanList([
    'electrical-core',
    'residential-service',
    item.system,
    item.itemType,
    item.variant,
    material,
    size,
    connectionType,
    shape,
    ..._electricalCoreFamilyTermsFor(item, shape),
  ]);
}

List<String> _electricalCoreNegativeMatchTokensFor(
  WorkSupplyItem item,
  String material,
  String shape,
  String text,
) {
  if (!_isElectricalCoreMetadataTarget(item)) return const [];
  final itemText = '$text ${item.name} ${item.itemType}'.toLowerCase();
  return _cleanList([
    if (!itemText.contains('conduit')) 'plumbing pvc pipe',
    if (!itemText.contains('conduit')) 'hvac condensate pvc',
    if (!itemText.contains('filter')) 'hvac air filter',
    if (!itemText.contains('water')) 'water line copper',
    if (!itemText.contains('gas')) 'gas appliance connector',
    if (!itemText.contains('box')) 'storage box',
    if (!itemText.contains('box')) 'cabinet hardware',
    if (!itemText.contains('plate')) 'drywall plate',
    if (itemText.contains('plate')) 'cabinet plate',
    if (itemText.contains('plate')) 'drywall repair plate',
    if (!itemText.contains('cover')) 'paint cover',
    if (itemText.contains('cover')) 'paint cover',
    if (itemText.contains('cover')) 'furniture cover',
    if (!itemText.contains('strap')) 'pipe strap',
    if (material != 'copper') 'plumbing copper fitting',
    if (shape != 'switch') 'hvac float switch',
    if (shape != 'connector') 'plumbing hose connector',
    if (shape != 'tape') 'hvac foil tape',
    'plumbing valve',
    'water heater element',
    'irrigation wire',
  ]);
}

bool _isElectricalCoreMetadataTarget(WorkSupplyItem item) {
  return item.trade == 'Electrical' &&
      _resolveWorkSupplyPackTier(item) == WorkSupplyPackTier.core &&
      item.marketScopes.contains(WorkSupplyMarketScope.residential);
}

List<String> _electricalCoreFamilyTermsFor(WorkSupplyItem item, String shape) {
  final text =
      '${item.name} ${item.itemType} ${item.system} ${item.aliases.join(' ')}'
          .toLowerCase();
  if (text.contains('nm-b') || text.contains('romex')) {
    return const ['nm-b', 'romex', 'copper cable', 'building wire'];
  }
  if (text.contains('thhn') || text.contains('thwn')) {
    return const ['thhn', 'thwn', 'conduit wire', 'stranded wire'];
  }
  if (text.contains('gfci') || text.contains('gfi')) {
    return const ['gfci', 'gfi', 'ground fault', 'receptacle'];
  }
  if (text.contains('receptacle') || text.contains('outlet')) {
    return const ['receptacle', 'outlet', 'duplex outlet'];
  }
  if (text.contains('breaker')) {
    return const ['breaker', 'brkr', 'circuit breaker'];
  }
  if (text.contains('emt')) return const ['emt', 'emt conduit'];
  if (text.contains('conduit')) return const ['conduit', 'raceway'];
  if (text.contains('wire connector') || text.contains('wire nut')) {
    return const ['wire connector', 'wire nut', 'twist connector'];
  }
  if (text.contains('lever connector')) {
    return const ['lever connector', 'wago connector'];
  }
  if (text.contains('box')) return const ['electrical box', 'device box'];
  if (text.contains('plate') || text.contains('cover')) {
    return const ['wall plate', 'device cover', 'cover plate'];
  }
  if (text.contains('switch')) return const ['switch', 'wall switch'];
  if (text.contains('ground')) return const ['ground', 'bonding', 'grounding'];
  if (text.contains('tape')) return const ['electrical tape', 'vinyl tape'];
  if (text.contains('staple')) return const ['cable staple', 'wire staple'];
  if (text.contains('smoke') || text.contains('co alarm')) {
    return const ['smoke alarm', 'co alarm', 'detector'];
  }
  if (text.contains('doorbell')) return const ['doorbell', 'chime'];
  if (text.contains('disconnect')) return const ['disconnect', 'pullout'];
  if (text.contains('surge')) return const ['surge protector', 'surge'];
  return _cleanList([item.itemType, shape]);
}

List<String> _electricalCompactFamilyTermsFor(
  WorkSupplyItem item,
  String shape,
) {
  return _cleanList([
    for (final term in _electricalCoreFamilyTermsFor(item, shape))
      term
          .toUpperCase()
          .replaceAll(' CONNECTOR', ' CONN')
          .replaceAll(' RECEPTACLE', ' RECPT')
          .replaceAll(' CIRCUIT BREAKER', ' BRKR')
          .replaceAll(' ELECTRICAL ', ' ELEC ')
          .replaceAll(' GROUND FAULT', ' GFCI')
          .replaceAll(' DUPLEX OUTLET', ' DUP OUTLET'),
  ]);
}

List<String> _electricalSpanishCoreFamilyTermsFor(
  WorkSupplyItem item,
  String shape,
) {
  final text = '${item.name} ${item.itemType} ${item.system}'.toLowerCase();
  if (text.contains('wire') || text.contains('cable')) {
    return const ['cable electrico', 'alambre electrico'];
  }
  if (text.contains('receptacle') || text.contains('outlet')) {
    return const ['tomacorriente', 'enchufe'];
  }
  if (text.contains('gfci') || text.contains('gfi')) {
    return const ['tomacorriente gfci', 'proteccion falla tierra'];
  }
  if (text.contains('breaker')) return const ['interruptor termico'];
  if (text.contains('box')) return const ['caja electrica'];
  if (text.contains('plate') || text.contains('cover')) {
    return const [
      'placa electrica',
      'cubierta electrica',
      'placa',
      'placa decora',
      'placa decorador',
      'placa cubierta',
    ];
  }
  if (text.contains('conduit') || text.contains('emt')) {
    return const ['conducto electrico', 'tubo electrico'];
  }
  if (text.contains('connector')) return const ['conector electrico'];
  if (text.contains('switch')) return const ['apagador', 'interruptor'];
  if (text.contains('ground')) return const ['tierra fisica', 'puesta tierra'];
  if (text.contains('tape')) return const ['cinta electrica'];
  if (text.contains('alarm')) return const ['alarma humo', 'detector'];
  return const ['material electrico residencial'];
}

const _electricalMaterialSignals = {
  'copper': 'copper',
  'bare copper': 'bare copper',
  'aluminum': 'aluminum',
  'steel': 'steel',
  'zinc': 'zinc-plated steel',
  'pvc': 'PVC',
  'vinyl': 'vinyl',
  'nylon': 'nylon',
  'plastic': 'plastic',
  'thermoplastic': 'thermoplastic',
  'metal': 'metal',
  'molded case': 'molded case',
  'brass': 'brass',
};

const _electricalShapeSignals = {
  'receptacle': 'receptacle',
  'outlet': 'receptacle',
  'gfci': 'receptacle',
  'switch': 'switch',
  'dimmer': 'dimmer',
  'breaker': 'breaker',
  'box': 'box',
  'plate': 'plate',
  'cover': 'cover',
  'connector': 'connector',
  'coupling': 'coupling',
  'conduit': 'conduit',
  'wire': 'wire',
  'cable': 'cable',
  'ground rod': 'ground rod',
  'clamp': 'clamp',
  'tape': 'tape',
  'staple': 'staple',
  'bushing': 'bushing',
  'disconnect': 'disconnect',
  'alarm': 'alarm',
  'lampholder': 'lampholder',
};

const _electricalNaturallyUnsizedSignals = [
  'wire nut',
  'twist-on',
  'lever connector',
  'electrical tape',
  'anti short',
  'fixture strap',
  'smoke alarm',
  'co alarm',
  'doorbell chime',
  'surge protector',
];
