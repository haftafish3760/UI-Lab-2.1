part of 'work_supply_receipt_parser.dart';

int _tileReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'tile') return score;
  if (RegExp(r'\b(duct mastic|duct sealant|hvac mastic)\b').hasMatch(text)) {
    return -90;
  }
  if (RegExp(
    r'\b(tile|porcelain|ceramic|thinset|thin set|grout|mastic|membrane|backer board|cement board|spacer|leveling clip|linear drain|shower curb|shower bench|'
    r'corner shelf|seam tape|backer screw|marble threshold|grout caulk|grout haze|glass tile|bullnose|cove base|pencil liner|crack isolation|anti fracture|'
    r'antifracture|membrane primer|floor heat|heated floor|drain grate|tileable drain|tile-in drain)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(ceramic|porcelain|mosaic|stone tile)\b').hasMatch(text) &&
      category == 'tile materials') {
    score += 24;
  }
  if (RegExp(
    r'\b(bathroom|shower|backsplash|kitchen|floor tile|entry tile|porcelain|ceramic|glass|quarry|stone look|subway|pickett|arabesque|herringbone|penny round|ledger panel|travertine|slate|limestone|granite|marble)\b',
  ).hasMatch(text)) {
    if (itemType.contains('bathroom') ||
        itemType.contains('kitchen') ||
        itemType.contains('floor') ||
        itemType.contains('natural stone')) {
      score += 34;
    }
  }
  for (final term in [
    'porcelain',
    'ceramic',
    'glass',
    'quarry',
    'marble',
    'travertine',
    'slate',
    'limestone',
    'granite',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 34;
    } else if (text.contains(term) &&
        (itemType.contains('bathroom') ||
            itemType.contains('kitchen') ||
            itemType.contains('floor') ||
            itemType.contains('natural stone')) &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  for (final term in [
    'white',
    'warm white',
    'gray',
    'charcoal',
    'black',
    'blue',
    'green',
    'sage',
    'red',
    'brown',
    'tan',
    'adobe',
    'sand',
    'carrara',
    'travertine',
    'slate',
    'beige',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 16;
  }
  for (final term in [
    'textured',
    'matte',
    'gloss',
    'polished',
    'honed',
    'tumbled',
    'split face',
    'anti slip',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 20;
  }
  for (final term in [
    'subway',
    'pickett',
    'arabesque',
    'herringbone',
    'hex mosaic',
    'penny round',
    'basketweave',
    'lantern',
    'chevron',
    'pebble',
    'linear mosaic',
    'mosaic sheet',
    'ledger panel',
    'plank',
    'backsplash',
    'floor tile',
    'rectified',
    'stone look',
    'paver tile',
    'quarry tile',
    'saltillo',
    'terracotta',
    'tread tile',
  ]) {
    if (text.contains(term) && itemName.contains(term)) score += 24;
  }
  for (final size in [
    '3 x 6',
    '4 x 12',
    '6 x 6',
    '6 x 24',
    '8 x 36',
    '8 x 48',
    '12 x 12',
    '12 x 24',
    '16 x 16',
    '16 x 32',
    '18 x 18',
    '18 x 36',
    '24 x 24',
    '24 x 48',
    '30 x 30',
  ]) {
    final compact = size.replaceAll(' ', '');
    if ((text.contains(size) || text.contains(compact)) &&
        itemName.contains('$size in')) {
      score += 30;
    }
  }
  if (RegExp(
        r'\b(glass tile|glass mosaic|bullnose tile|bullnose trim|cove base tile|tile cove base|pencil liner|tile pencil|accent tile)\b',
      ).hasMatch(text) &&
      itemType.contains('glass decorative')) {
    score += 34;
  }
  if (RegExp(r'\b(bullnose|cove base|pencil liner)\b').hasMatch(text)) {
    if (itemName.contains('bullnose') ||
        itemName.contains('cove base') ||
        itemName.contains('pencil liner')) {
      score += 54;
    } else if (category == 'tile materials') {
      score -= 10;
    }
  }
  if (text.contains('bullnose') &&
      !RegExp(r'\b(tile|trim|schluter|ceramic|porcelain)\b').hasMatch(text) &&
      trade == 'tile') {
    score -= 36;
  }
  if (text.contains('matte') &&
      (variant.contains('matte') || itemName.contains('matte'))) {
    score += 34;
  }
  if (text.contains('polished') &&
      (variant.contains('polished') || itemName.contains('polished'))) {
    score += 30;
  }
  if (text.contains('glazed') &&
      (variant.contains('glazed') || itemName.contains('glazed'))) {
    score += 24;
  }
  if (text.contains('matte') &&
      itemName.contains('porcelain') &&
      !variant.contains('matte')) {
    score -= 12;
  }
  if (RegExp(
        r'\b(thinset|thin set|modified mortar|large format mortar|lft mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('thinset')) {
    score += 28;
  }
  if (RegExp(r'\blft\b').hasMatch(text) &&
      (variant.contains('lft') || itemName.contains('lft'))) {
    score += 34;
  }
  if (RegExp(r'\blft\b').hasMatch(text) &&
      itemName.contains('mortar') &&
      !variant.contains('lft') &&
      !itemName.contains('lft')) {
    score -= 12;
  }
  if (RegExp(r'\b(mastic|tile adhesive)\b').hasMatch(text) &&
      itemType.contains('adhesive')) {
    score += 24;
  }
  if (RegExp(
        r'\b(glass tile mortar|rapid setting mortar|rapid set mortar)\b',
      ).hasMatch(text) &&
      itemType.contains('advanced mortar')) {
    score += 44;
  }
  if (RegExp(r'\b(grout|sanded grout|unsanded grout)\b').hasMatch(text) &&
      itemType.contains('grout')) {
    score += 26;
  }
  for (final unit in ['1 qt', '1 gal', '10 lb', '25 lb']) {
    final compact = unit.replaceAll(' ', '');
    if (text.contains(unit) || text.contains(compact)) {
      if (itemName.contains(unit)) {
        score += 34;
      } else if (itemName.contains('grout')) {
        score -= 10;
      }
    }
  }
  if (RegExp(
        r'\b(epoxy grout|urethane grout|high performance grout|premixed grout)\b',
      ).hasMatch(text) &&
      itemType.contains('advanced mortar')) {
    score += 44;
  }
  if (RegExp(r'\burethane grout\b').hasMatch(text)) {
    if (itemName.contains('urethane grout')) {
      score += 68;
    } else if (itemName.contains('grout')) {
      score -= 10;
    }
  }
  final context = _TileReceiptScoreContext(
    text: text,
    trade: trade,
    itemType: itemType,
    itemName: itemName,
    category: category,
    variant: variant,
    item: item,
  );
  score += _tileWaterproofingProfileReceiptScore(context);
  score += _tileToolsCleanupReceiptScore(context);
  if (RegExp(r'\b(shingle|roof|gutter|drip edge)\b').hasMatch(text)) {
    score -= 18;
  }
  return score;
}

class _TileReceiptScoreContext {
  const _TileReceiptScoreContext({
    required this.text,
    required this.trade,
    required this.itemType,
    required this.itemName,
    required this.category,
    required this.variant,
    required this.item,
  });

  final String text;
  final String trade;
  final String itemType;
  final String itemName;
  final String category;
  final String variant;
  final WorkSupplyItem item;
}

bool _tileReceiptMentionsSize(String text, String size) {
  final normalizedSize = _normalize(size);
  final compactNoSpace = normalizedSize.replaceAll(' ', '');
  final bareInch = normalizedSize.replaceFirst(RegExp(r'\s+in$'), '');
  final xCompact = normalizedSize.replaceAll(' x ', 'x');
  final xBare = bareInch.replaceAll(' x ', 'x');
  return text.contains(normalizedSize) ||
      text.contains(compactNoSpace) ||
      text.contains(bareInch) ||
      text.contains(xCompact) ||
      text.contains(xBare);
}
