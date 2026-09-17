part of 'work_supply_receipt_parser.dart';

int _sidingExteriorReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'siding and exterior') return score;
  if (RegExp(
    r'\b(siding|vinyl siding|dutch lap|lap siding|fiber cement|engineered siding|t1-11|shake siding|shingle siding|starter strip|j channel|f channel|'
    r'undersill|outside corner|inside corner|corner post|trim coil|pvc trim|mounting block|housewrap|house wrap|flashing tape|rain screen|drainage mat|'
    r'siding caulk|siding sealant|zip tool|gable vent|foundation vent|dryer vent hood|vinyl shutter|siding nail|fiber cement screw)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(vinyl siding|dutch lap|d4|d5|board batten)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vinyl siding')) {
      score += 60;
    } else if (itemName.contains('fiber cement')) {
      score -= 18;
    }
  }
  if (RegExp(r'\bd4\b').hasMatch(text)) {
    if (itemName.contains('double 4 in')) {
      score += 74;
    } else if (itemName.contains('double 5 in') || itemName.contains('4 x 8')) {
      score -= 36;
    }
  }
  if (RegExp(r'\bd5\b').hasMatch(text)) {
    if (itemName.contains('double 5 in')) {
      score += 74;
    } else if (itemName.contains('double 4 in') || itemName.contains('4 x 8')) {
      score -= 36;
    }
  }
  if (RegExp(
    r'\b(fiber cement|cement siding|engineered siding|lap siding|t1-11)\b',
  ).hasMatch(text)) {
    if (itemType.contains('fiber cement')) {
      score += 58;
    } else if (itemName.contains('vinyl siding')) {
      score -= 18;
    }
  }
  if (RegExp(r'\bfiber cement\b').hasMatch(text)) {
    if (itemName.contains('fiber cement')) {
      score += 68;
    } else if (itemName.contains('engineered wood') ||
        itemName.contains('cedar texture')) {
      score -= 28;
    }
  }
  if (RegExp(r'\bengineered (wood )?siding\b').hasMatch(text)) {
    if (itemName.contains('engineered wood')) {
      score += 58;
    } else if (itemName.contains('fiber cement')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(shake siding|shingle siding|scallop siding)\b',
  ).hasMatch(text)) {
    if (itemType.contains('shake')) {
      score += 56;
    } else if (itemName.contains('lap siding')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(starter strip|j channel|j-channel|f channel|undersill|finish trim|utility trim|corner post|outside corner|inside corner)\b',
  ).hasMatch(text)) {
    if (itemType.contains('starter')) {
      score += 58;
    } else if (itemName.contains('siding panel')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(pvc trim|trim board|trim coil|aluminum coil|mounting block|siding block)\b',
  ).hasMatch(text)) {
    if (itemType.contains('trim boards')) {
      score += 56;
    } else if (itemName.contains('siding trim')) {
      score -= 12;
    }
  }
  if (RegExp(
    r'\b(housewrap|house wrap|flashing tape|seam tape|rain screen|drainage mat|sill pan|window flashing|door sill pan)\b',
  ).hasMatch(text)) {
    if (itemType.contains('housewrap')) {
      score += 56;
    } else if (category == 'vapor barriers and accessories') {
      score -= 20;
    }
  }
  if (text.contains('exterior door sill pan')) {
    score -= 180;
  }
  if (text.contains('dryer vent hood')) {
    score -= 120;
  }
  if (RegExp(r'\bhousewrap roll\b').hasMatch(text)) {
    if (itemName.contains('housewrap roll') &&
        !itemName.contains('drainage') &&
        !itemName.contains('commercial')) {
      score += 62;
    } else if (itemName.contains('commercial') ||
        itemName.contains('drainage')) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(siding caulk|siding sealant|polyurethane sealant|siding repair|fiber cement patch|zip tool)\b',
  ).hasMatch(text)) {
    if (itemType.contains('sealant')) {
      score += 54;
    } else if (itemName.contains('siding panel')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(gable vent|foundation vent|dryer vent hood|louver vent|vinyl shutter|shutter pair)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vents')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(siding nail|ring shank siding nail|trim nail|fiber cement screw|siding screw)\b',
  ).hasMatch(text)) {
    if (itemType.contains('fasteners')) {
      score += 54;
    } else if (itemName.contains('shutter') || itemName.contains('vent')) {
      score -= 12;
    }
  }
  for (final length in ['10 ft', '12 ft', '1-1/4 in', '1-1/2 in', '2 in']) {
    final compact = length.replaceAll(' ', '');
    if ((text.contains(length) || text.contains(compact)) &&
        (itemName.contains(length) || variant.contains(length))) {
      score += 26;
    }
  }
  for (final color in [
    'white',
    'almond',
    'clay',
    'sandstone',
    'gray',
    'charcoal',
    'brown',
    'black',
    'blue',
    'sage',
    'cedar',
    'tan',
  ]) {
    if (text.contains(color) && itemName.contains(color)) score += 14;
  }
  if (RegExp(
    r'\b(shingle bundle|roofing nail|roof cement|ridge cap|k style gutter|gutter guard|micro mesh gutter guard)\b',
  ).hasMatch(text)) {
    score -= 54;
  }
  if (RegExp(
    r'\b(thhn|awg|romex|nm-b|nmb|bi nipple|black iron nipple|galv stl tee|pvc dwv|san tee)\b',
  ).hasMatch(text)) {
    score -= 80;
  }
  if (RegExp(r'\b(batt|fiberglass|foam board|r-\d{2})\b').hasMatch(text)) {
    score -= 18;
  }
  if (category == 'siding exterior detail stock') score += 6;
  return score;
}
