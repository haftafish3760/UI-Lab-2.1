part of '../../work_supply_receipt_parser.dart';

/// Scores receipt evidence for cabinets and countertops.
int _cabinetsCountertopsReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'cabinets and countertops') return score;
  if (RegExp(
    r'\b(base cabinet|wall cabinet|sink base|drawer base|pantry cabinet|utility cabinet|kitchen cabinet|cabinet filler|toe kick|end panel|vanity|vanity cabinet|vanity top|medicine cabinet|countertop|counter top|laminate top|butcher block|solid surface|quartz top|granite top|side splash|countertop end cap|miter bolt|backsplash panel|range backsplash|countertop support|undermount sink clip|dishwasher bracket)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(
    r'\b(base cabinet|wall cabinet|sink base|drawer base|pantry cabinet|utility cabinet|kitchen cabinet)\b',
  ).hasMatch(text)) {
    if (itemType.contains('base wall')) {
      score += 60;
    } else if (itemName.contains('vanity')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(cabinet filler|filler strip|end panel|toe kick|light rail|cabinet crown|scribe molding)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cabinet panels')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(cabinet filler strip|toe kick board|cabinet end panel)\b',
  ).hasMatch(text)) {
    score -= 34;
  }
  if (RegExp(
    r'\b(vanity|vanity cabinet|vanity top|cultured marble top|quartz vanity|granite vanity|ceramic vanity)\b',
  ).hasMatch(text)) {
    if (itemType.contains('vanity')) {
      score += 58;
    } else if (itemName.contains('kitchen cabinet')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(medicine cabinet|bath storage|linen tower|over toilet cabinet)\b',
  ).hasMatch(text)) {
    if (itemType.contains('medicine')) score += 54;
  }
  if (RegExp(
    r'\b(laminate countertop|countertop|counter top|butcher block|solid surface|worktop|finished edge)\b',
  ).hasMatch(text)) {
    if (itemType.contains('laminate butcher')) {
      score += 58;
    } else if (itemName.contains('backsplash')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(quartz countertop|quartz top|granite top|side splash|end cap kit|miter bolt|seam filler)\b',
  ).hasMatch(text)) {
    if (itemType.contains('stone quartz')) score += 56;
  }
  if (RegExp(
    r'\b(laminate backsplash|peel and stick backsplash|range backsplash|backsplash panel)\b',
  ).hasMatch(text)) {
    if (itemType.contains('backsplash')) {
      score += 54;
    } else if (itemName.contains('tile')) {
      score -= 16;
    }
  }
  if (RegExp(
    r'\b(countertop support|countertop bracket|countertop adhesive|countertop sealant|undermount sink clip|sink rail|dishwasher bracket)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cabinet countertop install')) score += 54;
  }
  for (final size in [
    '3 in',
    '6 in',
    '9 in',
    '12 in',
    '18 in',
    '24 in',
    '30 in',
    '36 in',
    '48 in',
    '4 ft',
    '6 ft',
    '8 ft',
    '10 ft',
    '12 ft',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 22;
    }
  }
  for (final finish in [
    'white shaker',
    'gray shaker',
    'espresso',
    'natural oak',
    'hickory',
    'unfinished',
    'navy shaker',
    'maple',
    'carrara',
    'calacatta',
    'black granite',
    'concrete gray',
    'walnut',
  ]) {
    if (text.contains(finish) && itemName.contains(finish)) score += 18;
  }
  for (final material in [
    'quartz',
    'ceramic',
    'cultured marble',
    'granite',
    'laminate',
    'butcher block',
    'solid surface',
  ]) {
    if (text.contains(material) && itemName.contains(material)) {
      score += 20;
    } else if (text.contains(material) && itemName.contains(' with ')) {
      score -= 10;
    }
  }
  if (RegExp(
    r'\b(cabinet pull|cabinet knob|cabinet hinge|cabinet shim pack|cabinet install screw|drawer slide|lazy susan hardware)\b',
  ).hasMatch(text)) {
    score -= 80;
  }
  if (RegExp(
    r'\b(cabinet paint|paint|roller|nap roller|roller cover|tile|grout|thinset)\b',
  ).hasMatch(text)) {
    score -= 90;
  }
  if (category == 'cabinets countertops detail stock') score += 6;
  return score;
}
