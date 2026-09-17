part of 'work_supply_receipt_parser.dart';

int _wellSepticWaterTreatmentReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'well septic and water treatment') return score;
  if (RegExp(
    r'\b(well pump|jet pump|submersible pump|pressure tank|tank tee|pitless|well cap|water filter|sediment filter|softener|reverse osmosis|uv lamp|septic|'
    r'effluent pump|sewage pump|drainfield|leach field|chemical feed|water test)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();

  if (RegExp(
    r'\b(well pump|jet pump|submersible pump|booster pump|pump control|pressure switch)\b',
  ).hasMatch(text)) {
    if (itemType.contains('well pumps')) score += 58;
  }
  for (final pumpType in [
    'shallow well jet pump',
    'convertible jet pump',
    'submersible well pump',
    'booster pump',
    'pump control box',
  ]) {
    if (text.contains(pumpType)) {
      if (itemName.contains(pumpType)) {
        score += 86;
      } else if (itemType.contains('well pumps')) {
        score -= 36;
      }
    }
  }
  if (RegExp(
    r'\b(pressure tank|well tank|tank tee|pressure gauge|pitless adapter|well seal|well cap)\b',
  ).hasMatch(text)) {
    if (itemType.contains('pressure tanks')) score += 58;
  }
  if (RegExp(
    r'\b(sediment filter|water filter|filter cartridge|whole house filter|filter housing|spin down filter)\b',
  ).hasMatch(text)) {
    if (itemType.contains('filter housings')) score += 58;
  }
  if (RegExp(
    r'\b(water softener|brine tank|softener resin|reverse osmosis|ro membrane|uv lamp|uv sleeve)\b',
  ).hasMatch(text)) {
    if (itemType.contains('softeners')) score += 58;
  }
  if (RegExp(
    r'\b(septic riser|riser lid|effluent pump|sewage pump|float switch|high water alarm)\b',
  ).hasMatch(text)) {
    if (itemType.contains('septic risers')) score += 58;
  }
  for (final septicPart in [
    'septic tank riser',
    'septic riser lid',
    'septic riser adapter ring',
    'effluent pump',
    'sewage pump',
    'septic pump float switch',
    'high water alarm',
  ]) {
    if (text.contains(septicPart)) {
      if (itemName.contains(septicPart)) {
        score += 84;
      } else if (itemType.contains('septic risers')) {
        score -= 34;
      }
    }
  }
  if (RegExp(
    r'\b(septic pipe|perforated drain pipe|drainfield|leach field|infiltrator|distribution box|septic fabric)\b',
  ).hasMatch(text)) {
    if (itemType.contains('drainfield')) score += 58;
  }
  if (text.contains('leach field chamber')) {
    if (itemName.contains('leach field chamber')) {
      score += 84;
    } else if (itemName.contains('chamber end cap')) {
      score -= 36;
    }
  }
  if (RegExp(
    r'\b(storage tank|retention tank|chemical feed|chlorine pump|water test|septic treatment|well sanitizer)\b',
  ).hasMatch(text)) {
    if (itemType.contains('storage tanks')) score += 56;
  }

  for (final size in [
    '1/2 hp',
    '3/4 hp',
    '1 hp',
    '1-1/2 hp',
    '115v',
    '230v',
    '20 gal',
    '32 gal',
    '44 gal',
    '62 gal',
    '86 gal',
    '3/4 in',
    '1 in',
    '1-1/4 in',
    '4.5 x 20 in',
    '5 micron',
    '24 in',
    '100 ft',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 24;
    }
  }
  for (final term in [
    'standard',
    'heavy duty',
    'contractor grade',
    'sediment',
    'carbon',
    'pleated',
    'string wound',
    'uv',
    'ro',
    'septic',
    'effluent',
    'chlorine',
    'iron',
    'hardness',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 16;
  }
  if (RegExp(
    r'\b(hvac|dryer|garage door|cabinet|paint|thhn|romex|dishwasher|range cord)\b',
  ).hasMatch(text)) {
    score -= 38;
  }
  if (category == 'well septic water treatment detail stock') score += 6;
  return score;
}
