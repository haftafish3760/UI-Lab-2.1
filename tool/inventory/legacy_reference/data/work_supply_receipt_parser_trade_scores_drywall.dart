part of 'work_supply_receipt_parser.dart';

int _drywallReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'drywall') return score;
  if (RegExp(
    r'\b(drywall|sheetrock|gypsum|joint compound|mud|hot mud|easy sand|corner bead|mesh tape|spackle|access panel|access door|tear away bead|control joint|'
    r'reveal bead|shadow bead|dust barrier|zip door|drywall lift|mud pan|taping knife|texture hopper|pole sander|texture repair|ceiling grid|cross tee|'
    r'main runner|ceiling tile|metal stud|steel stud|metal track|hat channel|resilient channel|hanger wire|rc clip|sound isolation)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  final receiptSaysDrywallBoard = RegExp(
    r'\b(sheetrock|gypsum|wall board|drywall board|drywall sheet|mold resist|moisture resist)\b',
  ).hasMatch(text);
  if (RegExp(r'\b(screw setter|setter bit)\b').hasMatch(text)) {
    score -= 64;
  }
  if (RegExp(r'\b(sheetrock|gypsum|drywall sheet|board)\b').hasMatch(text) &&
      category == 'panels and board') {
    score += 24;
  }
  if (receiptSaysDrywallBoard &&
      (category == 'panels and board' ||
          itemType.contains('board') ||
          itemName.contains('drywall board'))) {
    score += 34;
  }
  if (text.contains('mold resist') && variant.contains('mold resistant')) {
    score += 22;
  }
  if (text.contains('moisture resist') &&
      variant.contains('moisture resistant')) {
    score += 22;
  }
  for (final face in [
    'regular',
    'lightweight',
    'mold resistant',
    'fire rated',
    'type x',
    'abuse resistant',
  ]) {
    final receiptFace = face == 'mold resistant' ? 'mold resist' : face;
    if (text.contains(receiptFace) &&
        (variant.contains(face) || itemName.contains(face))) {
      score += 44;
    } else if (text.contains(receiptFace) &&
        itemName.contains('drywall') &&
        !(variant.contains(face) || itemName.contains(face))) {
      score -= 18;
    }
  }
  if (RegExp(r'\b(joint compound|drywall mud|mud|plus 3)\b').hasMatch(text) &&
      (itemType.contains('joint compound') ||
          itemName.contains('joint compound') ||
          itemName.contains('premixed'))) {
    score += 24;
  }
  if (text.contains('plus 3') && variant.contains('plus 3')) {
    score += 44;
  }
  if (text.contains('plus 3') &&
      itemType.contains('joint compound') &&
      !variant.contains('plus 3')) {
    score -= 12;
  }
  if (RegExp(r'\b(hot mud|easy sand|quick set|setting)\b').hasMatch(text) &&
      itemType.contains('setting')) {
    score += 24;
  }
  if (RegExp(r'\b(corner bead|j bead|edge bead)\b').hasMatch(text) &&
      itemType.contains('bead')) {
    score += 22;
  }
  if (RegExp(
        r'\b(access panel|access door|fire rated access|tear away bead|tearaway bead|control joint|no coat|shadow bead|reveal bead|expansion bead|bullnose adapter)\b',
      ).hasMatch(text) &&
      itemType.contains('access panels')) {
    score += 28;
  }
  if (RegExp(
        r'\b(reveal bead|expansion bead|bullnose adapter|splayed corner|three-way corner|outside corner cap)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall reveal')) {
    score += 34;
  }
  for (final bead in [
    'shadow bead',
    'reveal bead',
    'control joint',
    'tear away bead',
    'j bead',
    'l bead',
    'bullnose corner bead',
  ]) {
    if (text.contains(bead) &&
        (variant.contains(bead) || itemName.contains(bead))) {
      score += 62;
    } else if (text.contains(bead) &&
        itemName.contains('bead') &&
        !(variant.contains(bead) || itemName.contains(bead))) {
      score -= 22;
    }
  }
  if (RegExp(r'\b(concrete|slab|masonry|zip strip)\b').hasMatch(text) &&
      text.contains('control joint') &&
      trade == 'drywall') {
    score -= 70;
  }
  if (text.contains('shadow bead')) {
    if (itemName.contains('shadow bead')) {
      score += 110;
    }
    if (itemName.contains('reveal bead') ||
        itemName.contains('control joint') ||
        itemName.contains('tear away bead')) {
      score -= 90;
    }
  }
  if (RegExp(
    r'\b(bullnose three-way corner cap|bullnose outside corner cap|bullnose adapter|reveal bead)\b',
  ).hasMatch(text)) {
    if (itemName.contains('bullnose') ||
        itemName.contains('reveal bead') ||
        itemType.contains('drywall reveal')) {
      score += 70;
    }
  }
  if (RegExp(
        r'\b(access door|fire rated access panel|flush access panel)\b',
      ).hasMatch(text) &&
      itemType.contains('access doors')) {
    score += 34;
  }
  if (RegExp(r'\b(joint tape|mesh tape|paper tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 34;
  }
  if (RegExp(r'\b(spackle|patch|wall repair)\b').hasMatch(text) &&
      itemType.contains('patch')) {
    score += 20;
  }
  if (RegExp(r'\b(drywall|sheetrock|gypsum)\s+screws?\b').hasMatch(text) &&
      (itemType.contains('screw') || itemName.contains('screw'))) {
    score += 64;
  }
  if (RegExp(
        r'\b(dust barrier|zip door|floor protection|dust collection|cleanup sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('dust control')) {
    score += 26;
  }
  if (RegExp(
        r'\b(drywall lift|panel hoist|mud pan|taping knife|joint knife|texture hopper|hopper gun|drywall rasp|jab saw)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall hanging')) {
    score += 28;
  }
  if (RegExp(
        r'\b(texture hopper nozzle|texture hopper nozzle kit)\b',
      ).hasMatch(text) &&
      itemName.contains('texture hopper nozzle')) {
    score += 72;
  }
  if (RegExp(
        r'\b(pole sander|hand sander|dustless sanding|sanding disc|vacuum bag|dust extractor)\b',
      ).hasMatch(text) &&
      itemType.contains('drywall sanding')) {
    score += 34;
  }
  if (RegExp(
        r'\b(texture hopper nozzle|texture nozzle|texture repair|popcorn scraper|ceiling patch|texture pattern sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('texture sprayer')) {
    score += 34;
  }
  if (RegExp(r'\b(orange peel|knockdown|popcorn)\b').hasMatch(text) &&
      itemName.contains('texture')) {
    score += 24;
  }
  for (final texture in ['orange peel', 'knockdown', 'popcorn']) {
    if (text.contains(texture) && itemName.contains(texture)) {
      score += 44;
    }
  }
  for (final package in ['premixed', 'aerosol', 'powder mix']) {
    if (text.contains(package) && itemName.contains(package)) {
      score += 58;
    } else if (text.contains(package) &&
        itemName.contains('texture') &&
        !itemName.contains(package)) {
      score -= 36;
    }
  }
  if (RegExp(
        r'\b(ceiling grid|cross tee|main runner|wall angle|acoustic ceiling tile|hold down clip|grid repair clip)\b',
      ).hasMatch(text) &&
      itemType.contains('drop ceiling')) {
    score += 34;
  }
  for (final gridTerm in ['main runner', 'cross tee', 'wall angle']) {
    if (text.contains(gridTerm) && itemName.contains(gridTerm)) {
      score += 48;
    }
  }
  for (final color in ['black', 'white']) {
    if (text.contains(color) && itemName.contains(color)) {
      score += 40;
    } else if (text.contains(color) &&
        (itemName.contains('main runner') ||
            itemName.contains('cross tee') ||
            itemName.contains('wall angle')) &&
        !itemName.contains(color)) {
      score -= 36;
    }
  }
  if (RegExp(
        r'\b(metal stud|steel stud|drywall stud|metal track|steel track|hat channel|furring channel|resilient channel|rc channel|z furring)\b',
      ).hasMatch(text) &&
      itemType.contains('metal studs')) {
    score += 34;
  }
  if (RegExp(
        r'\b(ceiling wire|hanger wire|tie wire|sound isolation clip|rc clip|sound sealant|putty pad)\b',
      ).hasMatch(text) &&
      itemType.contains('ceiling grid')) {
    score += 34;
  }
  if (RegExp(
        r'\b(pan head screw|wafer head screw|metal stud screw|stud crimper|track fastener|deflection track|stud bushing)\b',
      ).hasMatch(text) &&
      itemType.contains('metal framing fasteners')) {
    score += 34;
  }
  for (final term in [
    'metal stud',
    'metal track',
    'hat channel',
    'resilient channel',
    'hanger wire',
    'sound isolation',
    'pan head',
    'wafer head',
    'stud crimper',
    'z furring',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  if (text.contains('z furring')) {
    if (itemName.contains('z furring')) {
      score += 100;
    }
    if (itemName.contains('hat channel') ||
        itemName.contains('resilient channel')) {
      score -= 70;
    }
  }
  if (text.contains('paint') && trade == 'drywall') score -= 12;
  return score;
}
