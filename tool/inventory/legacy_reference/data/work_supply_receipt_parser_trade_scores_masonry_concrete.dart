part of 'work_supply_receipt_parser.dart';

int _masonryConcreteReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'masonry and concrete') return score;
  if (RegExp(
    r'\b(concrete|mortar|cement|block|brick|cmu|rebar|remesh|anchor|tapcon|form board|sonotube|paver|patio stone|control joint|backer rod|acid stain|'
    r'weep screed|metal lath|flue liner|refractory mortar|paver restraint|masonry bit|diamond blade)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final normalizedVariant = _normalize(item.variant);
  if (RegExp(
        r'\b(concrete mix|high strength concrete|fast setting concrete|ready mix|quikrete|sakrete)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete')) {
    score += 28;
  }
  if (RegExp(r'\b5000\s*psi\b').hasMatch(text) &&
      normalizedVariant.contains('5000 psi')) {
    score += 42;
  }
  if (RegExp(
        r'\b(fiber reinforced|crack resistant|countertop)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(fiber reinforced|crack resistant|countertop)\b',
      ).hasMatch(normalizedVariant)) {
    score += 36;
  }
  if (RegExp(r'\b(integral concrete color|concrete color)\b').hasMatch(text) &&
      itemType.contains('additive')) {
    score += 34;
  }
  if (RegExp(r'\b(charcoal|buff|red|brown|terra cotta)\b').hasMatch(text) &&
      RegExp(
        r'\b(charcoal|buff|red|brown|terra cotta)\b',
      ).hasMatch(normalizedVariant)) {
    score += 24;
  }
  if (RegExp(
        r'\b(mortar|type n|type s|type m|masonry mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('mortar')) {
    score += 26;
  }
  if (RegExp(r'\btype\s*n\b').hasMatch(text) &&
      normalizedVariant.contains('type n')) {
    score += 34;
  }
  if (RegExp(r'\btype\s*s\b').hasMatch(text) &&
      normalizedVariant.contains('type s')) {
    score += 34;
  }
  if (RegExp(r'\btype\s*m\b').hasMatch(text) &&
      normalizedVariant.contains('type m')) {
    score += 34;
  }
  if (RegExp(
        r'\b(portland cement|masonry cement|hydraulic cement|cement)\b',
      ).hasMatch(text) &&
      item.name.toLowerCase().contains('cement')) {
    score += 24;
  }
  if (RegExp(r'\b(block|cinder block|cmu|brick|fire brick)\b').hasMatch(text) &&
      category == 'masonry materials') {
    score += 26;
  }
  final masonrySize = RegExp(
    r'\b(\d{1,2}\s*x\s*\d{1,2}\s*x\s*\d{1,2})\b',
  ).firstMatch(text);
  if (masonrySize != null &&
      RegExp(r'\b(block|cmu|brick|paver|patio stone)\b').hasMatch(text)) {
    final receiptSize = masonrySize.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedVariant.contains(receiptSize)) {
      score += 34;
    } else if (category == 'masonry materials') {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(rebar|reinforcing bar|remesh|wire mesh|tie wire|rebar chair|dobie)\b',
      ).hasMatch(text) &&
      category == 'reinforcement and forms') {
    score += 26;
  }
  if (RegExp(
        r'\b(form board|form lumber|form stake|expansion joint|sonotube|form tube)\b',
      ).hasMatch(text) &&
      itemType.contains('forming')) {
    score += 24;
  }
  if (RegExp(
        r'\b(wedge anchor|tapcon|concrete screw|masonry screw|sleeve anchor|drop-in anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('anchor')) {
    score += 26;
  }
  if (text.contains('tapcon') &&
      (normalizedVariant.contains('tapcon') ||
          normalizedVariant.contains('concrete screw anchor'))) {
    score += 42;
  }
  if (RegExp(
        r'\b(concrete patch|crack repair|resurfacer|paver sealer|masonry sealer|foundation coating)\b',
      ).hasMatch(text) &&
      itemType.contains('repair')) {
    score += 24;
  }
  if (RegExp(
        r'\b(expansion joint|control joint|zip strip|backer rod|isolation joint)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete joint')) {
    score += 32;
  }
  if (RegExp(r'\b(zip strip|control joint)\b').hasMatch(text) &&
      (normalizedVariant.contains('control joint') ||
          normalizedVariant.contains('zip strip'))) {
    score += 44;
  }
  if (RegExp(
        r'\b(concrete stain|acid stain|concrete dye|concrete color|integral color|stamped concrete release|densifier|wet look sealer)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete stain')) {
    score += 32;
  }
  if (RegExp(
        r'\b(weep screed|stucco bead|corner bead|metal lath|wire lath|stucco netting)\b',
      ).hasMatch(text) &&
      itemType.contains('stucco')) {
    score += 32;
  }
  if (RegExp(
        r'\b(fire brick|flue liner|flue tile|refractory mortar|fireplace mortar|chimney crown|smoke chamber)\b',
      ).hasMatch(text) &&
      itemType.contains('fire brick')) {
    score += 32;
  }
  if (RegExp(
        r'\b(paver|patio stone|wall block|stepping stone|fire pit block)\b',
      ).hasMatch(text) &&
      itemType.contains('pavers')) {
    score += 22;
  }
  if (RegExp(r'\b(holland paver|rectangle paver|wall cap)\b').hasMatch(text) &&
      normalizedVariant.contains(
        RegExp(
              r'\b(holland paver|rectangle paver|wall cap)\b',
            ).firstMatch(text)?.group(1) ??
            '',
      )) {
    score += 32;
  }
  if (RegExp(r'\b(form tube|sonotube)\b').hasMatch(text) &&
      normalizedVariant.contains('form tube')) {
    score += 34;
  }
  final formTubeSize = RegExp(
    r'\b(\d{1,2})\s*in\s*x\s*(\d{2,3})\s*in\b',
  ).firstMatch(text);
  if (formTubeSize != null && normalizedVariant.contains('form tube')) {
    final diameter = '${formTubeSize.group(1)} in';
    final height = '${formTubeSize.group(2)} in';
    if (normalizedVariant.contains(diameter) &&
        normalizedVariant.contains(height)) {
      score += 42;
    } else if (normalizedVariant.contains(diameter)) {
      score += 12;
    }
  }
  if (RegExp(r'\bblue concrete screw\b').hasMatch(text) &&
      normalizedVariant.contains('blue concrete screw')) {
    score += 38;
  }
  if (RegExp(
        r'\b(paver edge|paver restraint|edge restraint|paver spike|permeable paver grid|paver joint|joint stabilizer)\b',
      ).hasMatch(text) &&
      itemType.contains('paver edge')) {
    score += 32;
  }
  if (RegExp(
        r'\b(masonry bit|sds masonry bit|concrete diamond blade|masonry blade|brick chisel|mason line)\b',
      ).hasMatch(text) &&
      itemType.contains('masonry blades')) {
    score += 32;
  }
  if (text.contains('bit set') && itemType.contains('masonry blades')) {
    score -= 28;
  }
  if (RegExp(r'\bsds\s*plus\s*masonry\s*bit\b').hasMatch(text) &&
      normalizedVariant.contains('sds plus masonry bit')) {
    score += 44;
  }
  final masonryBitSize = RegExp(
    r'\b(\d/\d)\s*in\s*(?:sds\s*plus\s*)?masonry\s*bit\b',
  ).firstMatch(text);
  if (masonryBitSize != null &&
      normalizedVariant.contains('${masonryBitSize.group(1)} in') &&
      normalizedVariant.contains('masonry bit')) {
    score += 28;
  }
  if (RegExp(
        r'\b(block adhesive|masonry adhesive|epoxy anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('adhesive')) {
    score += 34;
  }
  if (RegExp(r'\b(mulch|topsoil|sprinkler|drip|irrigation)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

WorkSupplyItem? _directMasonryConcreteAnchorReceiptMatch(
  String text, {
  String? tradeScope,
}) {
  final scopedTrade = tradeScope?.trim().toLowerCase();
  if (scopedTrade != null &&
      scopedTrade.isNotEmpty &&
      scopedTrade != 'masonry and concrete') {
    return null;
  }
  if (!RegExp(r'\b(tapcon|concrete screw|masonry screw)\b').hasMatch(text)) {
    return null;
  }

  final size = _nominalReceiptSize(text);
  final dimensions = _receiptSizeMatrix(text);
  final wantsBlue = RegExp(r'\bblue\b').hasMatch(text);
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(const [
    'concrete',
    'screw',
  ])) {
    if (item.trade != 'Masonry and Concrete') continue;
    final itemText = _normalize('${item.name} ${item.variant}');
    if (wantsBlue && !itemText.contains('blue concrete screw')) continue;
    final itemWithoutInches = itemText
        .replaceAll(' in ', ' ')
        .replaceAll(RegExp(r'\bin\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (dimensions != null && !itemWithoutInches.contains(dimensions)) {
      continue;
    }
    if (dimensions == null &&
        size != null &&
        !_nameMatchesReceiptSize(item.name.toLowerCase(), size) &&
        !_nameMatchesReceiptSize(item.variant.toLowerCase(), size)) {
      continue;
    }
    return item;
  }
  return null;
}
