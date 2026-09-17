part of '../../work_supply_receipt_parser.dart';

/// Scores HVAC air distribution, line-hide, vent, and gas-install evidence.
int _hvacAirDistributionAndGasReceiptScore(String text, WorkSupplyItem item) {
  var score = 0;
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = _normalize(item.variant);
  if (RegExp(r'\b(spin in|spin-in|takeoff)\b').hasMatch(text)) {
    if (itemName.contains('takeoff')) {
      score += 54;
    }
    if (text.contains('with damper') &&
        itemName.contains('takeoff with damper')) {
      score += 86;
    } else if (text.contains('with damper') &&
        itemName.contains('takeoff') &&
        !itemName.contains('with damper')) {
      score -= 34;
    }
  }
  if (RegExp(r'\b(galvanized sheet metal|sheet metal)\b').hasMatch(text)) {
    if (itemName.contains('galvanized sheet metal')) {
      score += 112;
    } else if (itemName.contains('elbow') ||
        itemName.contains('round duct') ||
        itemName.contains('takeoff')) {
      score -= 50;
    }
    for (final size in ['12 x 24', '24 x 24', '24 x 36', '36 x 48']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 52;
      }
    }
  }
  if (RegExp(
        r'\b(line set cover|line hide|equipment pad|condenser pad|wall bracket|ground stand|tie down kit|hurricane strap)\b',
      ).hasMatch(text) &&
      itemType.contains('line set covers')) {
    score += 34;
  }
  if (text.contains('line hide') && itemName.contains('line hide')) {
    score += 72;
  } else if (text.contains('line hide') &&
      itemName.contains('line set cover')) {
    score -= 28;
  }
  if (text.contains('line hide')) {
    for (final part in ['elbow', 'coupling', 'end cap', 'wall cap']) {
      if (text.contains(part) && itemName.contains('line hide $part')) {
        score += 82;
      } else if (text.contains(part) &&
          itemName.contains('line hide') &&
          !itemName.contains(part)) {
        score -= 36;
      }
    }
    for (final size in ['3 in', '4 in', '5 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 64;
      } else if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('line hide') &&
          !itemName.contains(size)) {
        score -= 26;
      }
    }
    for (final color in ['white', 'black', 'brown']) {
      if (text.contains(color) && itemName.contains(color)) {
        score += 30;
      } else if (text.contains(color) &&
          itemName.contains('line hide') &&
          !itemName.contains(color)) {
        score -= 16;
      }
    }
  }
  if (RegExp(
    r'\b(equipment pad|condenser pad|hurricane pad|wall bracket|ground stand|snow stand|tie down strap|vibration pad)\b',
  ).hasMatch(text)) {
    if (itemName.contains('equipment pad') ||
        itemName.contains('condenser pad') ||
        itemName.contains('hurricane pad') ||
        itemName.contains('wall bracket') ||
        itemName.contains('ground stand') ||
        itemName.contains('tie down') ||
        itemName.contains('vibration pad')) {
      score += 48;
    }
    for (final part in [
      'equipment pad',
      'condenser pad',
      'hurricane pad',
      'wall bracket',
      'ground stand',
      'snow stand',
      'condenser tie down strap kit',
      'hurricane pad strap kit',
      'anti vibration pad',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 72;
      } else if (text.contains(part) &&
          (itemName.contains('pad') ||
              itemName.contains('bracket') ||
              itemName.contains('stand')) &&
          !itemName.contains(part)) {
        score -= 24;
      }
    }
    for (final size in [
      '18 x 38',
      '24 x 24',
      '24 x 36',
      '30 x 30',
      '32 x 32',
      '36 x 36',
      '40 x 40',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 44;
      } else if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('equipment pad') ||
              itemName.contains('condenser pad') ||
              itemName.contains('hurricane pad')) &&
          !itemName.contains(size)) {
        score -= 20;
      }
    }
  }
  if (RegExp(
        r'\b(mini split|mini-split|line hide|communication cable)\b',
      ).hasMatch(text) &&
      itemType.contains('mini split')) {
    score += 28;
  }
  if (text.contains('mini split') &&
      text.contains('line hide') &&
      itemType.contains('mini split')) {
    score += 30;
  }
  if (text.contains('mini split') &&
      itemType.contains('line set covers') &&
      !variant.contains('mini split')) {
    score -= 16;
  }
  if (text.contains('communication cable')) {
    if (itemName.contains('communication cable')) {
      score += 80;
    } else if (itemType.contains('mini split')) {
      score -= 28;
    }
    for (final cable in ['14/4 x 50 ft', '14/4 x 100 ft', '16/4 x 50 ft']) {
      final compact = cable
          .replaceAll(' x ', ' ')
          .replaceAll(' ', '')
          .replaceAll('ft', 'ft');
      final receiptCompact = text.replaceAll(' ', '');
      if ((text.contains(cable) || receiptCompact.contains(compact)) &&
          itemName.contains(cable)) {
        score += 86;
      } else if ((text.contains(cable) || receiptCompact.contains(compact)) &&
          itemName.contains('communication cable') &&
          !itemName.contains(cable)) {
        score -= 28;
      }
    }
  }
  if (RegExp(
        r'\b(register|grille|vent cover|wall stack boot)\b',
      ).hasMatch(text) &&
      itemType.contains('boots')) {
    score += 24;
  }
  if (text.contains('register boot')) {
    if (itemName.contains('register boot')) {
      score += 70;
    }
    for (final style in ['straight', 'end']) {
      if (text.contains(style) && itemName.contains(style)) {
        score += 54;
      } else if (text.contains(style) &&
          itemName.contains('register boot') &&
          !itemName.contains(style)) {
        score -= 20;
      }
    }
  }
  if (text.contains('manual balancing damper')) {
    if (itemName.contains('manual balancing damper')) {
      score += 110;
    } else if (itemName.contains('duct reducer') ||
        itemName.contains('round duct')) {
      score -= 48;
    }
  }
  if (text.contains('ul181') && text.contains('foil tape')) {
    if (itemName.contains('ul181 foil tape')) {
      score += 110;
    } else if (itemName.contains('foil hvac tape')) {
      score -= 46;
    }
  }
  if (RegExp(r'\b(sediment trap|drip leg)\b').hasMatch(text)) {
    if (itemName.contains('sediment trap') || itemName.contains('drip leg')) {
      score += 116;
    }
    if (itemName.contains('black iron') && !itemName.contains('sediment')) {
      score -= 36;
    }
  }
  if (text.contains('gas appliance connector') ||
      text.contains('gas flex connector')) {
    if (itemName.contains('gas appliance connector')) {
      score += 118;
    } else if (itemName.contains('gas connector') ||
        itemName.contains('gas range connector')) {
      score += 32;
    } else if (itemName.contains('connector')) {
      score -= 20;
    }
    for (final size in ['1/2 in', '3/4 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 38;
      } else if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains('gas appliance connector') &&
          !itemName.contains(size)) {
        score -= 18;
      }
    }
    for (final length in ['24 in', '36 in', '48 in', '60 in']) {
      final compact = length.replaceAll(' ', '');
      if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains(length)) {
        score += 46;
      } else if ((text.contains(length) || text.contains(compact)) &&
          itemName.contains('gas appliance connector') &&
          !itemName.contains(length)) {
        score -= 20;
      }
    }
  }
  if (RegExp(r'\b(bath fan wall cap|bath fan roof jack)\b').hasMatch(text)) {
    if (itemName.contains('bath fan wall cap') ||
        itemName.contains('bath fan roof jack')) {
      score += 116;
    } else if (itemName.contains('wall cap') || itemName.contains('roof cap')) {
      score -= 38;
    }
  }
  if (RegExp(
        r'\b(register boot|duct boot|spin in|spin-in|takeoff|start collar|round reducer|round wye)\b',
      ).hasMatch(text) &&
      itemType.contains('duct boots')) {
    score += 34;
  }
  if (RegExp(
    r'\b(round duct|duct pipe|sheet metal|manual damper|backdraft damper|start collar|takeoff collar|spin in|spin-in|round reducer|round wye|round tee)\b',
  ).hasMatch(text)) {
    if (itemName.contains('round duct') ||
        itemName.contains('duct pipe') ||
        itemName.contains('manual damper') ||
        itemName.contains('backdraft damper') ||
        itemName.contains('start collar') ||
        itemName.contains('takeoff') ||
        itemName.contains('round reducer') ||
        itemName.contains('round wye') ||
        itemName.contains('round tee')) {
      score += 44;
    }
    for (final item in [
      'manual damper',
      'backdraft damper',
      'start collar',
      'takeoff collar',
      'spin in takeoff',
      'round reducer',
      'round wye',
      'round tee',
      'adjustable elbow',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 70;
      } else if (text.contains(item) &&
          (itemName.contains('duct') ||
              itemName.contains('damper') ||
              itemName.contains('elbow') ||
              itemName.contains('collar')) &&
          !itemName.contains(item)) {
        score -= 28;
      }
    }
    for (final size in [
      '3 in',
      '4 in',
      '5 in',
      '6 in',
      '7 in',
      '8 in',
      '9 in',
      '10 in',
      '12 in',
      '14 in',
      '16 in',
      '18 in',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 28;
      }
    }
    for (final gauge in ['26 gauge', '28 gauge', '30 gauge']) {
      final compact = gauge.replaceAll('uge', '').replaceAll(' ', '');
      if ((text.contains(gauge) || text.contains(compact)) &&
          itemName.contains(gauge)) {
        score += 30;
      }
    }
  }
  if (RegExp(
        r'\b(b vent|b-vent|gas vent|flue pipe|draft hood|wall cap|roof cap|backdraft damper|galvanized pipe)\b',
      ).hasMatch(text) &&
      itemType.contains('duct pipe')) {
    score += 34;
  }
  if (text.contains('dryer vent hood')) {
    if (itemName.contains('dryer vent hood')) {
      score += 90;
    } else if (itemName.contains('dryer')) {
      score += 20;
    }
  }
  if (RegExp(
    r'\b(b vent|b-vent|gas vent|flue pipe|draft hood|storm collar|wall thimble)\b',
  ).hasMatch(text)) {
    if (itemName.contains('b vent') ||
        itemName.contains('gas vent') ||
        itemName.contains('flue pipe') ||
        itemName.contains('draft hood')) {
      score += 38;
    }
    for (final part in [
      'b vent adjustable elbow',
      'b vent 90 elbow',
      'b vent pipe',
      'b vent tee',
      'b vent cap',
      'b vent storm collar',
      'b vent wall thimble',
      'draft hood connector',
      'single wall flue pipe',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 82;
      } else if (text.contains(part) &&
          (itemName.contains('b vent') ||
              itemName.contains('flue pipe') ||
              itemName.contains('draft hood')) &&
          !itemName.contains(part)) {
        score -= 32;
      }
    }
  }
  if (RegExp(
        r'\b(zone damper|zoning panel|humidifier pad|uv lamp|air cleaner)\b',
      ).hasMatch(text) &&
      itemType.contains('zoning')) {
    score += 26;
  }
  if (RegExp(
    r'\b(zone damper|round zone damper|bypass damper|motorized round damper|zone control panel|zone panel|damper motor)\b',
  ).hasMatch(text)) {
    if (itemName.contains('zone damper') ||
        itemName.contains('bypass damper') ||
        itemName.contains('motorized round damper') ||
        itemName.contains('zone control panel') ||
        itemName.contains('damper motor')) {
      score += 64;
    } else if (itemName.contains('duct') || itemName.contains('elbow')) {
      score -= 38;
    }
    for (final part in [
      'round zone damper',
      'bypass damper',
      'motorized round damper',
      'zone control panel',
      'zone damper motor',
    ]) {
      if (text.contains(part) && itemName.contains(part)) {
        score += 84;
      } else if (text.contains(part) &&
          (itemName.contains('damper') || itemName.contains('zone')) &&
          !itemName.contains(part)) {
        score -= 24;
      }
    }
    for (final size in ['6 in', '8 in', '10 in', '12 in', '14 in', '16 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 30;
      }
    }
    for (final voltage in ['24v', '120v']) {
      if (text.contains(voltage) && itemName.contains(voltage)) {
        score += 28;
      }
    }
  }
  return score;
}
