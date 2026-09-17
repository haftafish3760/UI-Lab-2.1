part of 'work_supply_receipt_parser.dart';

int _paintingReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'painting') return score;
  if (RegExp(
    r'\b(paint|primer|roller|brush|painter tape|masking tape|caulk|spackle|drop cloth|tray|stain|polyurethane|polycrylic|spray tip|paint sprayer|'
    r'masking machine|paint stripper|deglosser|lead paint|color sample|paint sample|epoxy coating|concrete etcher|garage floor cleaner|rust converter|'
    r'elastomeric sealant|big stretch|backer rod|sprayer filter|pre taped masking film|paint hardener)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  if (RegExp(r'\b(interior paint|wall paint|latex paint)\b').hasMatch(text) &&
      itemType.contains('interior paint')) {
    score += 24;
  }
  if (RegExp(r'\b(exterior paint|outside paint)\b').hasMatch(text) &&
      itemType.contains('exterior paint')) {
    score += 24;
  }
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (text.contains('cabinet') &&
      (variant.contains('cabinet') || itemName.contains('cabinet'))) {
    score += 36;
  }
  if (text.contains('cabinet') &&
      itemName.contains('paint') &&
      !variant.contains('cabinet') &&
      !itemName.contains('cabinet')) {
    score -= 14;
  }
  if (text.contains('ceiling') &&
      (variant.contains('ceiling') || itemName.contains('ceiling'))) {
    score += 26;
  }
  if (text.contains('trim') &&
      (variant.contains('trim') || itemName.contains('trim'))) {
    score += 26;
  }
  if (RegExp(r'\b(primer|stain blocker|bonding primer)\b').hasMatch(text) &&
      itemType.contains('primer')) {
    score += 24;
  }
  for (final primer in [
    'drywall primer',
    'stain blocking primer',
    'bonding primer',
    'masonry primer',
    'metal primer',
    'shellac primer',
    'oil based primer',
  ]) {
    if (text.contains(primer) &&
        (variant.contains(primer) || itemName.contains(primer))) {
      score += 68;
    } else if (text.contains(primer) &&
        itemName.contains('primer') &&
        !(variant.contains(primer) || itemName.contains(primer))) {
      score -= 28;
    }
  }
  if (RegExp(
        r'\b(wood stain|deck stain|fence stain|gel stain|polyurethane|polycrylic|spar urethane|shellac|lacquer|spray paint|high heat paint|appliance epoxy)\b',
      ).hasMatch(text) &&
      itemType.contains('stains clear')) {
    score += 28;
  }
  for (final term in [
    'deck stain',
    'fence stain',
    'gel stain',
    'polyurethane',
    'polycrylic',
    'spar urethane',
    'shellac',
    'lacquer',
    'high heat',
    'appliance epoxy',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 48;
  }
  if (text.contains('satin') && variant.contains('satin')) score += 18;
  if (text.contains('gloss') && variant.contains('gloss')) score += 18;
  if (RegExp(
        r'\b(floor paint|garage floor paint|epoxy coating|waterproofing paint|masonry waterproofing|rust preventive|chalkboard paint|dry erase paint)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty coatings')) {
    score += 28;
  }
  if (RegExp(
        r'\b(concrete etcher|garage floor cleaner|floor degreaser|rust converter|rust reformer|anti skid additive|floor coating roller)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete garage')) {
    score += 34;
  }
  for (final term in [
    'porch and patio',
    'garage floor',
    'epoxy coating',
    'waterproofing paint',
    'masonry waterproofing',
    'rust preventive',
    'chalkboard',
    'dry erase',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 44;
  }
  if (RegExp(r'\b(roller cover|roller sleeve|paint roller)\b').hasMatch(text) &&
      itemType.contains('roller')) {
    score += 22;
  }
  if (RegExp(
        r'\b(nap roller|roller\s+\d+\s*pk|3/8\s+nap|1/2\s+nap)\b',
      ).hasMatch(text) &&
      itemType.contains('roller')) {
    score += 70;
  }
  if (RegExp(
        r'\b(extension pole|paint pole|spray tip|airless tip|tip guard|paint sprayer|sprayer hose|pump armor|masking machine|hand masker)\b',
      ).hasMatch(text) &&
      itemType.contains('sprayers')) {
    score += 26;
  }
  if (RegExp(
        r'\b(airless tip|spray gun filter|gun filter|sprayer filter|tip guard|sprayer pump repair|inlet strainer|manifold filter|storage fluid)\b',
      ).hasMatch(text) &&
      itemType.contains('sprayer tips')) {
    score += 34;
  }
  for (final mesh in ['60 mesh', '100 mesh', '200 mesh']) {
    if (text.contains(mesh) && itemName.contains(mesh)) {
      score += 66;
    } else if (text.contains(mesh) &&
        itemName.contains('spray gun filter') &&
        !itemName.contains(mesh)) {
      score -= 32;
    }
  }
  if (RegExp(r'\b(painter tape|masking tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 22;
  }
  if (text.contains('delicate') &&
      (variant.contains('delicate') || itemName.contains('delicate'))) {
    score += 34;
  }
  if (text.contains('exterior') &&
      (variant.contains('exterior') || itemName.contains('exterior'))) {
    score += 18;
  }
  if (text.contains('general purpose') &&
      (variant.contains('general purpose') ||
          itemName.contains('general purpose'))) {
    score += 18;
  }
  if (RegExp(
        r'\b(paintable caulk|painter caulk|acrylic caulk)\b',
      ).hasMatch(text) &&
      itemType.contains('caulk')) {
    score += 22;
  }
  if (RegExp(
        r'\b(elastomeric sealant|big stretch|paintable silicone|backer rod|caulk finishing tool|caulk tool|caulk saver)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty painter sealants')) {
    score += 34;
  }
  if (RegExp(
        r'\b(paint stripper|paint remover|adhesive remover|deglosser|lead paint test|lead test kit|deck cleaner|concrete etcher)\b',
      ).hasMatch(text) &&
      itemType.contains('paint removers')) {
    score += 26;
  }
  for (final term in [
    'paint stripper',
    'paint remover',
    'adhesive remover',
    'deglosser',
    'deck cleaner',
    'concrete etcher',
    'lead paint test',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 48;
  }
  if (RegExp(
        r'\b(paint sample|color sample|colorant|fan deck|paint suit|spray sock|paint hardener|paint disposal)\b',
      ).hasMatch(text) &&
      itemType.contains('painter safety')) {
    score += 24;
  }
  if (RegExp(
        r'\b(pre taped masking film|pre-taped masking film|canvas drop cloth|paint hardener|paint disposal|waste label|pour spout|paint can clip)\b',
      ).hasMatch(text) &&
      itemType.contains('masking film')) {
    score += 34;
  }
  if (RegExp(r'\b(angle brush|paint brush)\b').hasMatch(text) &&
      itemType.contains('brush')) {
    score += 22;
  }
  for (final term in [
    'garage floor cleaner',
    'rust converter',
    'anti-skid',
    'elastomeric',
    'big stretch',
    'paintable silicone',
    'backer rod',
    'spray gun filter',
    'pump repair',
    'pre-taped',
    'paint hardener',
    'paint disposal',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (category == 'paint' && text.contains('drywall screw')) score -= 20;
  return score;
}
