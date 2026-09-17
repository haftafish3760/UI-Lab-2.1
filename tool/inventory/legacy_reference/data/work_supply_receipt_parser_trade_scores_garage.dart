part of 'work_supply_receipt_parser.dart';

int _garageDoorsOpenersReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'garage doors and openers') return score;
  if (RegExp(
    r'\b(garage door|garage opener|door opener|opener remote|opener rail|torsion spring|extension spring|lift cable|safety cable|cable drum|door roller|'
    r'garage hinge|bottom seal|threshold seal|photo eye|safety sensor|wall console|garage keypad|winding bar|door strut)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();

  if (RegExp(
    r'\b(garage door section|door panel|garage panel)\b',
  ).hasMatch(text)) {
    if (itemType.contains('residential garage door')) score += 58;
  }
  if (RegExp(
    r'\b(vertical track|garage door track|door roller|garage hinge)\b',
  ).hasMatch(text)) {
    if (itemType.contains('tracks hinges')) score += 56;
  }
  if (RegExp(
    r'\b(torsion spring|extension spring|garage spring)\b',
  ).hasMatch(text)) {
    if (itemType.contains('torsion')) score += 60;
  }
  if (RegExp(
    r'\b(lift cable|safety cable|cable drum|torsion tube)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cables drums')) score += 56;
  }
  if (text.contains('lift cable')) {
    if (itemName.contains('lift cable')) {
      score += 72;
    } else if (itemName.contains('cable drum') ||
        itemName.contains('safety cable')) {
      score -= 32;
    }
  }
  if (text.contains('safety cable')) {
    if (itemName.contains('safety cable')) {
      score += 72;
    } else if (itemName.contains('lift cable') ||
        itemName.contains('cable drum')) {
      score -= 32;
    }
  }
  if (RegExp(
    r'\b(chain drive|belt drive|screw drive|garage door opener)\b',
  ).hasMatch(text)) {
    if (itemType.contains('garage door openers')) score += 58;
  }
  if (RegExp(
    r'\b(remote|keypad|wall console|safety sensor|photo eye)\b',
  ).hasMatch(text)) {
    if (itemType.contains('remotes wall')) score += 56;
  }
  if (text.contains('safety sensor')) {
    if (itemName.contains('safety sensor')) {
      score += 74;
    } else if (itemName.contains('photo eye bracket')) {
      score -= 38;
    }
  }
  if (text.contains('photo eye bracket')) {
    if (itemName.contains('photo eye bracket')) {
      score += 74;
    } else if (itemName.contains('safety sensor')) {
      score -= 26;
    }
  }
  if (RegExp(
    r'\b(bottom seal|threshold seal|weather seal|stop molding)\b',
  ).hasMatch(text)) {
    if (itemType.contains('weather seals')) score += 56;
  }
  if (RegExp(
    r'\b(strut|slide lock|t handle|winding bar|garage door lube)\b',
  ).hasMatch(text)) {
    if (itemType.contains('struts locks')) score += 54;
  }

  for (final size in [
    '7 ft',
    '8 ft',
    '9 ft',
    '10 ft',
    '12 ft',
    '16 ft',
    '18 ft',
    '1/2 hp',
    '3/4 hp',
    '1 hp',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 24;
    }
  }
  for (final term in [
    'white',
    'almond',
    'sandstone',
    'brown',
    'black',
    'chain drive',
    'belt drive',
    'battery backup',
    'wi-fi',
    'smart',
    'left wind',
    'right wind',
    'nylon roller',
    'steel roller',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 18;
  }
  if (RegExp(
    r'\b(interior door|entry door|storm door|patio door|cabinet|drawer|flooring|paint)\b',
  ).hasMatch(text)) {
    score -= 36;
  }
  if (category == 'garage doors openers detail stock') score += 6;
  return score;
}
