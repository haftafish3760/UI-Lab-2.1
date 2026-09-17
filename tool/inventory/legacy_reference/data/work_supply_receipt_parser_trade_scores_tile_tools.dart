part of 'work_supply_receipt_parser.dart';

int _tileToolsCleanupReceiptScore(_TileReceiptScoreContext context) {
  var score = 0;
  final text = context.text;
  final itemType = context.itemType;
  final itemName = context.itemName;
  final item = context.item;

  if (RegExp(
        r'\b(tile leveling cap|reusable leveling cap|porcelain diamond blade|glass tile blade|epoxy grout float|grout release|grout sealer applicator|carbide grout removal blade|tile hole saw)\b',
      ).hasMatch(text) &&
      itemType.contains('tile tools cleanup')) {
    score += 44;
  }
  if (RegExp(
    r'\b(porcelain diamond blade|glass tile blade)\b',
  ).hasMatch(text)) {
    if (itemName.contains('porcelain diamond blade') ||
        itemName.contains('glass tile blade')) {
      score += 64;
    } else if (itemName.contains('diamond blade')) {
      score -= 10;
    }
  }
  if (RegExp(
    r'\b(tile hole saw|diamond tile hole saw|porcelain hole saw|glass tile drill bit|diamond core bit|core bit)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hole saw') ||
        itemName.contains('drill bit') ||
        itemName.contains('core bit')) {
      score += 70;
    } else if (itemName.contains('blade')) {
      score -= 34;
    }
    for (final toolType in [
      'diamond tile hole saw',
      'porcelain hole saw',
      'glass tile drill bit',
      'diamond core bit',
    ]) {
      if (text.contains(toolType) && itemName.contains(toolType)) {
        score += 74;
      } else if (text.contains(toolType) &&
          (itemName.contains('hole saw') ||
              itemName.contains('drill bit') ||
              itemName.contains('core bit')) &&
          !itemName.contains(toolType)) {
        score -= 28;
      }
    }
    for (final size in [
      '1/4 in',
      '5/16 in',
      '3/8 in',
      '1/2 in',
      '5/8 in',
      '3/4 in',
      '1 in',
      '1-1/4 in',
      '1-3/8 in',
      '2 in',
    ]) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 46;
        } else if (itemName.contains('hole saw') ||
            itemName.contains('drill bit') ||
            itemName.contains('core bit')) {
          score -= 18;
        }
      }
    }
  }
  if (RegExp(
    r'\b(leveling clip|tile leveling clip|leveling clips)\b',
  ).hasMatch(text)) {
    if (item.name.toLowerCase().contains('leveling clip')) {
      score += 30;
    } else if (item.name.toLowerCase().contains('spacer')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(trowel|diamond blade|grout float|tile sponge)\b',
      ).hasMatch(text) &&
      itemType.contains('trowel')) {
    score += 18;
  }
  if (RegExp(r'\b(trowel|notched trowel|notch trowel)\b').hasMatch(text)) {
    if (itemName.contains('trowel')) {
      score += 38;
    }
    for (final notch in [
      '1/8 x 1/8 in',
      '3/16 x 5/32 in',
      '1/4 x 1/4 in',
      '1/4 x 3/8 in',
      '1/2 x 1/2 in',
      '3/4 x 9/16 in',
    ]) {
      if (_tileReceiptMentionsSize(text, notch)) {
        if (itemName.contains(notch)) {
          score += 46;
        } else if (itemName.contains('trowel')) {
          score -= 16;
        }
      }
    }
    if (text.contains('stainless') && itemName.contains('stainless')) {
      score += 24;
    }
  }
  if (RegExp(
    r'\b(cement backer board|fiber cement backer board|foam tile backer|waterproof tile board|backer board screw|mesh tape|liquid waterproofing)\b',
  ).hasMatch(text)) {
    if (itemType.contains('cement foam') ||
        itemName.contains('backer board') ||
        itemName.contains('tile board') ||
        itemName.contains('mesh tape')) {
      score += 44;
    }
  }
  for (final term in [
    'cement backer board',
    'fiber cement backer board',
    'foam tile backer board',
    'waterproof tile board',
  ]) {
    if (text.contains(term) && itemName.contains(term)) {
      score += 58;
    } else if (text.contains(term) &&
        itemType.contains('cement foam') &&
        !itemName.contains(term)) {
      score -= 18;
    }
  }
  if (RegExp(
    r'\b(self leveling underlayment|self leveling primer|tile bonding primer|porous surface primer|non porous surface primer|waterproofing primer|'
    r'floor patch|feather finish|rapid set floor patch|anti fracture membrane|crack isolation membrane|uncoupling membrane|peel and stick tile membrane)\b',
  ).hasMatch(text)) {
    if (itemType.contains('self leveling') ||
        itemName.contains('self leveling') ||
        itemName.contains('primer') ||
        itemName.contains('floor patch') ||
        itemName.contains('anti fracture') ||
        itemName.contains('crack isolation') ||
        itemName.contains('uncoupling membrane')) {
      score += 48;
    }
    for (final term in [
      'tile bonding primer',
      'self leveling primer',
      'porous surface primer',
      'non porous surface primer',
      'waterproofing primer',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 64;
      } else if (text.contains(term) &&
          itemName.contains('primer') &&
          !itemName.contains(term)) {
        score -= 22;
      }
    }
    for (final size in ['1 qt', '1 gal', '2 gal', '3.5 gal', '5 gal']) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 32;
        } else if (itemName.contains('primer') ||
            itemName.contains('additive')) {
          score -= 12;
        }
      }
    }
  }
  if (RegExp(
        r'\b(grout caulk|tile caulk|ceramic tile caulk|grout colorant|grout haze remover|haze remover|grout release|stone cleaner|tile sealer|stone enhancer|natural stone sealer|stone sealer)\b',
      ).hasMatch(text) &&
      itemType.contains('grout caulk')) {
    score += 28;
  }
  if (RegExp(
    r'\b(grout release|grout haze remover|heavy duty grout cleaner|stone cleaner|tile sealer|stone enhancer|natural stone sealer|stone sealer)\b',
  ).hasMatch(text)) {
    if (itemName.contains('grout release') ||
        itemName.contains('haze remover') ||
        itemName.contains('stone cleaner') ||
        itemName.contains('tile sealer') ||
        itemName.contains('stone enhancer') ||
        itemName.contains('natural stone sealer')) {
      score += 46;
    }
    for (final term in [
      'grout release',
      'grout haze remover',
      'heavy duty grout cleaner',
      'stone cleaner',
      'tile sealer',
      'stone enhancer',
      'natural stone sealer',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 64;
      } else if (text.contains(term) &&
          (itemName.contains('sealer') ||
              itemName.contains('cleaner') ||
              itemName.contains('grout')) &&
          !itemName.contains(term)) {
        score -= 18;
      }
    }
    for (final size in ['1 qt', '1 gal']) {
      if (_tileReceiptMentionsSize(text, size)) {
        if (itemName.contains(size)) {
          score += 32;
        } else if (itemName.contains('sealer') ||
            itemName.contains('cleaner')) {
          score -= 10;
        }
      }
    }
  }
  return score;
}
