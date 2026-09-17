part of '../../work_supply_receipt_parser.dart';

/// Scores receipt evidence for the Electrical trade.
int _electricalReceiptScore(
  String text,
  String trade,
  String category,
  String system,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'electrical') return score;
  if (RegExp(
    r'\b(gfci|gfi|receptacle|recept|outlet|romex|nm-b|nmb|mc|armored|emt|conduit|raceway|awg|wire|breaker|lb body|smart switch|smart dimmer|smoke alarm|smoke detector|co alarm|fan box|fan brace|weatherhead|ground bar|panel filler)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = _normalize(item.variant);
  final ampRating = RegExp(r'\b(\d{1,3})\s*amp\b').firstMatch(text);
  if (ampRating != null) {
    final rating = '${ampRating.group(1)} amp';
    if (variant == rating) {
      score += 24;
    } else if (variant.endsWith('amp')) {
      score -= 18;
    }
  }
  final receiptSaysNmCable = RegExp(
    r'\b(nm-b|nmb|romex|house wire)\b',
  ).hasMatch(text);
  final receiptSaysThhn = RegExp(r'\b(thhn|building wire)\b').hasMatch(text);
  final receiptLength = RegExp(r'\b(\d{2,4})\s*ft\b').firstMatch(text);
  final receiptSaysBreaker = RegExp(
    r'\b(breaker|brkr|circuit breaker)\b',
  ).hasMatch(text);
  final receiptSaysSinglePole = RegExp(
    r'\b(single pole|single-pole|1p)\b',
  ).hasMatch(text);
  final receiptSaysDoublePole = RegExp(
    r'\b(double pole|double-pole|2p)\b',
  ).hasMatch(text);
  final receiptSaysGfci = RegExp(
    r'\b(gfci|gfc1|gfi|ground fault)\b',
  ).hasMatch(text);
  final receiptSaysAfci = RegExp(r'\b(afci|arc fault)\b').hasMatch(text);
  final receiptSaysDualFunction = RegExp(
    r'\b(dual function|dual-function)\b',
  ).hasMatch(text);
  final receiptPackCount = RegExp(r'\b(\d+)\s*pack\b').firstMatch(text);
  final receiptSaysOutlet = RegExp(
    r'\b(receptacle|recept|outlet|wall socket|plug)\b',
  ).hasMatch(text);
  final receiptSaysMcCable = RegExp(
    r'\b(mc|armored cable|metal clad|bx)\b',
  ).hasMatch(text);
  final receiptSaysFlexibleRaceway = RegExp(
    r'\b(flex|flexible|fmc|liquid\s*tight|liquidtight|sealtite)\b',
  ).hasMatch(text);
  final receiptSaysPhotocell = RegExp(
    r'\b(photocell|photoeye|photo eye)\b',
  ).hasMatch(text);
  final receiptSaysEmt = RegExp(r'\b(emt|thinwall)\b').hasMatch(text);
  final receiptSaysConduit = RegExp(r'\b(conduit|pipe)\b').hasMatch(text);
  final receiptSaysRacewayBody = RegExp(
    r'\b(lb body|ll body|lr body|conduit body)\b',
  ).hasMatch(text);
  final receiptSaysConnector = RegExp(
    r'\b(connector|conn|set screw conn)\b',
  ).hasMatch(text);
  final receiptSaysCoupling = RegExp(
    r'\b(coupling|cplg|coup)\b',
  ).hasMatch(text);
  final receiptSaysWireNut = RegExp(
    r'\b(wire nut|wirenut|tuerca cable|conector cable)\b',
  ).hasMatch(text);
  final receiptSaysWinged = RegExp(r'\bwing(ed)?\b').hasMatch(text);
  final receiptSaysSmartControl = RegExp(
    r'\b(smart switch|smart dimmer|wifi switch|wi-fi switch|motion switch|occupancy sensor|vacancy sensor|timer switch|countdown timer)\b',
  ).hasMatch(text);
  final receiptSaysAlarm = RegExp(
    r'\b(smoke alarm|smoke detector|co alarm|carbon monoxide|heat alarm)\b',
  ).hasMatch(text);
  final receiptSaysLedLighting = RegExp(
    r'\b(led shop light|shop light|led lamp|led bulb|led driver|tape light)\b',
  ).hasMatch(text);
  final receiptSaysDoorbell = RegExp(
    r'\b(doorbell transformer|bell transformer|doorbell chime|video doorbell)\b',
  ).hasMatch(text);
  final receiptSaysFanSupport = RegExp(
    r'\b(fan box|fan brace|ceiling fan box|fixture box|ceiling box|bar hanger)\b',
  ).hasMatch(text);
  final receiptSaysBoxAccessory = RegExp(
    r'\b(mud ring|box extender|extension ring|knockout seal|ko seal|locknut|bushing|reducing washer)\b',
  ).hasMatch(text);
  final receiptSaysDeviceBox = RegExp(
    r'\b(device box|outlet box|switch box|single gang box|gang device box)\b',
  ).hasMatch(text);
  final receiptSaysJunctionBox = RegExp(
    r'\b(junction box|j box|square box)\b',
  ).hasMatch(text);
  final receiptSaysWeatherproofCover = RegExp(
    r'\b(weatherproof|extra duty|in use|in-use|bubble cover|outdoor cover)\b',
  ).hasMatch(text);
  final receiptSaysWallPlate = RegExp(
    r'\b(wall plate|cover plate|switch plate|device plate|blank plate|decorator plate|decora plate|placa|placa electrica|placa decora|placa decorador|cubierta electrica)\b',
  ).hasMatch(text);
  final receiptSaysPanelAccessory = RegExp(
    r'\b(ground bar|neutral bar|breaker filler|panel filler|panel label|circuit directory|panel schedule|interlock kit|surge protective)\b',
  ).hasMatch(text);
  final receiptSaysServiceAccessory = RegExp(
    r'\b(weatherhead|service head|service entrance head|mast clamp|service mast|ground bridge|bonding terminal)\b',
  ).hasMatch(text);
  final receiptSaysRacewaySupport = RegExp(
    r'\b(one hole strap|two hole strap|mini strap|conduit strap|conduit hanger|minerallac|beam clamp|strut clamp)\b',
  ).hasMatch(text);
  if (receiptSaysNmCable && system == 'nm-b cable') score += 24;
  if (receiptSaysThhn && system == 'conduit wire') score += 24;
  if (receiptSaysThhn && itemName.contains('thhn')) score += 72;
  if (receiptSaysThhn && receiptLength != null) {
    final length = '${receiptLength.group(1)} ft';
    if (variant.contains(length) || itemName.contains(length)) {
      score += 34;
    } else if (system == 'conduit wire' && itemName.contains('thhn')) {
      score -= 12;
    }
  }
  if (receiptSaysMcCable && itemType.contains('armored cable')) score += 28;
  if (receiptSaysMcCable && itemType.contains('nm-b')) score -= 16;
  if (receiptSaysFlexibleRaceway &&
      (itemType.contains('flexible raceway') ||
          itemName.contains('flexible raceway') ||
          variant.contains('flexible metal') ||
          variant.contains('fmc') ||
          variant.contains('liquidtight'))) {
    score += 54;
  }
  if (receiptSaysFlexibleRaceway && variant.contains('1/2 in')) score += 26;
  if (receiptSaysFlexibleRaceway && variant.contains('1-1/2 in')) score -= 28;
  if (receiptSaysFlexibleRaceway && system == 'emt') score -= 26;
  if (receiptSaysNmCable && system == 'conduit wire') score -= 20;
  if (receiptSaysThhn && system == 'nm-b cable') score -= 20;
  if (text.contains('with ground') && system == 'nm-b cable') score += 10;
  if (receiptSaysBreaker && category == 'breakers') score += 22;
  if (receiptSaysSinglePole && itemType.contains('single-pole')) score += 22;
  if (receiptSaysDoublePole && itemType.contains('double-pole')) score += 22;
  if (receiptSaysSinglePole && itemType.contains('double-pole')) score -= 22;
  if (receiptSaysDoublePole && itemType.contains('single-pole')) score -= 22;
  if (receiptSaysOutlet && system == 'receptacles') score += 22;
  if (receiptSaysOutlet &&
      (itemType.contains('wiring device') ||
          itemName.contains('wiring device'))) {
    score += 20;
  }
  if (receiptPackCount != null) {
    final pack = '${receiptPackCount.group(1)} pack';
    if (variant.contains(pack)) {
      score += 24;
    } else if (itemType.contains('receptacle') || itemType.contains('outlet')) {
      score -= 10;
    }
  }
  if (receiptSaysGfci && itemType.contains('gfci')) score += 36;
  if (receiptSaysGfci && !itemType.contains('gfci')) score -= 12;
  if (receiptSaysAfci && itemType.contains('afci')) score += 20;
  if (receiptSaysAfci && !itemType.contains('afci')) score -= 12;
  if (receiptSaysDualFunction && itemName.contains('dual function')) {
    score += 92;
  } else if (receiptSaysDualFunction && category == 'breakers') {
    score -= 32;
  }
  if (receiptSaysEmt && system == 'emt') score += 20;
  if (receiptSaysConduit && itemType.contains('conduit')) score += 18;
  if (receiptSaysRacewayBody && itemType.contains('raceway')) score += 24;
  if (receiptSaysRacewayBody && itemType.contains('conduit bodies')) {
    score += 38;
  }
  if (receiptSaysRacewaySupport && itemType.contains('raceway hangers')) {
    score += 34;
  }
  if (receiptSaysConnector && itemType.contains('connector')) score += 18;
  if (receiptSaysCoupling && itemType.contains('coupling')) score += 18;
  if (receiptSaysConnector && itemType.contains('coupling')) score -= 16;
  if (receiptSaysCoupling && itemType.contains('connector')) score -= 16;
  if (receiptSaysWireNut &&
      (itemType.contains('wire connector') ||
          itemType.contains('wire nut') ||
          itemName.contains('wire connector'))) {
    score += 24;
  }
  if (receiptSaysWinged && variant.contains('winged')) score += 28;
  if (receiptSaysWinged &&
      (itemType.contains('wire connector') ||
          itemType.contains('wire nut') ||
          itemName.contains('wire connector')) &&
      !variant.contains('winged')) {
    score -= 14;
  }
  if (receiptSaysSmartControl && itemType.contains('smart controls')) {
    score += 34;
  }
  if (receiptSaysAlarm && itemType.contains('safety and alarm')) score += 36;
  if (receiptSaysDoorbell && itemType.contains('safety and alarm')) {
    score += 32;
  }
  if (receiptSaysLedLighting &&
      (itemType.contains('lamp') ||
          itemType.contains('lighting') ||
          itemName.contains('led'))) {
    score += 44;
  }
  if (receiptSaysPhotocell && variant.contains('photocell')) score += 110;
  if (receiptSaysPhotocell && !variant.contains('photocell')) score -= 36;
  if (text.contains('shop light') && itemName.contains('shop light')) {
    score += 36;
  }
  if (text.contains('video doorbell') &&
      itemName.contains('doorbell transformer')) {
    score -= 28;
  }
  if (receiptSaysFanSupport && itemType.contains('fan and fixture')) {
    score += 38;
  }
  if (receiptSaysDeviceBox && itemName.contains('electrical box')) {
    score += 40;
    if (text.contains('old work') && itemName.contains('old work')) {
      score += 28;
    }
    if (text.contains('new work') && itemName.contains('new work')) {
      score += 28;
    }
  }
  if (receiptSaysJunctionBox && itemName.contains('junction box')) {
    score += 44;
  }
  if (receiptSaysWeatherproofCover) {
    if (itemName.contains('weatherproof')) {
      score += 72;
    } else if (itemName.contains('cover')) {
      score -= 30;
    }
    if ((text.contains('bubble cover') ||
            text.contains('extra duty') ||
            text.contains('in use') ||
            text.contains('in-use')) &&
        itemName.contains('in-use cover')) {
      score += 82;
    }
  }
  if (receiptSaysWallPlate && itemName.contains('cover plate')) {
    score += 48;
    if (text.contains('blank') && variant.contains('blank')) score += 32;
    if (!text.contains('blank') && variant.contains('blank')) score -= 36;
    if (RegExp(r'\b(1g|1 gang|single gang)\b').hasMatch(text) &&
        variant.contains('1 gang')) {
      score += 28;
    }
    if (RegExp(r'\b(wht|white)\b').hasMatch(text)) {
      if (variant.contains('white')) {
        score += 42;
      } else if (variant.contains('black') || variant.contains('brown')) {
        score -= 42;
      }
    }
  }
  if (receiptSaysWallPlate && itemName.contains('wall plate')) {
    score += 54;
    final receiptHasPlateColor = RegExp(
      r'\b(black|brown|gray|grey|ivory|light almond|white|blk|brn|gry|wht)\b',
    ).hasMatch(text);
    if (!receiptHasPlateColor) {
      if (variant.contains('white')) score += 24;
      if (RegExp(r'\b(black|brown|gray)\b').hasMatch(variant)) score -= 24;
    }
    if (RegExp(r'\b(decora|decorator|decorador)\b').hasMatch(text)) {
      if (variant.contains('decorator')) {
        score += 58;
      } else if (variant.contains('blank') ||
          variant.contains('toggle') ||
          variant.contains('duplex')) {
        score -= 52;
      }
    }
    if (text.contains('blank')) {
      if (variant.contains('blank')) {
        score += 36;
      } else {
        score -= 26;
      }
    } else if (variant.contains('blank')) {
      score -= 32;
    }
  }
  if (receiptSaysBoxAccessory && itemType.contains('box accessories')) {
    score += 34;
  }
  if (RegExp(r'\b(low voltage bracket|lv bracket)\b').hasMatch(text) &&
      itemType.contains('box accessories')) {
    score += 42;
    if (itemName.contains('mud ring') || itemName.contains('box extender')) {
      score += 24;
    }
  }
  if (receiptSaysPanelAccessory && itemType.contains('panel accessories')) {
    score += 38;
  }
  if (receiptSaysServiceAccessory &&
      itemType.contains('service entrance accessories')) {
    score += 38;
  }
  for (final term in [
    'smart dimmer',
    'smart switch',
    'motion sensor',
    'occupancy sensor',
    'timer switch',
    'smoke alarm',
    'carbon monoxide',
    'doorbell transformer',
    'fan brace',
    'ceiling fan',
    'mud ring',
    'box extender',
    'ground bar',
    'neutral bar',
    'breaker filler',
    'panel schedule',
    'weatherhead',
    'service entrance',
    'bonding terminal',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  return score;
}
