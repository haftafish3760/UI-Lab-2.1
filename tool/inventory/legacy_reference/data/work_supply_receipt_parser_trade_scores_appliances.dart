part of 'work_supply_receipt_parser.dart';

int _applianceInstallationRepairReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'appliance installation and repair') return score;
  if (RegExp(
    r'\b(dishwasher|garbage disposal|disposal|washer|washing machine|dryer|range|oven|stove|cooktop|refrigerator|fridge|ice maker|microwave|appliance)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();

  if (RegExp(
    r'\b(dishwasher supply|dishwasher connector|dishwasher elbow|dishwasher drain|dishwasher air gap|dishwasher bracket|dishwasher cord)\b',
  ).hasMatch(text)) {
    if (itemType.contains('dishwasher install')) score += 58;
  }
  if (RegExp(
    r'\b(garbage disposal|disposal mount|disposal cord|splash guard|discharge tube|air switch)\b',
  ).hasMatch(text)) {
    if (itemType.contains('garbage disposal')) score += 58;
  }
  if (RegExp(
    r'\b(washer hose|washing machine hose|washer drain|washer outlet box|washing machine valve|steam dryer hose)\b',
  ).hasMatch(text)) {
    if (itemType.contains('washer hoses')) score += 58;
  }
  if (RegExp(
    r'\b(dryer vent|dryer duct|dryer hose|dryer cord|dryer gas connector|dryer clamp)\b',
  ).hasMatch(text)) {
    if (itemType.contains('dryer venting')) score += 58;
  }
  if (text.contains('dryer vent hood')) {
    score -= 90;
  }
  if (RegExp(
    r'\b(range cord|oven cord|stove cord|gas range connector|anti tip bracket|range hood)\b',
  ).hasMatch(text)) {
    if (itemType.contains('range oven')) score += 58;
  }
  if (RegExp(
    r'\b(refrigerator water line|fridge water line|ice maker line|ice maker kit|saddle valve|fridge filter)\b',
  ).hasMatch(text)) {
    if (itemType.contains('refrigerator')) score += 58;
  }
  if (RegExp(
    r'\b(microwave bracket|microwave damper|microwave filter|dishwasher trim|oven trim|appliance filler|gap cover)\b',
  ).hasMatch(text)) {
    if (itemType.contains('microwave dishwasher')) score += 54;
  }
  if (RegExp(
    r'\b(door gasket|leveling leg|terminal block|thermal fuse|door switch|anti vibration pad)\b',
  ).hasMatch(text)) {
    if (itemType.contains('common appliance repair')) score += 54;
  }
  for (final part in [
    'door gasket',
    'leveling leg',
    'terminal block',
    'thermal fuse',
    'door switch',
    'anti vibration pad',
    'mounting screw',
    'handle screw',
  ]) {
    if (text.contains(part)) {
      if (itemName.contains(part)) {
        score += 76;
      } else if (itemType.contains('common appliance repair')) {
        score -= 28;
      }
    }
  }
  if (RegExp(
    r'\b(appliance drip pan|washer drain pan|range gap cover|touch up paint|appliance screw|appliance strap)\b',
  ).hasMatch(text)) {
    if (itemType.contains('appliance protection')) score += 52;
  }

  for (final size in [
    '24 in',
    '27 in',
    '30 in',
    '36 in',
    '40 amp',
    '50 amp',
    '30 amp',
    '3 prong',
    '4 prong',
    '4 ft',
    '5 ft',
    '6 ft',
    '8 ft',
    '10 ft',
    '20 ft',
    '25 ft',
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
  for (final appliance in [
    'dishwasher',
    'washer',
    'dryer',
    'range',
    'refrigerator',
    'microwave',
    'stainless',
    'white',
    'black',
    'chrome',
  ]) {
    if (text.contains(appliance) && itemName.contains(appliance)) score += 16;
  }
  if (RegExp(
    r'\b(general purpose cord|romex|breaker|receptacle|pex|toilet|sink faucet|cabinet|paint roller|garage door)\b',
  ).hasMatch(text)) {
    score -= 38;
  }
  if (category == 'appliance installation repair detail stock') score += 6;
  return score;
}
