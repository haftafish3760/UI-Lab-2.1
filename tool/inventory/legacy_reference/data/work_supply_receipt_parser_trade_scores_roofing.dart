part of 'work_supply_receipt_parser.dart';

int _roofingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'roofing') return score;
  if (RegExp(
    r'\b(roof|roofing|shingle|felt|underlayment|ice shield|drip edge|flashing|ridge vent|pipe boot|gutter|downspout|metal roof|ridge cap|rake trim|'
    r'eave trim|closure strip|butyl tape|soffit|fascia|f channel|j channel|epdm|tpo|low slope|modified bitumen|roof jack|storm collar|b vent|gas vent|'
    r'roof repair tape|gutter guard|heat cable|roof anchor|roof bracket|chimney cap|spark arrestor)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(rafter vent baffle|soffit vent baffle|attic vent chute)\b',
  ).hasMatch(text)) {
    score -= 32;
  }
  if (RegExp(r'\b(shingle|shingles|shingle bundle)\b').hasMatch(text) &&
      itemType.contains('shingle')) {
    score += 28;
  }
  if (text.contains('starter') &&
      (variant.contains('starter') || itemName.contains('starter'))) {
    score += 38;
  }
  if (RegExp(
    r'\b(shingle repair|repair shingle|roof granule|roofing granule)\b',
  ).hasMatch(text)) {
    if (itemType.contains('shingle repair')) {
      score += 38;
    } else if (itemType.contains('shingle') ||
        itemName.contains('roof covering')) {
      score -= 10;
    }
  }
  if (text.contains('ridge') &&
      (variant.contains('ridge') || itemName.contains('ridge'))) {
    score += 30;
  }
  if ((text.contains('starter') || text.contains('ridge')) &&
      itemName.contains('shingle') &&
      !variant.contains('starter') &&
      !variant.contains('ridge')) {
    score -= 16;
  }
  if (RegExp(
        r'\b(felt|felt paper|synthetic underlayment|ice shield|ice barrier)\b',
      ).hasMatch(text) &&
      itemType.contains('underlayment')) {
    score += 26;
  }
  if (RegExp(r'\b(drip edge|edge metal|rake edge)\b').hasMatch(text) &&
      itemType.contains('drip')) {
    score += 24;
  }
  if (RegExp(
        r'\b(step flashing|valley flashing|roof flashing|flashing)\b',
      ).hasMatch(text) &&
      itemType.contains('flashing')) {
    score += 24;
  }
  if (RegExp(r'\b(pipe boot|roof boot|vent boot)\b').hasMatch(text) &&
      itemType.contains('pipe boot')) {
    score += 26;
  }
  for (final material in ['rubber', 'silicone', 'lead']) {
    if (text.contains(material) &&
        itemName.contains(material) &&
        itemName.contains('pipe boot')) {
      score += 62;
    } else if (text.contains(material) &&
        itemName.contains('pipe boot') &&
        !itemName.contains(material)) {
      score -= 28;
    }
  }
  if (RegExp(r'\b(ridge vent|box vent|roof vent)\b').hasMatch(text) &&
      itemType.contains('vent')) {
    score += 24;
  }
  if (RegExp(
        r'\b(gutter|downspout|hidden hanger|drop outlet)\b',
      ).hasMatch(text) &&
      category == 'gutters and drainage') {
    score += 22;
  }
  if (RegExp(
    r'\b(k style gutter|k-style gutter|gutter 10 ft|gutter guard|micro mesh gutter guard)\b',
  ).hasMatch(text)) {
    if (itemName.contains('gutter')) {
      score += 76;
    }
    if (itemName.contains('siding') || itemName.contains('floor')) {
      score -= 36;
    }
  }
  if (RegExp(r'\b(roof nail|roofing nail|cap nail)\b').hasMatch(text) &&
      itemType.contains('nail')) {
    score += 22;
  }
  if (RegExp(
        r'\b(roof cement|roof sealant|flashing sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('sealant')) {
    score += 22;
  }
  if (RegExp(
        r'\b(roof deck|roof decking|roof sheathing|deck patch)\b',
      ).hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 28;
  }
  if (RegExp(r'\b(osb|cdx|plywood|sheathing)\b').hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 18;
  }
  if (RegExp(r'\b(h clip|h-clip|panel spacer)\b').hasMatch(text) &&
      itemName.contains('roof deck')) {
    score += 26;
  }
  if (RegExp(
    r'\b(roof h clip|roof h-clip|h clip panel spacer|h-clip panel spacer)\b',
  ).hasMatch(text)) {
    if (itemName.contains('h-clip panel spacer')) {
      score += 90;
    }
    if (itemName.contains('tile') || itemName.contains('clip spacer')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(metal roof|metal roofing|ridge cap|rake trim|eave trim)\b',
      ).hasMatch(text) &&
      itemName.contains('metal roofing')) {
    score += 28;
  }
  if (RegExp(r'\b(closure strip|foam closure)\b').hasMatch(text) &&
      itemName.contains('closure strip')) {
    score += 26;
  }
  if (RegExp(r'\b(butyl tape|roof butyl)\b').hasMatch(text) &&
      itemName.contains('butyl tape')) {
    score += 26;
  }
  if (RegExp(
        r'\b(roof repair tape|roof patch tape|cover tape|seam roller|flashing primer)\b',
      ).hasMatch(text) &&
      itemType.contains('roof patch')) {
    score += 34;
  }
  if (RegExp(
    r'\b(peel and stick roof repair tape|roof repair tape)\b',
  ).hasMatch(text)) {
    if (itemName.contains('roof repair tape')) {
      score += 88;
    }
    if (itemName.contains('floor') || itemName.contains('vinyl')) {
      score -= 40;
    }
  }
  if (RegExp(
        r'\b(gutter guard|micro mesh|foam gutter guard|brush gutter)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 34;
  }
  if (RegExp(
        r'\b(heat cable|deicing cable|de-icing cable|roof clip)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 34;
  }
  if (RegExp(
        r'\b(downspout strainer|splash block|downspout extension)\b',
      ).hasMatch(text) &&
      itemType.contains('gutter guards')) {
    score += 26;
  }
  if (RegExp(
        r'\b(roof anchor|roof bracket|toe board|walk pad|warning line|ladder roof hook|roof harness)\b',
      ).hasMatch(text) &&
      itemType.contains('roof safety')) {
    score += 36;
  }
  if (RegExp(r'\b(metal roofing screw|roofing screw)\b').hasMatch(text) &&
      itemName.contains('metal roofing screw')) {
    score += 28;
  }
  if (RegExp(
        r'\b(soffit panel|vented soffit|solid soffit|fascia cover|aluminum fascia|f channel|j channel|soffit channel)\b',
      ).hasMatch(text) &&
      itemType.contains('soffit fascia')) {
    score += 30;
  }
  if (RegExp(r'\b(soffit|fascia|f channel|j channel)\b').hasMatch(text)) {
    if (itemName.contains('soffit') ||
        itemName.contains('fascia') ||
        itemName.contains('channel')) {
      score += 26;
    } else if (itemName.contains('gutter')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(soffit panel|vented soffit|solid soffit)\b').hasMatch(text)) {
    if (itemName.contains('soffit panel')) {
      score += 60;
    } else if (itemName.contains('fascia')) {
      score -= 24;
    }
  }
  if (text.contains('vented soffit')) {
    if (itemName.contains('vented') && itemName.contains('soffit')) {
      score += 42;
    } else if (itemName.contains('solid') && itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (text.contains('solid soffit')) {
    if (itemName.contains('solid') && itemName.contains('soffit')) {
      score += 42;
    } else if (itemName.contains('vented') && itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(fascia cover|aluminum fascia|fascia trim)\b',
  ).hasMatch(text)) {
    if (itemName.contains('fascia cover')) {
      score += 60;
    } else if (itemName.contains('soffit')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(epdm|tpo|low slope|modified bitumen|base sheet|cold process|roof adhesive|silicone roof coating|elastomeric roof coating)\b',
      ).hasMatch(text) &&
      itemType.contains('low slope')) {
    score += 32;
  }
  if (RegExp(
    r'\b(tpo seam tape|epdm seam tape|tpo patch|epdm patch)\b',
  ).hasMatch(text)) {
    if (itemName.contains('tpo') || itemName.contains('epdm')) {
      score += 84;
    }
    if (itemName.contains('tile') || itemName.contains('membrane seam')) {
      score -= 42;
    }
  }
  if (RegExp(
    r'\b(silicone roof coating|elastomeric roof coating|roof coating)\b',
  ).hasMatch(text)) {
    if (itemName.contains('roof coating')) {
      score += 88;
    }
    if (itemName.contains('pipe boot')) {
      score -= 96;
    }
  }
  if (RegExp(r'\b(epdm patch|tpo patch|patch kit)\b').hasMatch(text)) {
    if (itemName.contains('patch kit')) {
      score += 34;
    } else if (itemName.contains('roof coating')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(roof jack|storm collar|b vent flashing|gas vent flashing|chimney flashing|skylight flashing|roof cricket|rain diverter)\b',
      ).hasMatch(text) &&
      itemType.contains('roof jacks')) {
    score += 32;
  }
  if (RegExp(
        r'\b(chimney flashing|counter flashing|skylight flashing|sidewall flashing|endwall flashing|kickout flashing)\b',
      ).hasMatch(text) &&
      itemType.contains('chimney skylight')) {
    score += 36;
  }
  if (RegExp(
        r'\b(chimney cap|chimney rain cap|rain cap|vent cap|spark arrestor|bird screen|vent mesh guard)\b',
      ).hasMatch(text) &&
      itemType.contains('vent cap')) {
    score += 36;
  }
  if (RegExp(
    r'\b(chimney rain cap|chimney cap|spark arrestor|bird screen|vent mesh guard)\b',
  ).hasMatch(text)) {
    if (itemName.contains('chimney') ||
        itemName.contains('spark arrestor') ||
        itemName.contains('bird screen') ||
        itemName.contains('vent mesh guard')) {
      score += 70;
    } else if (itemName.contains('wall cap') || itemName.contains('duct')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(roof jack|adjustable roof jack)\b').hasMatch(text)) {
    if (itemName.contains('roof jack')) {
      score += 70;
    } else if (itemName.contains('pipe boot')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(storm collar|vent collar)\b').hasMatch(text)) {
    if (itemName.contains('storm collar')) {
      score += 36;
    } else if (itemName.contains('pipe boot')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(thinset|grout|tile)\b').hasMatch(text)) score -= 18;
  return score;
}
