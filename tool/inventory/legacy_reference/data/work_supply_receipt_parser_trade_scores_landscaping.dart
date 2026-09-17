part of 'work_supply_receipt_parser.dart';

int _landscapingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'landscaping') return score;
  if (RegExp(
    r'\b(landscape|landscaping|irrigation|drip|sprinkler|corrugated drain|catch basin|wattle|paver base|mulch|topsoil|fabric|weed barrier|grass seed|'
    r'fertilizer|sod|pine straw|weed killer|herbicide|pump sprayer|trimmer line|mower blade|path light|paver sealer|geogrid|tree tie|plant stake|root stimulator|two cycle oil|mower spark plug)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
        r'\b(irrigation pipe|poly pipe|funny pipe|drip tubing|drip line|drip emitter)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation')) {
    score += 28;
  }
  if (RegExp(r'\bblu-?lock\b').hasMatch(text)) {
    if (itemName.contains('blu-lock')) {
      score += 58;
    } else if (itemType.contains('irrigation')) {
      score -= 16;
    }
  }
  for (final fitting in ['coupling', 'elbow', 'tee', 'adapter']) {
    if (RegExp('\\b$fitting\\b').hasMatch(text) && itemName.contains(fitting)) {
      score += 24;
    }
  }
  if (RegExp(
        r'\b(pressure compensating drip emitter|pc drip emitter|drip manifold|drip pressure regulator|drip filter|drip flush valve|valve box lid|valve box extension|valve diaphragm|irrigation valve solenoid)\b',
      ).hasMatch(text) &&
      itemType.contains('drip emitters')) {
    score += 42;
  }
  if (RegExp(r'\b(pressure compensating|pc)\b').hasMatch(text) &&
      text.contains('emitter')) {
    if (itemName.contains('pressure compensating')) {
      score += 62;
    } else if (itemName.contains('drip emitter')) {
      score -= 10;
    }
  }
  if (text.contains('funny pipe') &&
      (itemName.contains('funny pipe') || variant.contains('funny pipe'))) {
    score += 36;
  }
  if (RegExp(
        r'\b(sprinkler head|rotor|pop-up|irrigation valve|timer|solenoid)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation control')) {
    score += 26;
  }
  if (RegExp(
        r'\b(sprinkler wire|irrigation wire|waterproof wire connector|grease cap|valve repair|diaphragm)\b',
      ).hasMatch(text) &&
      itemType.contains('irrigation repair')) {
    score += 28;
  }
  if (text.contains('sprinkler wire')) {
    if (itemName.contains('sprinkler wire')) {
      score += 82;
    } else if (itemName.contains('landscape wire')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(sprinkler nozzle|spray nozzle|cut off riser|cut-off riser|riser extension|rotor tool|sprinkler head cap|filter screen)\b',
      ).hasMatch(text) &&
      itemType.contains('sprinkler nozzles')) {
    score += 34;
  }
  if (RegExp(r'\b(irrigation|sprinkler)\b').hasMatch(text) &&
      RegExp(
        r'\b(grease cap|waterproof connector|waterproof wire connector)\b',
      ).hasMatch(text) &&
      (itemName.contains('grease cap') ||
          itemName.contains('waterproof wire connector'))) {
    score += 80;
  }
  if (RegExp(
        r'\b(corrugated drain|french drain|ez drain|catch basin|drain box|drain grate|pop-up drainage)\b',
      ).hasMatch(text) &&
      category == 'drainage and erosion') {
    score += 28;
  }
  if (RegExp(
        r'\b(ez drain|catch basin|drain grate|channel drain)\b',
      ).hasMatch(text) &&
      itemType.contains('drainage')) {
    score += 34;
  }
  if (RegExp(r'\bcatch basin\b').hasMatch(text)) {
    if (RegExp(
      r'\b(catch basin grate|catch basin riser|catch basin outlet)\b',
    ).hasMatch(text)) {
      if (itemName.contains('catch basin grate') ||
          itemName.contains('catch basin riser') ||
          itemName.contains('catch basin outlet')) {
        score += 58;
      }
    } else if (itemName.contains('catch basin') &&
        !itemName.contains('atrium grate')) {
      score += 72;
    } else if (itemName.contains('atrium grate')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(channel drain grate|channel drain end cap|channel drain outlet|channel drain coupler|catch basin grate|catch basin riser|atrium grate|pop up emitter|pop-up emitter|downspout adapter|french drain sock)\b',
      ).hasMatch(text) &&
      itemType.contains('drainage channel')) {
    score += 42;
  }
  if (RegExp(r'\bchannel drain grate\b').hasMatch(text)) {
    if (itemName.contains('channel drain grate')) {
      score += 72;
    } else if (itemName.contains('catch basin grate')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(atrium grate|yard drain grate)\b').hasMatch(text)) {
    if (itemName.contains('atrium grate')) score += 58;
  }
  if (text.contains('ez drain') &&
      (itemName.contains('ez drain') || variant.contains('ez drain'))) {
    score += 80;
  }
  if (RegExp(
        r'\b(straw wattle|erosion wattle|silt fence|erosion blanket)\b',
      ).hasMatch(text) &&
      itemType.contains('erosion')) {
    score += 26;
  }
  if (RegExp(
        r'\b(paver base|leveling sand|polymeric sand|landscape edging|plastic landscape edging|steel landscape edging|aluminum landscape edging)\b',
      ).hasMatch(text) &&
      itemType.contains('hardscape')) {
    score += 26;
  }
  if (text.contains('paver base')) {
    if (itemName.contains('paver base')) {
      score += 72;
    } else if (itemName.contains('polymeric sand')) {
      score -= 24;
    }
  }
  if (text.contains('landscape edging') &&
      variant.contains('landscape edging')) {
    score += 54;
  }
  if (RegExp(
        r'\b(no dig edging|no-dig edging|edging spike|paver edge spike|artificial turf|putting green turf|turf seam tape|artificial turf adhesive|retaining wall cap|retaining wall pin|paver sand base panel)\b',
      ).hasMatch(text) &&
      itemType.contains('edging turf')) {
    score += 42;
  }
  if (RegExp(r'\bretaining wall cap\b').hasMatch(text)) {
    if (itemName.contains('retaining wall cap')) {
      score += 76;
    } else if (itemName.contains('wall cap')) {
      score += 20;
    }
  }
  if (RegExp(r'\b(artificial turf|putting green turf)\b').hasMatch(text)) {
    if (itemName.contains('artificial turf') ||
        itemName.contains('putting green turf')) {
      score += 58;
    }
  }
  if (RegExp(
        r'\b(paver sealer|paver cleaner|geogrid|edge restraint|paver spacer|paver joint)\b',
      ).hasMatch(text) &&
      itemType.contains('hardscape adhesives')) {
    score += 34;
  }
  if (RegExp(r'\b(landscape block adhesive|block adhesive)\b').hasMatch(text) &&
      itemType.contains('hardscape adhesives')) {
    score -= 44;
  }
  if (RegExp(
        r'\b(paver stone|patio paver|patio stone|retaining wall|river rock|pea gravel)\b',
      ).hasMatch(text) &&
      category == 'hardscape') {
    score += 24;
  }
  if (RegExp(
        r'\b(mulch|topsoil|garden soil|compost|fertilizer|lime|soil conditioner)\b',
      ).hasMatch(text) &&
      itemType.contains('ground')) {
    score += 26;
  }
  if (RegExp(
        r'\b(grass seed|fescue|bermuda|ryegrass|weed and feed|grub control)\b',
      ).hasMatch(text) &&
      itemType.contains('lawn care')) {
    score += 28;
  }
  if (RegExp(
        r'\b(weed killer|herbicide|brush killer|pre-emergent|insect control|sod roll|sod patch|pine straw|wheat straw|pump sprayer|backpack sprayer)\b',
      ).hasMatch(text) &&
      itemType.contains('lawn and landscape treatment')) {
    score += 28;
  }
  if (text.contains('weed killer') &&
      (itemName.contains('weed killer') || variant.contains('weed killer'))) {
    score += 64;
  }
  if (RegExp(
        r'\b(tree tie|plant stake|plant support|root stimulator|tree watering bag|tree fertilizer spike|burlap|guying kit|bird netting|deer netting)\b',
      ).hasMatch(text) &&
      itemType.contains('planting and tree support')) {
    score += 34;
  }
  if (RegExp(
        r'\b(landscape fabric|weed barrier|fabric staple|tree stake)\b',
      ).hasMatch(text) &&
      itemType.contains('accessory')) {
    score += 24;
  }
  if (RegExp(
        r'\b(shovel|rake|tamper|post hole digger|trimmer line|mower blade|edger blade|yard waste bag|garden hose)\b',
      ).hasMatch(text) &&
      itemType.contains('landscape tool')) {
    score += 26;
  }
  if (RegExp(
        r'\b(trimmer line|weed eater string|mower blade|mulching blade|high lift blade|edger blade|two cycle oil|2 cycle oil|mower spark plug|primer bulb|trimmer head|brush cutter)\b',
      ).hasMatch(text) &&
      itemType.contains('power equipment consumables')) {
    score += 34;
  }
  if (RegExp(
        r'\b(landscape light|path light|spot light|well light|low voltage landscape wire|low voltage transformer|photocell)\b',
      ).hasMatch(text) &&
      itemType.contains('landscape lighting')) {
    score += 26;
  }
  if (RegExp(
        r'\b(direct burial landscape wire|smart landscape transformer|hardscape wall light|deck step light|waterproof landscape wire nut|'
        r'pierce point wire connector|landscape lighting wire connector|astronomical landscape timer|smart outdoor plug)\b',
      ).hasMatch(text) &&
      itemType.contains('lighting timer')) {
    score += 42;
  }
  if (text.contains('low voltage') &&
      text.contains('landscape') &&
      itemType.contains('lighting timer')) {
    score += 34;
  }
  if (RegExp(r'\b\d{2}/2\b').hasMatch(text) &&
      text.contains('landscape wire')) {
    if (itemName.contains('landscape wire')) {
      score += 72;
    } else if (itemName.contains('transformer')) {
      score -= 30;
    }
  }
  if (text.contains('low voltage landscape wire')) {
    if (itemName.contains('low voltage landscape wire')) {
      score += 54;
    } else if (itemName.contains('direct burial landscape wire')) {
      score -= 20;
    }
  }
  final landscapeWireLength = RegExp(r'\b(50|100|250)\s*ft\b').firstMatch(text);
  if (landscapeWireLength != null &&
      itemName.contains('${landscapeWireLength.group(1)} ft') &&
      itemName.contains('landscape wire')) {
    score += 34;
  }
  if (text.contains('weed barrier') &&
      (itemName.contains('weed barrier') || variant.contains('weed barrier'))) {
    score += 28;
  }
  if (text.contains('landscape fabric') &&
      (itemName.contains('landscape fabric') ||
          variant.contains('landscape fabric'))) {
    score += 28;
  }
  for (final term in [
    'spray nozzle',
    'cut-off riser',
    'paver sealer',
    'geogrid',
    'tree tie',
    'plant stake',
    'root stimulator',
    'tree watering bag',
    'two cycle',
    'mower spark plug',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (RegExp(r'\b(rebar|tapcon|cmu|mortar|concrete anchor)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

WorkSupplyItem? _directLandscapingDrainageReceiptMatch(
  String text, {
  String? tradeScope,
}) {
  final scopedTrade = tradeScope?.trim().toLowerCase();
  if (scopedTrade != null &&
      scopedTrade.isNotEmpty &&
      scopedTrade != 'landscaping') {
    return null;
  }
  if (text.contains('landscape lighting wire connector')) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (item.trade == 'Landscaping' &&
          item.name.toLowerCase().contains(
            'landscape lighting wire connector',
          )) {
        return item;
      }
    }
  }
  final strongDetailTokens = switch (text) {
    final value when value.contains('landscape lighting wire connector') =>
      const ['landscape', 'lighting', 'wire', 'connector'],
    final value when value.contains('artificial turf roll') => const [
      'artificial',
      'turf',
      'roll',
    ],
    final value when value.contains('landscape path light') => const [
      'landscape',
      'path',
      'light',
    ],
    final value when value.contains('low voltage transformer') => const [
      'low',
      'voltage',
      'transformer',
    ],
    final value when value.contains('mower spark plug') => const [
      'mower',
      'spark',
      'plug',
    ],
    final value when value.contains('tree tie') => const [
      'tree',
      'tie',
      'strap',
      'roll',
    ],
    final value when RegExp(r'\b(?:2|two)\s+cycle\s+oil\b').hasMatch(value) =>
      const ['cycle', 'oil'],
    _ => const <String>[],
  };
  if (strongDetailTokens.isNotEmpty) {
    for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
      strongDetailTokens,
    )) {
      if (item.trade != 'Landscaping') continue;
      final itemText = _normalize('${item.name} ${item.variant}');
      if (strongDetailTokens.every(itemText.contains)) return item;
    }
  }

  if (!RegExp(r'\bez\s+drain\b').hasMatch(text)) return null;

  final size = _nominalReceiptSize(text);
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(const [
    'ez',
    'drain',
  ])) {
    if (item.trade != 'Landscaping') continue;
    final itemText = '${item.name} ${item.variant}'.toLowerCase();
    if (!itemText.contains('ez drain')) continue;
    if (size == null ||
        _nameMatchesReceiptSize(item.name.toLowerCase(), size) ||
        _nameMatchesReceiptSize(item.variant.toLowerCase(), size)) {
      return item;
    }
  }
  return null;
}
