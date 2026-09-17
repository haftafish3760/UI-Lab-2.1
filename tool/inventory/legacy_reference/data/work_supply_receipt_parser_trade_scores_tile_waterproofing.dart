part of 'work_supply_receipt_parser.dart';

int _tileWaterproofingProfileReceiptScore(_TileReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final trade = context.trade;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final category = context.category;
  final variant = context.variant;

  if (RegExp(
        r'\b(uncoupling membrane|waterproofing membrane|shower membrane|cement board|backer board)\b',
      ).hasMatch(text) &&
      category == 'waterproofing') {
    score += 26;
  }
  if (RegExp(
        r'\b(crack isolation membrane|crack isolation|anti fracture membrane|antifracture membrane|peel and stick tile membrane|membrane primer|tile primer|'
        r'self leveling primer|floor heat mat|heated floor|floor heat cable|radiant floor heat|floor heat thermostat|self leveling underlayment)\b',
      ).hasMatch(text) &&
      itemType.contains('crack isolation')) {
    score += 34;
  }
  if (RegExp(
    r'\b(crack isolation membrane|crack isolation)\b',
  ).hasMatch(text)) {
    if (itemName.contains('crack isolation membrane')) {
      score += 62;
    } else if (itemName.contains('anti fracture')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(anti fracture membrane|antifracture membrane)\b',
  ).hasMatch(text)) {
    if (itemName.contains('anti fracture')) {
      score += 62;
    } else if (itemName.contains('crack isolation')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(floor heat|heated floor|radiant floor heat)\b',
  ).hasMatch(text)) {
    if (itemName.contains('floor heat') ||
        itemName.contains('heated floor') ||
        itemName.contains('radiant floor')) {
      score += 60;
    } else if (itemName.contains('membrane')) {
      score -= 10;
    }
    for (final area in [
      '10 sq ft',
      '15 sq ft',
      '20 sq ft',
      '25 sq ft',
      '30 sq ft',
      '40 sq ft',
      '50 sq ft',
      '60 sq ft',
      '80 sq ft',
      '100 sq ft',
    ]) {
      final compact = area.replaceAll(' ', '');
      if ((text.contains(area) || text.contains(compact)) &&
          itemName.contains(area)) {
        score += 44;
      } else if ((text.contains(area) || text.contains(compact)) &&
          (itemName.contains('floor heat') ||
              itemName.contains('radiant floor')) &&
          !itemName.contains(area)) {
        score -= 16;
      }
    }
  }
  if (RegExp(r'\b(shower pan|linear drain|shower niche)\b').hasMatch(text) &&
      itemType.contains('shower')) {
    score += 24;
  }
  if (RegExp(
    r'\b(shower tray|shower pan|tile ready pan|foam shower tray)\b',
  ).hasMatch(text)) {
    if (itemName.contains('shower tray') || itemName.contains('shower pan')) {
      score += 42;
    }
    for (final size in [
      '32 x 60',
      '36 x 36',
      '36 x 48',
      '36 x 60',
      '48 x 48',
      '48 x 60',
      '60 x 60',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('$size in')) {
        score += 58;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('shower tray') ||
              itemName.contains('shower pan')) &&
          !itemName.contains('$size in')) {
        score -= 20;
      }
    }
    for (final drain in ['left drain', 'right drain', 'center drain']) {
      if (text.contains(drain) && itemName.contains(drain)) {
        score += 36;
      } else if (text.contains(drain) &&
          (itemName.contains('shower tray') ||
              itemName.contains('shower pan')) &&
          !itemName.contains(drain)) {
        score -= 12;
      }
    }
  }
  if (RegExp(
    r'\b(linear shower drain|linear drain|shower drain)\b',
  ).hasMatch(text)) {
    if (itemName.contains('linear shower drain') ||
        itemName.contains('linear drain')) {
      score += 76;
    } else if (itemName.contains('shower pan') ||
        itemName.contains('pan extension')) {
      score -= 34;
    }
    for (final length in [
      '24 in',
      '30 in',
      '36 in',
      '42 in',
      '48 in',
      '60 in',
    ]) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 42;
      } else if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains('linear') &&
          !itemName.contains(length)) {
        score -= 18;
      }
    }
    for (final finish in [
      'brushed nickel',
      'matte black',
      'chrome',
      'oil rubbed bronze',
      'satin stainless',
    ]) {
      if (text.contains(finish) && itemName.contains(finish)) {
        score += 30;
      } else if (text.contains(finish) &&
          itemName.contains('linear') &&
          !itemName.contains(finish)) {
        score -= 12;
      }
    }
    if (text.contains('channel') && itemName.contains('channel')) {
      score += 28;
    }
  }
  if (RegExp(r'\b(shower pan extension|tray extension)\b').hasMatch(text)) {
    if (itemName.contains('shower pan extension')) {
      score += 68;
    } else if (itemName.contains('linear shower drain') ||
        itemName.contains('shower pan kit')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(drain grate|shower drain grate|tileable drain|tile-in drain|point drain|linear drain grate|drain grate cover|waterproof shower niche|foam shower niche|foot rest|shower bench bracket|shower curb overlay)\b',
      ).hasMatch(text) &&
      itemType.contains('shower')) {
    score += 34;
  }
  if (RegExp(
    r'\b(shower niche|foam niche|tile ready shower niche|recessed shower niche|shower curb|foam curb|shower bench|corner bench|corner shelf|foot rest)\b',
  ).hasMatch(text)) {
    if (itemName.contains('shower niche') ||
        itemName.contains('shower curb') ||
        itemName.contains('shower bench') ||
        itemName.contains('corner shelf') ||
        itemName.contains('foot rest')) {
      score += 54;
    } else if (itemName.contains('membrane')) {
      score -= 30;
    }
    for (final size in [
      '12 x 12',
      '12 x 20',
      '12 x 28',
      '16 x 20',
      '16 x 28',
      '16 x 32',
      '36 in',
      '48 in',
      '60 in',
      '72 in',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 46;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('shower niche') ||
              itemName.contains('shower curb') ||
              itemName.contains('shower bench')) &&
          !itemName.contains(size)) {
        score -= 14;
      }
    }
    for (final term in [
      'tile ready',
      'waterproof',
      'foam',
      'recessed',
      'triangular',
      'floating',
    ]) {
      if (text.contains(term) && itemName.contains(term)) score += 22;
    }
  }
  if (RegExp(r'\b(tileable drain|tile-in drain)\b').hasMatch(text)) {
    if (itemName.contains('tileable drain')) {
      score += 60;
    } else if (itemName.contains('linear shower drain')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(shower curb|foam curb|shower bench|foam bench|corner shelf|shower shelf|seam tape|waterproofing band|backer screw|backer board screw|pipe seal|mixing valve seal)\b',
      ).hasMatch(text) &&
      itemType.contains('shower curbs')) {
    score += 28;
  }
  if (RegExp(
    r'\b(waterproofing band|waterproofing seam tape|seam tape roll|uncoupling seam tape)\b',
  ).hasMatch(text)) {
    if (itemName.contains('waterproofing band') ||
        itemName.contains('seam tape')) {
      score += 48;
    }
    for (final length in ['16 ft', '33 ft', '50 ft', '98 ft']) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 42;
      } else if ((text.contains(length) || text.contains(compact)) &&
          (itemName.contains('waterproofing band') ||
              itemName.contains('seam tape')) &&
          !itemName.contains(length)) {
        score -= 14;
      }
    }
  }
  if (RegExp(
        r'\b(foam board washer|kerdi fix|waterproof sealant tube|shower pan extension|floor heat sensor|heat sensor wire|floor heat alarm)\b',
      ).hasMatch(text) &&
      itemType.contains('waterproof shower')) {
    score += 44;
  }
  if (RegExp(r'\b(foam board washer|tile board washer)\b').hasMatch(text)) {
    if (itemName.contains('foam board washer') &&
        itemType.contains('waterproof shower')) {
      score += 70;
    } else if (trade == 'tile' &&
        (itemName.contains('backer board') || itemName.contains('membrane'))) {
      score -= 8;
    }
  }
  if (RegExp(
    r'\b(schluter|tile trim|edge trim|profile|jolly|rondec|marble threshold|marble sill|tile sill|movement joint|transition strip|stair nose)\b',
  ).hasMatch(text)) {
    if (itemName.contains('profile') ||
        itemName.contains('edge trim') ||
        itemName.contains('threshold') ||
        variant.contains('profile') ||
        variant.contains('edge trim') ||
        variant.contains('threshold') ||
        variant.contains('movement joint') ||
        variant.contains('transition')) {
      score += 34;
    }
  }
  if (RegExp(
    r'\b(jolly|rondec|quadec|schiene|edge trim|inside corner profile|outside corner profile)\b',
  ).hasMatch(text)) {
    if (itemType.contains('metal tile profiles') ||
        itemName.contains('edge trim') ||
        itemName.contains('profile')) {
      score += 46;
    }
  }
  for (final term in [
    'jolly',
    'rondec',
    'quadec',
    'schiene',
    'inside corner',
    'outside corner',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 52;
    } else if (text.contains(term) &&
        itemType.contains('metal tile profiles') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(marble threshold|engineered stone threshold|shower curb cap|window sill|tile reducer|t molding|carpet transition|movement joint)\b',
  ).hasMatch(text)) {
    if (itemType.contains('thresholds') ||
        itemName.contains('threshold') ||
        itemName.contains('transition') ||
        itemName.contains('curb cap')) {
      score += 46;
    }
  }
  if (RegExp(r'\b(tile spacer|leveling clip|tile leveling)\b').hasMatch(text) &&
      itemType.contains('spacer')) {
    score += 22;
  }
  for (final term in [
    'tile spacer',
    'tile leveling clip',
    'tile leveling wedge',
    'reusable tile leveling cap',
    't spin leveling spacer',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 64;
    } else if (text.contains(term) &&
        itemType.contains('leveling') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  return score;
}
