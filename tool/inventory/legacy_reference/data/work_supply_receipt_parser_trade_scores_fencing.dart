part of 'work_supply_receipt_parser.dart';

int _fencingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'fencing') return score;
  if (RegExp(
    r'\b(fence|fencing|picket|chain link|chainlink|vinyl fence|gate|barbed wire|welded wire|field fence|t-post|post concrete|ornamental fence|'
    r'aluminum fence|post cap|post repair|electric fence|fence charger|poly wire|privacy slat|fence screen|silt fence|post anchor|pool fence|pet fence)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(picket|privacy fence board|wood fence)\b').hasMatch(text) &&
      itemType.contains('wood fence')) {
    score += 26;
  }
  for (final style in ['dog ear picket', 'flat top picket', 'privacy board']) {
    if (text.contains(style) && itemName.contains(style)) {
      score += 64;
    } else if (text.contains(style) &&
        itemName.contains('wood fence') &&
        !itemName.contains(style)) {
      score -= 26;
    }
  }
  if (RegExp(r'\b(vinyl fence|privacy panel|vinyl rail)\b').hasMatch(text) &&
      itemType.contains('vinyl')) {
    score += 26;
  }
  if (RegExp(
        r'\b(chain link|chainlink|top rail|terminal post|line post)\b',
      ).hasMatch(text) &&
      itemType.contains('chain link')) {
    score += 26;
  }
  if (RegExp(
    r'\b(chain link|chainlink)\s+fabric\b|\bfabric\b',
  ).hasMatch(text)) {
    if (variant.contains('fabric') || itemName.contains('fabric')) {
      score += 42;
    } else if (variant.contains('post') ||
        itemName.contains('post') ||
        itemName.contains('rail')) {
      score -= 18;
    }
  }
  final chainGauge = RegExp(
    r'\b(9|11|11\.5)\s*(?:ga|gauge)\b',
  ).firstMatch(text);
  if (chainGauge != null && itemName.contains('chain link')) {
    final gauge = '${chainGauge.group(1)} gauge';
    if (itemName.contains(gauge)) {
      score += 46;
    } else if (itemName.contains('gauge')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(landscape fabric|weed barrier|landscaping fabric)\b',
  ).hasMatch(text)) {
    score -= 36;
  }
  if (RegExp(
        r'\b(welded wire|barbed wire|barb wire|field fence|farm fence)\b',
      ).hasMatch(text) &&
      itemType.contains('wire')) {
    score += 24;
  }
  if (RegExp(
        r'\b(t post|t-post|green t post|treated post|wood fence post)\b',
      ).hasMatch(text) &&
      itemType.contains('post')) {
    score += 24;
  }
  if (RegExp(r'\b(gate hinge|gate latch|gate kit|anti-sag)\b').hasMatch(text) &&
      itemType.contains('gate')) {
    score += 24;
  }
  if (text.contains('gate kit')) {
    if (itemName.contains('gate kit')) {
      score += 72;
    } else if (itemName.contains('walk gate') ||
        itemName.contains('farm gate')) {
      score -= 28;
    }
  }
  for (final width in ['4 ft', '5 ft', '6 ft', '8 ft', '10 ft', '12 ft']) {
    final compact = width.replaceAll(' ', '');
    if ((text.contains(width) || text.contains(compact)) &&
        itemName.contains(width)) {
      score += 32;
    }
  }
  if (RegExp(
        r'\b(walk gate|farm gate|driveway gate|gate opener|gate operator|gate wheel|drop rod)\b',
      ).hasMatch(text) &&
      itemType.contains('driveway')) {
    score += 28;
  }
  if (RegExp(
        r'\b(ornamental fence|aluminum fence|steel fence|fence finial)\b',
      ).hasMatch(text) &&
      itemType.contains('ornamental')) {
    score += 28;
  }
  if (RegExp(
        r'\b(post cap|post repair sleeve|mending plate|rail repair bracket|fence tie|hog ring|wire stretcher)\b',
      ).hasMatch(text) &&
      itemType.contains('repair')) {
    score += 28;
  }
  if (RegExp(
        r'\b(electric fence|fence charger|poly wire|poly tape|fence insulator|gate handle|voltage tester)\b',
      ).hasMatch(text) &&
      itemType.contains('electric')) {
    score += 30;
  }
  if (RegExp(
        r'\b(privacy slat|fence screen|privacy screen|windscreen|reed fence|bamboo fence|willow fence|screen clip)\b',
      ).hasMatch(text) &&
      itemType.contains('privacy')) {
    score += 30;
  }
  if (RegExp(r'\b(fence screen|privacy screen|windscreen)\b').hasMatch(text)) {
    if (variant.contains('fence privacy screen') ||
        itemName.contains('fence privacy screen')) {
      score += 36;
    } else if (variant.contains('privacy fence roll') ||
        itemName.contains('privacy fence roll')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(reed fence|bamboo fence|willow fence)\b').hasMatch(text)) {
    if (variant.contains('privacy fence roll') ||
        itemName.contains('privacy fence roll')) {
      score += 36;
    }
  }
  if (RegExp(
        r'\b(orange safety fence|temporary fence|silt fence|silt fence fabric|fence stake|temporary fence panel)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary')) {
    score += 30;
  }
  if (RegExp(
        r'\b(post anchor|post base anchor|post anchor spike|adjustable post base|rail bracket|fence flange)\b',
      ).hasMatch(text) &&
      itemType.contains('anchor')) {
    score += 30;
  }
  if (RegExp(
        r'\b(pool fence|pool gate latch|pool gate hinge|pet fence|child safety fence)\b',
      ).hasMatch(text) &&
      itemType.contains('pool')) {
    score += 30;
  }
  if (RegExp(
        r'\b(gate keypad|gate opener keypad|photo eye sensor|gate opener solar|control board|exit wand)\b',
      ).hasMatch(text) &&
      itemType.contains('gate opener')) {
    score += 30;
  }
  if (RegExp(
        r'\b(fence screw|fence staple|tension band|brace band)\b',
      ).hasMatch(text) &&
      itemType.contains('fastener')) {
    score += 22;
  }
  if (text.contains('tension band') &&
      (variant.contains('tension band') || itemName.contains('tension band'))) {
    score += 34;
  }
  if (text.contains('brace band') &&
      (variant.contains('brace band') || itemName.contains('brace band'))) {
    score += 34;
  }
  if (text.contains('tension band') && itemName.contains('brace band')) {
    score -= 18;
  }
  if (text.contains('brace band') && itemName.contains('tension band')) {
    score -= 18;
  }
  if (RegExp(
        r'\b(post concrete|fence post concrete|post foam)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete')) {
    score += 22;
  }
  if (RegExp(r'\b(insulation|batt|thinset|shingle)\b').hasMatch(text)) {
    score -= 16;
  }
  return score;
}
