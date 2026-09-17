part of '../../work_supply_receipt_parser.dart';

/// Scores HVAC service equipment, diagnostics, hydronics, and cleaning evidence.
int _hvacServiceEquipmentAndToolReceiptScore(String text, WorkSupplyItem item) {
  var score = 0;
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final variant = _normalize(item.variant);
  if (RegExp(
        r'\b(duct board|supply plenum|return plenum|return box|duct transition|takeoff damper)\b',
      ).hasMatch(text) &&
      itemType.contains('duct board')) {
    score += 26;
  }
  if (RegExp(
    r'\b(supply plenum|return plenum|return air box|filter box|duct transition|square to round transition)\b',
  ).hasMatch(text)) {
    if (itemName.contains('plenum') ||
        itemName.contains('return air box') ||
        itemName.contains('filter box') ||
        itemName.contains('transition')) {
      score += 38;
    }
    for (final term in [
      'supply plenum',
      'return plenum',
      'return air box',
      'filter box',
      'duct transition',
      'square to round transition',
    ]) {
      if (text.contains(term) && itemName.contains(term)) {
        score += 76;
      } else if (text.contains(term) &&
          (itemName.contains('plenum') ||
              itemName.contains('box') ||
              itemName.contains('transition')) &&
          !itemName.contains(term)) {
        score -= 36;
      }
    }
    for (final size in [
      '16 x 16 x 24',
      '16 x 20 x 24',
      '18 x 18 x 24',
      '20 x 20 x 24',
      '20 x 25 x 24',
      '24 x 24 x 24',
      '16 x 16 x 30',
      '16 x 20 x 30',
      '18 x 18 x 30',
      '20 x 20 x 30',
      '20 x 25 x 30',
      '24 x 24 x 30',
      '16 x 16 x 36',
      '16 x 20 x 36',
      '18 x 18 x 36',
      '20 x 20 x 36',
      '20 x 25 x 36',
      '24 x 24 x 36',
      '16 x 16 x 48',
      '16 x 20 x 48',
      '18 x 18 x 48',
      '20 x 20 x 48',
      '20 x 25 x 48',
      '24 x 24 x 48',
    ]) {
      final compact = size.replaceAll(' ', '');
      if ((text.contains(size) || text.contains(compact)) &&
          itemName.contains(size)) {
        score += 46;
      }
    }
  }
  if (RegExp(
        r'\b(dryer vent|dryer duct|vent hood|bath fan|exhaust duct)\b',
      ).hasMatch(text) &&
      itemType.contains('dryer vent')) {
    score += 26;
  }
  if (RegExp(
        r'\b(manifold gauge|gauge set|refrigerant scale|charging scale|vacuum pump|micron gauge|core removal|flaring tool|tubing cutter|recovery tank)\b',
      ).hasMatch(text) &&
      itemType.contains('vacuum')) {
    score += 26;
  }
  if (RegExp(
    r'\b(clamp meter|multimeter|manometer|psychrometer|temperature clamp|pipe clamp thermometer|infrared thermometer|static pressure|combustion analyzer|carbon monoxide|co meter)\b',
  ).hasMatch(text)) {
    if (itemType.contains('meters') ||
        itemName.contains('meter') ||
        itemName.contains('manometer') ||
        itemName.contains('psychrometer') ||
        itemName.contains('thermometer') ||
        itemName.contains('test instrument')) {
      score += 64;
    } else if (itemName.contains('gauge') || itemName.contains('tool')) {
      score += 12;
    }
    for (final tool in [
      'clamp meter',
      'true rms multimeter',
      'dual port manometer',
      'digital psychrometer',
      'temperature clamp probe',
      'pipe clamp thermometer',
      'infrared thermometer',
      'static pressure tip',
      'combustion analyzer',
      'carbon monoxide meter',
    ]) {
      if (text.contains(tool) && itemName.contains(tool)) {
        score += 86;
      } else if (text.contains(tool) &&
          itemName.contains('hvac test instrument') &&
          !itemName.contains(tool)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
    r'\b(leak detector|refrigerant leak detector|uv dye|dye injector|bubble leak|nylog|schrader core|service cap)\b',
  ).hasMatch(text)) {
    if (itemName.contains('leak detector') ||
        itemName.contains('uv leak') ||
        itemName.contains('uv dye') ||
        itemName.contains('nylog') ||
        itemName.contains('schrader') ||
        itemName.contains('service cap')) {
      score += 70;
    } else if (itemName.contains('hvac leak detection')) {
      score += 24;
    }
    for (final item in [
      'electronic refrigerant leak detector',
      'uv leak detection dye cartridge',
      'uv dye injector hose',
      'bubble leak detector spray',
      'nylog blue thread sealant',
      'schrader core assortment',
      'low side service cap',
      'high side service cap',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          itemName.contains('hvac leak detection') &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(boiler|hydronic|circulator|circ pump|zone valve|aquastat|low water cutoff|expansion tank|air vent|coin vent|backflow preventer|pressure reducing|fill valve|air separator)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hydronic') ||
        itemName.contains('boiler') ||
        itemName.contains('circulator') ||
        itemName.contains('zone valve') ||
        itemName.contains('aquastat') ||
        itemName.contains('expansion tank') ||
        itemName.contains('air vent') ||
        itemName.contains('backflow preventer') ||
        itemName.contains('pressure reducing')) {
      score += 62;
    } else if (item.trade == 'Plumbing' && text.contains('boiler')) {
      score -= 18;
    }
    for (final item in [
      'universal circulator pump',
      'zone valve power head',
      'aquastat temperature control',
      'low water cutoff control',
      'hydronic expansion tank',
      'automatic air vent',
      'pressure relief valve 30 psi',
      'pressure reducing fill valve',
      'microbubble air separator',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          (itemName.contains('hydronic') || itemName.contains('boiler')) &&
          !itemName.contains(item)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
    r'\b(baseboard heat|baseboard element|baseboard cover|baseboard end cap|radiator air vent|radiator valve|radiant heat|radiant manifold|oxygen barrier pex)\b',
  ).hasMatch(text)) {
    if (itemName.contains('baseboard') ||
        itemName.contains('radiator') ||
        itemName.contains('radiant')) {
      score += 64;
    }
    for (final item in [
      'baseboard heating element',
      'baseboard enclosure front cover',
      'baseboard end cap',
      'radiator air vent',
      'radiant manifold flow meter',
      'radiant manifold actuator',
      'oxygen barrier pex coupling',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 82;
      } else if (text.contains(item) &&
          (itemName.contains('baseboard') ||
              itemName.contains('radiator') ||
              itemName.contains('radiant')) &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(rooftop unit|rtu|package unit|blower belt|cogged belt|hail guard|panel screw|door latch|crankcase heater|phase monitor)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rooftop unit') ||
        itemName.contains('package unit') ||
        itemName.contains('blower belt') ||
        itemName.contains('crankcase heater') ||
        itemName.contains('phase monitor') ||
        itemName.contains('hail guard')) {
      score += 62;
    }
    for (final belt in [
      'a28',
      'a30',
      'a32',
      'a34',
      'a36',
      'a38',
      'a40',
      'a42',
      'b34',
      'b36',
      'b38',
      'b40',
      'b42',
      'b44',
      'bx38',
      'bx40',
      'bx42',
      'bx44',
    ]) {
      if (text.contains(belt) &&
          itemName.contains('$belt cogged blower belt')) {
        score += 94;
      } else if (text.contains(belt) &&
          itemName.contains('blower belt') &&
          !itemName.contains(belt)) {
        score -= 24;
      }
    }
    for (final item in [
      'rooftop unit hail guard panel',
      'rtu condensate drain trap kit',
      'package unit fan relay',
      'rtu time delay relay',
      'crankcase heater',
      'rtu phase monitor',
      'compressor terminal repair kit',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 84;
      } else if (text.contains(item) &&
          (itemName.contains('rooftop unit') ||
              itemName.contains('package unit') ||
              itemName.contains('rtu')) &&
          !itemName.contains(item)) {
        score -= 22;
      }
    }
  }
  if (RegExp(
    r'\b(economizer|enthalpy sensor|mixed air sensor|outdoor air sensor|return air sensor|damper actuator|damper linkage|minimum position|barometric relief|fresh air hood)\b',
  ).hasMatch(text)) {
    if (itemName.contains('economizer') ||
        itemName.contains('enthalpy sensor') ||
        itemName.contains('mixed air sensor') ||
        itemName.contains('outdoor air sensor') ||
        itemName.contains('return air sensor') ||
        itemName.contains('damper actuator') ||
        itemName.contains('barometric relief') ||
        itemName.contains('fresh air hood')) {
      score += 68;
    }
    for (final item in [
      'economizer logic module',
      'economizer enthalpy sensor',
      'economizer mixed air sensor',
      'economizer outdoor air sensor',
      'economizer damper linkage kit',
      'barometric relief damper',
      'fresh air hood filter',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 88;
      } else if (text.contains(item) &&
          itemName.contains('economizer') &&
          !itemName.contains(item)) {
        score -= 24;
      }
    }
  }
  if (RegExp(
        r'\b(ac disconnect|disconnect box|ac whip|liquid tight|surge protector)\b',
      ).hasMatch(text) &&
      itemType.contains('electrical install')) {
    score += 26;
  }
  if (RegExp(
        r'\b(ignitor|hsi|flame sensor|flame rod|pressure switch)\b',
      ).hasMatch(text) &&
      itemType.contains('ignition')) {
    score += 26;
  }
  if (RegExp(
        r'\b(pressure switch tubing|door switch|rollout switch|limit switch|inducer gasket|ignitor wire harness)\b',
      ).hasMatch(text) &&
      itemType.contains('furnace service switches')) {
    score += 34;
  }
  if (RegExp(
    r'\b(coil cleaner|evap cleaner|evaporator cleaner|condenser cleaner|no rinse cleaner|pan tablets|pan strips|drain line cleaner|uv dye|fin comb|coil brush)\b',
  ).hasMatch(text)) {
    if (itemType.contains('coil cleaners') ||
        itemName.contains('coil cleaner') ||
        itemName.contains('evaporator cleaner') ||
        itemName.contains('condenser cleaner') ||
        itemName.contains('drain line cleaner') ||
        itemName.contains('pan tablet') ||
        itemName.contains('fin comb') ||
        itemName.contains('coil brush')) {
      score += 42;
    }
    for (final item in [
      'foaming evaporator coil cleaner',
      'condenser coil cleaner',
      'no rinse evaporator cleaner',
      'drain line cleaner',
      'condensate pan tablet',
      'fin comb',
      'coil brush',
    ]) {
      if (text.contains(item) && itemName.contains(item)) {
        score += 78;
      } else if (text.contains(item) &&
          itemName.contains('hvac cleaning supply') &&
          !itemName.contains(item)) {
        score -= 18;
      }
    }
  }
  if (category == 'air filters' && text.contains('mfd')) score -= 18;
  if (system == 'thermostats' && text.contains('capacitor')) score -= 18;
  if (system == 'capacitors and contactors' && text.contains('filter')) {
    score -= 18;
  }
  for (final term in [
    'filter rack',
    'return filter grille',
    'secondary drain pan',
    'clear vinyl tubing',
    'line set cover',
    'line hide',
    'equipment pad',
    'wall bracket',
    'register boot',
    'spin-in',
    'start collar',
    'b vent',
    'flue pipe',
    'wall cap',
    'rollout switch',
    'limit switch',
  ]) {
    if (text.contains(term) && variant.contains(term)) score += 42;
  }
  return score;
}
