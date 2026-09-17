part of 'work_supply_receipt_parser.dart';

int _insulationReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'insulation') return score;
  if (RegExp(
    r'\b(insulation|batt|fiberglass|mineral wool|rock wool|foam board|spray foam|loose fill|vapor barrier|house wrap|r-\d{2}|pipe insulation|weatherstrip|'
    r'radiant barrier|water heater blanket|garage door insulation|acoustic sealant|sound panel|mass loaded vinyl|crawlspace liner|crawl space liner|'
    r'crawlspace seam tape|termination bar|drainage mat|firestop collar|fire stop collar|firestop sealant|draft stop|putty pad|sound control batt|'
    r'acoustic board|sound isolation clip|rafter vent|soffit baffle|attic vent chute|can light cover|foam gasket|insulation netting|cap nail|impaling clip|firestop wrap|sound isolation track)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = item.variant.toLowerCase();
  if (RegExp(r'\b(r-\d{2}|batt|fiberglass batt|attic batt)\b').hasMatch(text) &&
      itemType.contains('batt')) {
    score += 28;
  }
  if (text.contains('kraft') && variant.contains('kraft')) score += 24;
  if (text.contains('unfaced') && variant.contains('unfaced')) score += 24;
  if (text.contains('foil') && variant.contains('foil')) score += 22;
  if (RegExp(
        r'\b(mineral wool|rock wool|sound batt|fire batt)\b',
      ).hasMatch(text) &&
      itemType.contains('mineral')) {
    score += 26;
  }
  if (RegExp(r'\b(foam board|rigid insulation|xps|polyiso)\b').hasMatch(text) &&
      itemType.contains('foam board')) {
    score += 26;
  }
  if (text.contains('polyiso') &&
      (variant.contains('polyiso') || itemName.contains('polyiso'))) {
    score += 34;
  }
  if (text.contains('xps') &&
      (variant.contains('xps') || itemName.contains('xps'))) {
    score += 28;
  }
  if (text.contains('r tech') &&
      (variant.contains('r-tech') || itemName.contains('r-tech'))) {
    score += 28;
  }
  if (RegExp(
        r'\b(spray foam|expanding foam|foam sealant|fire block foam)\b',
      ).hasMatch(text) &&
      itemType.contains('spray foam')) {
    score += 26;
  }
  if (RegExp(r'\b(fireblock|fire block)\b').hasMatch(text) &&
      (variant.contains('fire block') ||
          variant.contains('fireblock') ||
          itemName.contains('fire block') ||
          itemName.contains('fireblock'))) {
    score += 40;
  }
  if (RegExp(r'\b(fireblock|fire block)\b').hasMatch(text) &&
      itemName.contains('spray foam') &&
      !variant.contains('fire block') &&
      !variant.contains('fireblock')) {
    score -= 14;
  }
  if (RegExp(r'\b(blown insulation|loose fill|cellulose)\b').hasMatch(text) &&
      itemType.contains('loose fill')) {
    score += 24;
  }
  if (text.contains('cellulose')) {
    if (item.name.toLowerCase().contains('cellulose')) {
      score += 26;
    } else if (item.name.toLowerCase().contains('fiberglass')) {
      score -= 18;
    }
  }
  if (text.contains('fiberglass')) {
    if (item.name.toLowerCase().contains('fiberglass')) {
      score += 20;
    } else if (item.name.toLowerCase().contains('cellulose')) {
      score -= 14;
    }
  }
  if (RegExp(
        r'\b(vapor barrier|poly barrier|plastic sheeting|house wrap)\b',
      ).hasMatch(text) &&
      category == 'vapor barriers and accessories') {
    score += 24;
  }
  if (RegExp(
        r'\b(crawlspace liner|crawl space liner|crawlspace seam tape|crawl space tape|vapor barrier sealant|termination bar|drainage mat|foundation air sealant|crawlspace sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('crawlspace')) {
    score += 34;
  }
  if (RegExp(r'\b(crawlspace seam tape|crawl space tape)\b').hasMatch(text)) {
    if (itemName.contains('crawlspace seam tape')) {
      score += 60;
    } else if (itemName.contains('house wrap tape') ||
        itemName.contains('seam tape')) {
      score -= 14;
    }
  }
  if (RegExp(r'\b(crawlspace liner|crawl space liner)\b').hasMatch(text)) {
    if (itemName.contains('crawlspace liner')) {
      score += 60;
    } else if (itemName.contains('vapor barrier')) {
      score -= 10;
    }
  }
  for (final mil in ['4 mil', '6 mil', '10 mil', '12 mil', '20 mil']) {
    final compact = mil.replaceAll(' ', '');
    if ((text.contains(mil) || text.contains(compact)) &&
        itemName.contains(mil)) {
      score += 44;
    } else if ((text.contains(mil) || text.contains(compact)) &&
        (itemName.contains('crawlspace liner') ||
            itemName.contains('vapor barrier')) &&
        !itemName.contains(mil)) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(seam tape|house wrap tape|support wire|insulation hanger)\b',
      ).hasMatch(text) &&
      itemType.contains('tape')) {
    score += 20;
  }
  if (RegExp(
        r'\b(rafter vent|soffit baffle|attic vent chute|wind wash barrier|can light cover|recessed light cover|foam gasket|outlet gasket|switch gasket|air sealant)\b',
      ).hasMatch(text) &&
      itemType.contains('attic venting')) {
    score += 42;
  }
  if (RegExp(
    r'\b(rafter vent baffle|soffit vent baffle|attic vent chute)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rafter vent baffle') ||
        itemName.contains('soffit vent baffle') ||
        itemName.contains('attic vent chute')) {
      score += 68;
    }
  }
  if (RegExp(r'\b(can light cover|recessed light cover)\b').hasMatch(text)) {
    if (itemName.contains('can light cover') ||
        itemName.contains('light cover')) {
      score += 52;
    } else if (itemName.contains('vapor barrier') ||
        itemName.contains('seam tape')) {
      score -= 16;
    }
  }
  if (RegExp(
        r'\b(insulation netting|blown in mesh|cap nail|house wrap cap|vapor barrier cap nail|foam board washer|impaling clip|stick pin|termination bar)\b',
      ).hasMatch(text) &&
      itemType.contains('fasteners')) {
    score += 42;
  }
  if (RegExp(r'\b(impaling clip|stick pin)\b').hasMatch(text)) {
    if (itemName.contains('impaling clip') || itemName.contains('stick pin')) {
      score += 56;
    } else if (itemName.contains('retainer clip')) {
      score -= 12;
    }
  }
  if (RegExp(
        r'\b(firestop collar|fire stop collar|firestop sleeve|firestop sealant|fire stop sealant|fireblock sealant|draft stop|intumescent|putty pad|fire pad|firestop wrap|pipe firestop boot|smoke seal)\b',
      ).hasMatch(text) &&
      itemType.contains('firestop')) {
    score += 36;
  }
  if (RegExp(
    r'\b(firestop wrap|pipe firestop boot|wrap strip)\b',
  ).hasMatch(text)) {
    if (itemName.contains('firestop wrap') ||
        itemName.contains('firestop boot')) {
      score += 58;
    } else if (itemName.contains('firestop collar')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(firestop collar|fire stop collar)\b').hasMatch(text)) {
    if (itemName.contains('firestop collar')) {
      score += 64;
    } else if (itemName.contains('pipe insulation')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(pipe insulation|foam pipe insulation|rubber pipe insulation|weatherstrip|door sweep|window insulation|foam gasket)\b',
      ).hasMatch(text) &&
      itemType.contains('weatherization')) {
    score += 28;
  }
  if (RegExp(
        r'\b(radiant barrier|reflective insulation|water heater blanket|garage door insulation|vent cover)\b',
      ).hasMatch(text) &&
      itemType.contains('weatherization')) {
    score += 28;
  }
  if (RegExp(
        r'\b(acoustic sealant|sound panel|acoustic panel|mass loaded vinyl|resilient channel|sound isolation)\b',
      ).hasMatch(text) &&
      itemType.contains('acoustic')) {
    score += 28;
  }
  if (RegExp(
        r'\b(sound control batt|sound batt|acoustic board|sound board|sound isolation clip|sound isolation track|hat channel|sound deadening|door sound seal)\b',
      ).hasMatch(text) &&
      itemType.contains('sound isolation')) {
    score += 34;
  }
  if (RegExp(r'\b(sound isolation clip|resilient channel)\b').hasMatch(text)) {
    if (itemName.contains('sound isolation clip') ||
        itemName.contains('resilient channel')) {
      score += 54;
    }
  }
  if (RegExp(
    r'\b(sound isolation track|sound isolation bracket)\b',
  ).hasMatch(text)) {
    if (itemName.contains('sound isolation track') ||
        itemName.contains('sound isolation bracket')) {
      score += 58;
    } else if (itemName.contains('sound isolation clip')) {
      score -= 12;
    }
  }
  if (RegExp(r'\b(fence|shingle|tile|thinset)\b').hasMatch(text)) score -= 16;
  return score;
}
