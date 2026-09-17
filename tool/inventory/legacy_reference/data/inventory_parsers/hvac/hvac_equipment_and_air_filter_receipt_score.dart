part of '../../work_supply_receipt_parser.dart';

/// Scores HVAC equipment, capacitors, filters, and early duct evidence.
int _hvacEquipmentAndAirFilterReceiptScore(String text, WorkSupplyItem item) {
  var score = 0;
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final variant = _normalize(item.variant);
  if (text.contains('retaining wall')) {
    score -= 40;
  }
  if (RegExp(
    r'\b(capacitor|mfd|uf|run cap|pleated|filter|furnace filter|ac filter|filter rack|return grille|foil tape|hvac tape|mastic|duct|condensate|drain pan|thermostat|contactor|line set|line hide|mini split|register|grille|boot|takeoff|b vent|flue|ignitor|flame sensor|coil cleaner|zone damper|duct board|plenum|dryer vent|vacuum pump|manifold gauge|micron gauge|ac disconnect|ac whip|equipment pad|limit switch|rollout switch|condenser|heat pump|evaporator coil|evap coil|gas furnace|air handler|heat kit|package unit|rooftop unit|economizer|crankcase heater)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  if (RegExp(r'\b\d{2,3}v\b').hasMatch(variant) &&
      !RegExp(r'\b\d{2,3}v\b').hasMatch(text)) {
    score -= 20;
  }
  if (RegExp(
    r'\b(ac condenser|condensing unit|heat pump condenser|side discharge heat pump|inverter condenser|evaporator coil|evap coil|cased coil|uncased coil|gas furnace|air handler|electric heat kit|mini split|package unit|rooftop unit|roof curb|economizer|fresh air damper|condenser fan guard|crankcase heater|low ambient kit)\b',
  ).hasMatch(text)) {
    if (itemName.contains('equipment') ||
        itemName.contains('condenser') ||
        itemName.contains('heat pump') ||
        itemName.contains('evaporator coil') ||
        itemName.contains('gas furnace') ||
        itemName.contains('air handler') ||
        itemName.contains('heat kit') ||
        itemName.contains('mini split') ||
        itemName.contains('package unit') ||
        itemName.contains('roof curb') ||
        itemName.contains('economizer') ||
        itemName.contains('crankcase heater') ||
        itemName.contains('low ambient')) {
      score += 52;
    }
    for (final term in [
      'ac condenser',
      'heat pump condenser',
      'side discharge heat pump',
      'inverter condenser',
      'cased evaporator coil',
      'uncased evaporator coil',
      'gas furnace',
      'multi position air handler',
      'wall mount air handler',
      'electric heat kit',
      'mini split outdoor condenser',
      'mini split wall mount indoor head',
      'mini split ceiling cassette',
      'mini split floor console',
      'gas electric package unit',
      'heat pump package unit',
      'package unit roof curb',
      'economizer kit',
      'fresh air damper kit',
      'condenser fan guard',
      'evaporator coil drain pan',
      'condenser riser kit',
      'compressor sound blanket',
      'low ambient control kit',
      'crankcase heater kit',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 86;
      } else if (text.contains(term) &&
          (itemName.contains('condenser') ||
              itemName.contains('coil') ||
              itemName.contains('furnace') ||
              itemName.contains('air handler') ||
              itemName.contains('mini split') ||
              itemName.contains('package unit') ||
              itemName.contains('kit')) &&
          !itemName.contains(term)) {
        score -= 26;
      }
    }
    if (text.contains('nat gas') && itemName.contains('natural gas')) {
      score += 28;
    }
    if (text.contains('evap coil') && itemName.contains('evaporator coil')) {
      score += 70;
    }
    if (text.contains('wall mount indoor head') &&
        itemName.contains('mini split wall mount indoor head')) {
      score += 70;
    }
    for (final tons in [
      '1.5 ton',
      '2 ton',
      '2.5 ton',
      '3 ton',
      '3.5 ton',
      '4 ton',
      '5 ton',
    ]) {
      final compact = tons.replaceAll(' ', '');
      if ((text.contains(tons) || text.contains(compact)) &&
          itemName.contains(tons)) {
        score += 36;
      } else if ((text.contains(tons) || text.contains(compact)) &&
          (itemName.contains('condenser') ||
              itemName.contains('coil') ||
              itemName.contains('air handler') ||
              itemName.contains('package unit')) &&
          !itemName.contains(tons)) {
        score -= 14;
      }
    }
    for (final btu in [
      '9k btu',
      '12k btu',
      '18k btu',
      '24k btu',
      '30k btu',
      '36k btu',
      '40k btu',
      '60k btu',
      '80k btu',
      '100k btu',
      '120k btu',
    ]) {
      final compact = btu.replaceAll(' ', '');
      if ((text.contains(btu) || text.contains(compact)) &&
          itemName.contains(btu)) {
        score += 36;
      }
    }
    for (final detail in [
      '14.3 seer2',
      '15.2 seer2',
      '16 seer2',
      '17 seer2',
      '18 seer2',
      '20 seer2',
      '22 seer2',
      '80 afue',
      '92 afue',
      '96 afue',
      '97 afue',
      'r410a',
      'r454b',
      '5 kw',
      '10 kw',
      '15 kw',
      '20 kw',
      'natural gas',
      'lp convertible',
      'upflow',
      'downflow',
      'horizontal',
      'multi position',
      '208-230v',
      '120v',
    ]) {
      final compact = detail.replaceAll(' ', '');
      if ((text.contains(detail) || text.contains(compact)) &&
          itemName.contains(detail)) {
        score += 24;
      }
    }
    for (final width in ['14 in', '17.5 in', '21 in', '24.5 in']) {
      final compact = width.replaceAll(' ', '');
      if ((text.contains(width) || text.contains(compact)) &&
          itemName.contains(width)) {
        score += 24;
      }
    }
  }
  if (RegExp(r'\b(capacitor|mfd|uf|run cap|dual run)\b').hasMatch(text) &&
      itemType.contains('capacitor')) {
    score += 24;
    for (final value in [
      '25/5',
      '30/5',
      '35/5',
      '40/5',
      '45/5',
      '50/5',
      '55/5',
      '60/5',
      '70/5',
      '80/5',
    ]) {
      if (text.contains(value) && itemName.contains(value)) {
        score += 96;
      } else if (text.contains(value) && !itemName.contains(value)) {
        score -= 36;
      }
    }
    if (RegExp(r'\b(dual run|run cap)\b').hasMatch(text) &&
        itemName.contains('start kit')) {
      score -= 90;
    }
    if (text.contains('start') && itemName.contains('start capacitor')) {
      score += 42;
    }
  }
  if (RegExp(r'\b(pleated|filter)\b').hasMatch(text) &&
      itemType.contains('filter')) {
    score += 24;
  }
  if (RegExp(r'\b(filter|merv|media cabinet)\b').hasMatch(text) &&
      itemName.contains('filter')) {
    for (final size in [
      '10 x 20 x 1',
      '12 x 12 x 1',
      '12 x 20 x 1',
      '14 x 14 x 1',
      '14 x 20 x 1',
      '14 x 25 x 1',
      '16 x 16 x 1',
      '16 x 20 x 1',
      '16 x 24 x 1',
      '16 x 25 x 1',
      '18 x 20 x 1',
      '18 x 24 x 1',
      '20 x 20 x 1',
      '20 x 24 x 1',
      '20 x 25 x 1',
      '24 x 24 x 1',
      '24 x 30 x 1',
      '12 x 24 x 2',
      '16 x 20 x 2',
      '16 x 25 x 2',
      '20 x 20 x 2',
      '20 x 25 x 2',
      '24 x 24 x 2',
      '20 x 25 x 5',
      '20 x 25 x 4',
      '16 x 25 x 5',
      '16 x 25 x 4',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          (itemName.contains('$size in') || itemName.contains(size))) {
        score += 58;
      } else if ((text.contains(size) || text.contains(compact)) &&
          !itemName.contains('$size in') &&
          !itemName.contains(size)) {
        score -= 22;
      }
    }
    for (final rating in ['merv 8', 'merv 11', 'merv 13', 'merv 16']) {
      if (text.contains(rating) && itemName.contains(rating)) {
        score += 30;
      } else if (text.contains(rating) && !itemName.contains(rating)) {
        score -= 10;
      }
    }
    if (!text.contains('merv') && itemName.contains('merv')) {
      score -= 72;
    }
    if (!RegExp(r'\b(12\s*pack|pack|case|carton|ct)\b').hasMatch(text) &&
        RegExp(r'\b(12\s*pack|case stock|filter case)\b').hasMatch(itemName)) {
      score -= 84;
    }
    if (text.contains('media cabinet') &&
        itemName.contains('media cabinet filter')) {
      score += 40;
    }
  }
  if (RegExp(
        r'\b(filter rack|filter base|return filter grille|filter grille|return air grille)\b',
      ).hasMatch(text) &&
      itemType.contains('filter racks')) {
    score += 34;
  }
  if (RegExp(r'\b(foil tape|hvac tape|metal tape)\b').hasMatch(text) &&
      itemType.contains('tape')) {
    score += 22;
  }
  if (RegExp(r'\b(mastic|duct sealant)\b').hasMatch(text) &&
      itemType.contains('mastic')) {
    score += 22;
  }
  if (RegExp(
    r'\b(duct mastic|duct sealant|water based duct sealant)\b',
  ).hasMatch(text)) {
    if (itemName.contains('duct mastic') || itemName.contains('duct sealant')) {
      score += 84;
    } else if (itemName.contains('mastic')) {
      score -= 42;
    }
    for (final size in ['1 gal', '2 gal', '5 gal']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 28;
      }
    }
  }
  if (RegExp(r'\b(contactor|compressor contactor)\b').hasMatch(text) &&
      itemType.contains('contactor')) {
    score += 24;
  }
  if (RegExp(r'\b(thermostat|t-stat|t stat|stat)\b').hasMatch(text) &&
      itemType.contains('thermostat')) {
    score += 20;
  }
  if (RegExp(
        r'\b(thermostat wire|stat wire|low voltage wire)\b',
      ).hasMatch(text) &&
      itemType.contains('thermostat wire')) {
    score += 24;
  }
  if (RegExp(r'\b(cond pump|condensate pump|little pump)\b').hasMatch(text) &&
      itemType.contains('condensate pump')) {
    score += 24;
  }
  if (RegExp(r'\b(pan tabs|drain tabs|condensate tablets)\b').hasMatch(text) &&
      itemType.contains('condensate drain tablets')) {
    score += 24;
  }
  if (RegExp(
        r'\b(drain pan|secondary pan|auxiliary pan|vinyl tubing|clear tubing|condensate treatment|pan switch|float switch|wet switch)\b',
      ).hasMatch(text) &&
      itemType.contains('condensate pans')) {
    score += 34;
  }
  if (RegExp(r'\b(line set|copper line|armaflex)\b').hasMatch(text) &&
      itemType.contains('line sets')) {
    score += 26;
  }
  if (RegExp(r'\b(flex duct|insulated flex)\b').hasMatch(text)) {
    if (itemName.contains('flex duct')) {
      score += 90;
    } else if (itemName.contains('duct elbow') ||
        itemName.contains('duct coupling') ||
        itemName.contains('round duct')) {
      score -= 42;
    }
    for (final size in ['4 in', '5 in', '6 in', '7 in', '8 in', '10 in']) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 34;
      }
    }
    for (final rating in ['r6', 'r8']) {
      if (text.contains(rating) && itemName.contains(rating)) {
        score += 46;
      } else if (text.contains(rating) &&
          itemName.contains('flex duct') &&
          !itemName.contains(rating)) {
        score -= 22;
      }
    }
  }
  return score;
}
