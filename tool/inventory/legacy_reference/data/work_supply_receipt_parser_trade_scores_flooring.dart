part of 'work_supply_receipt_parser.dart';

int _flooringReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'flooring') return score;
  if (RegExp(
    r'\b(lvp|lvt|vinyl plank|vinyl tile|luxury vinyl|rigid core|spc|wpc|laminate|hardwood|engineered hardwood|flooring|floating floor|sheet vinyl|'
    r'peel stick|peel and stick|carpet|carpet tile|carpet pad|tack strip|floor underlayment|moisture barrier|vapor barrier|floor leveler|self leveler|'
    r'floor patch|transition strip|t molding|reducer|end cap|threshold|quarter round|shoe molding|stair nose|floor adhesive|floor spacer|pull bar|tapping block|floor cleat|floor staple)\b',
  ).hasMatch(text)) {
    score += 18;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(lvp|vinyl plank|luxury vinyl plank)\b').hasMatch(text)) {
    if (itemType.contains('luxury vinyl')) {
      score += 60;
    } else if (itemName.contains('sheet vinyl') ||
        itemName.contains('peel and stick')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(lvt|vinyl tile|luxury vinyl tile)\b').hasMatch(text)) {
    if (itemType.contains('luxury vinyl') && itemName.contains('tile')) {
      score += 60;
    } else if (itemName.contains('plank')) {
      score -= 12;
    }
  }
  for (final term in ['spc', 'wpc', 'rigid core', 'waterproof']) {
    if (text.contains(term) && itemName.contains(term)) score += 34;
  }
  if (RegExp(r'\b(laminate|floating floor)\b').hasMatch(text)) {
    if (itemType.contains('laminate')) {
      score += 54;
    } else if (itemName.contains('vinyl') || itemName.contains('hardwood')) {
      score -= 14;
    }
  }
  if (RegExp(
    r'\b(hardwood|engineered hardwood|wood flooring)\b',
  ).hasMatch(text)) {
    if (itemType.contains('hardwood')) {
      score += 54;
    } else if (itemName.contains('laminate') || itemName.contains('vinyl')) {
      score -= 14;
    }
  }
  for (final species in [
    'oak',
    'red oak',
    'white oak',
    'maple',
    'hickory',
    'birch',
    'bamboo',
    'walnut',
    'acacia',
  ]) {
    if (text.contains(species) && itemName.contains(species)) score += 22;
  }
  if (RegExp(r'\b(sheet vinyl|vinyl roll)\b').hasMatch(text)) {
    if (itemType.contains('sheet vinyl')) {
      score += 54;
    } else if (itemName.contains('lvp') || itemName.contains('lvt')) {
      score -= 16;
    }
  }
  if (RegExp(r'\b(peel stick|peel and stick|self stick)\b').hasMatch(text)) {
    if (itemType.contains('sheet vinyl') &&
        itemName.contains('peel and stick')) {
      score += 58;
    } else if (itemName.contains('sheet vinyl roll')) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(carpet|berber|plush|frieze)\b').hasMatch(text)) {
    if (itemType.contains('carpet') && !itemName.contains('carpet pad')) {
      score += 50;
    }
  }
  if (RegExp(
    r'\b(carpet pad|tack strip|seam tape|binder bar)\b',
  ).hasMatch(text)) {
    if (itemType.contains('carpet pad')) {
      score += 56;
    } else if (itemName.contains('carpet flooring')) {
      score -= 16;
    }
  }
  if (RegExp(
        r'\b(floor underlayment|foam underlayment|cork underlayment|moisture barrier|vapor barrier|sound control underlayment|plywood underlayment)\b',
      ).hasMatch(text) &&
      itemType.contains('underlayment')) {
    score += 54;
  }
  if (RegExp(
        r'\b(self leveler|self leveling|floor leveler|floor patch|feather finish|leveler primer|floor primer|adhesive remover)\b',
      ).hasMatch(text) &&
      itemType.contains('leveler')) {
    score += 54;
  }
  if (RegExp(
    r'\b(t molding|t-molding|transition strip|reducer|end cap|threshold|quarter round|shoe molding|stair nose|metal transition)\b',
  ).hasMatch(text)) {
    if (itemType.contains('transition')) {
      score += 58;
    } else if (itemName.contains('plank') || itemName.contains('tile')) {
      score -= 14;
    }
  }
  if (RegExp(r'\bstair nose\b').hasMatch(text)) {
    if (itemName.contains('stair nose')) {
      score += 46;
    } else if (itemName.contains('threshold')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(floor adhesive|vinyl adhesive|wood flooring adhesive|carpet adhesive|pressure sensitive adhesive)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesives')) {
    score += 54;
  }
  if (RegExp(
        r'\b(flooring installation kit|pull bar|tapping block|floor spacers|floor cleat|floor staple|floor repair|seam roller|floor cutter)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesives')) {
    score += 46;
  }
  for (final size in [
    '4 mm',
    '5 mm',
    '6 mm',
    '7 mm',
    '8 mm',
    '10 mm',
    '12 mm',
    '12 x 12',
    '12 x 24',
    '18 x 18',
    '24 x 24',
    '6 x 36',
    '7 x 48',
    '72 in',
    '78 in',
    '94 in',
  ]) {
    if (_tileReceiptMentionsSize(text, size) &&
        (itemName.contains(size) || variant.contains(size))) {
      score += 26;
    }
  }
  for (final color in [
    'oak',
    'gray',
    'walnut',
    'hickory',
    'maple',
    'barnwood',
    'espresso',
    'chestnut',
    'carrara',
    'slate',
    'travertine',
    'beige',
    'taupe',
    'charcoal',
    'brown',
  ]) {
    if (text.contains(color) && itemName.contains(color)) score += 14;
  }
  if (RegExp(
    r'\b(thinset|grout|backer board|cement board|shower)\b',
  ).hasMatch(text)) {
    score -= 26;
  }
  if (RegExp(
    r'\b(floor paint|garage floor epoxy|porch paint)\b',
  ).hasMatch(text)) {
    score -= 24;
  }
  if (RegExp(
    r'\b(project panel|stair tread|handrail bracket|stair riser|baluster)\b',
  ).hasMatch(text)) {
    score -= 48;
  }
  if (RegExp(r'\b(roof|roofing|gutter|drip edge)\b').hasMatch(text)) {
    score -= 60;
  }
  if (RegExp(r'\b(thhn|awg|romex|nm-b|nmb|building wire)\b').hasMatch(text)) {
    score -= 90;
  }
  if (category == 'flooring detail stock') score += 6;
  return score;
}
