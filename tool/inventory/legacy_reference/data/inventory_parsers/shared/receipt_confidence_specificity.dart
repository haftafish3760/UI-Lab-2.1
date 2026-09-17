part of '../../work_supply_receipt_parser.dart';

/// Scores receipt evidence that uniquely supports a catalog match.
double _specificityEvidenceScore(String text, WorkSupplyItem item) {
  var score = 0.0;
  if (_nominalReceiptSize(text) != null) score += 0.04;
  if (_receiptSizeMatrix(text) != null) score += 0.05;
  if (_receiptContainsVariantTokens(text, item.variant)) score += 0.06;
  if (_containsExactPhrase(text, item.itemType)) score += 0.04;
  if (_containsExactPhrase(text, item.system)) score += 0.04;
  final itemText = _indexedReceiptTextFor(item);
  if (RegExp(
    r'\b(sch|schedule|dwv|s40|emt|thhn|condensate|merv)\b',
  ).hasMatch(text)) {
    score += 0.05;
  }
  if (RegExp(
    r'\b(pex|cpvc|abs|copper|brass|galv|galvanized)\b',
  ).hasMatch(text)) {
    score += 0.04;
  }
  if (RegExp(r'\b(cpvc|cpv\s*c)\b').hasMatch(text) &&
      RegExp(r'\b(coupling|cplg|coup)\b').hasMatch(text) &&
      itemText.contains('cpvc coupling')) {
    score += 0.10;
  }
  if (RegExp(
    r'\b(conduit|condensate|refrigerant|dwv|pressure)\b',
  ).hasMatch(itemText)) {
    score += 0.03;
  }
  if (RegExp(r'\b(c\s*wire|common\s+wire|wire\s+saver)\b').hasMatch(text) &&
      itemText.contains('common wire adapter')) {
    score += 0.10;
  }
  if (RegExp(r'\b(surge|spd)\b').hasMatch(text) &&
      itemText.contains('surge protector')) {
    score += 0.10;
  }
  if (RegExp(r'\bposi\s*temp\b').hasMatch(text) &&
      itemText.contains('shower cartridge')) {
    score += 0.10;
  }
  if (RegExp(r'\b(foam|gasket)\b').hasMatch(text) &&
      RegExp(r'\btape\b').hasMatch(text) &&
      itemText.contains('foam gasket tape')) {
    score += 0.10;
  }
  if (RegExp(r'\b(cond|condensate|drain)\b').hasMatch(text) &&
      RegExp(r'\b(tabs?|tablets?)\b').hasMatch(text) &&
      itemText.contains('condensate drain tablets')) {
    score += 0.12;
  }
  final rawItemText = '${item.name} ${item.variant} ${item.itemType}'
      .toLowerCase();
  if (_hasPTrapReceiptPhrase(text) &&
      (rawItemText.contains('p-trap') || rawItemText.contains('p trap'))) {
    score += 0.24;
  }
  score += _plumbingCoreReceiptEvidenceScore(text, item, itemText);
  return score;
}

double _plumbingCoreReceiptEvidenceScore(
  String text,
  WorkSupplyItem item,
  String itemText,
) {
  var score = 0.0;
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(90|90d|ell|elb|elbow)\b').hasMatch(text) &&
      itemText.contains('pvc schedule 40 90 elbow')) {
    score += 0.10;
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      itemText.contains('pvc cement')) {
    score += 0.20;
    final amount = _receiptPackageAmount(text, 'oz');
    if (_itemMatchesPackageAmount(item, amount, 'oz')) {
      score += 0.12;
    }
    if (RegExp(r'\bclear\b').hasMatch(text) && itemText.contains('clear')) {
      score += 0.04;
    }
  }
  if (RegExp(r'\b(cop|cu|copper)\b').hasMatch(text) &&
      !_hasBrokenCriticalPlumbingFraction(text) &&
      RegExp(r'\b(90|90d|ell|elb|elbow)\b').hasMatch(text) &&
      RegExp(
        r'\b(cxc|c\s*x\s*c|copper\s+copper|sweat|wrot)\b',
      ).hasMatch(text) &&
      itemText.contains('copper') &&
      itemText.contains('90') &&
      itemText.contains('elbow')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(reducing cplg|reducing coupling|reducer coupling)\b',
      ).hasMatch(text) &&
      itemText.contains('reducing coupling')) {
    score += 0.10;
  }
  final serviceFamilies = <RegExp, List<String>>{
    RegExp(r'\b(p trap|p-trap)\b'): ['p trap', 'p-trap'],
    RegExp(r'\b(fill valve|valvula llenado|valvula de llenado)\b'): [
      'fill valve',
    ],
    RegExp(r'\btank lever\b'): ['tank lever'],
    RegExp(r'\baerator\b'): ['aerator'],
    RegExp(r'\b(o ring|o-ring|oring)\b'): ['o ring', 'o-ring', 'oring'],
    RegExp(r'\bstem\s+packing\b'): ['stem packing'],
    RegExp(r'\bdisposal drain elb'): ['disposal drain elbow'],
    RegExp(r'\bcontinuous waste\b|\bcont waste\b'): ['continuous waste'],
    RegExp(r'\bdisposal install kit\b'): ['disposal install kit'],
    RegExp(r'\bdisposal elbow gasket\b|\bdisposal gasket\b'): [
      'disposal gasket',
      'disposal elbow gasket',
    ],
    RegExp(r'\bescutcheon\b|\besc plate\b'): ['escutcheon'],
    RegExp(r'\b(boiler drain|heater drain|drain valve)\b'): [
      'drain valve',
      'boiler drain',
      'heater drain',
    ],
    RegExp(r'\b(t and p|t p|t&p|tpr|valvula alivio|valvula t p)\b'): [
      'temperature and pressure relief valve',
      'relief valve',
      't&p valve',
      'tpr valve',
    ],
    RegExp(r'\b(fernco|rubber coupling|flexible coupling)\b'): [
      'fernco',
      'rubber coupling',
      'flexible coupling',
      'flexible drain repair coupling',
    ],
    RegExp(r'\b(sharkbite|push|push fit|push-fit)\b.*\b(coup|coupling|cplg)\b'):
        ['push-fit coupling', 'push coupling', 'push connect coupling'],
    RegExp(r'\b(cinta teflon|cinta de teflon|ptfe tape|teflon tape)\b'): [
      'ptfe thread tape',
      'ptfe tape',
      'teflon tape',
    ],
    RegExp(
      r'\b(softener salt|salt pellets|sal suavizador|sal ablandador|sal para suavizador)\b',
    ): [
      'water softener salt pellets',
      'softener salt',
    ],
    RegExp(
      r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
    ): [
      'pressure gauge',
      'well pressure gauge',
    ],
    RegExp(
      r'\b(well pressure switch|pump pressure switch|pressure switch|well switch|switch presion pozo|interruptor bomba|presostato)\b',
    ): [
      'pressure switch',
      'well pressure switch',
      'pump pressure switch',
      'well switch',
    ],
    RegExp(r'\b(valvula\s+check\s+pozo|check\s+bomba)\b'): [
      'well pump check valve',
      'check valve',
    ],
    RegExp(
      r'\b(well pump|jet pump|shallow well|deep well|bomba pozo|bomba de pozo|bomba agua pozo)\b',
    ): [
      'well pump',
      'jet pump',
      'shallow well pump',
      'deep well pump',
    ],
    RegExp(
      r'\b(poly|polyethylene|well pipe)\b.*\b(insert|barb|barbed|coupling|adapter)\b',
    ): [
      'poly pipe insert',
      'poly well fitting',
      'well pipe fitting',
      'barbed coupling',
      'well service fitting',
    ],
    RegExp(r'\b(tr|tamper resistant)\b.*\b(dup|duplex|recpt|recept|outlet)\b'):
        ['duplex receptacle', 'tamper resistant'],
    RegExp(r'\b(cinta electrica|cinta aislante|elec tape|electrical tape)\b'): [
      'electrical tape',
    ],
    RegExp(r'\b(nail\s+plate|stud\s+guard)\b'): ['stud guard plate'],
    RegExp(r'\b(outside\s+faucet|hose\s+bibb?)\b'): ['hose bibb'],
    RegExp(r'\bvac(?:uum)?\s+breaker\b'): ['vacuum breaker'],
    RegExp(r'\b(jumbo\s+)?wax\s+ring(?:\s+bolts?)?\b'): ['wax ring'],
    RegExp(r'\bplumbers?\s+putty\b'): ['plumber putty'],
    RegExp(r'\bexpansion\s+tank\s+mounting\s+bracket\b'): [
      'expansion tank',
      'mounting bracket',
    ],
    RegExp(r'\bdielectric\s+nipple(?:\s+pair)?\b'): ['dielectric nipple'],
    RegExp(r'\b(inside\s+pipe\s+cutter|pipe\s+cutter)\b'): [
      'plumbing hand tool',
      'pipe cutter',
    ],
    RegExp(r'\bpvc\s+deburr(?:ing)?\s+tool\b'): [
      'plumbing hand tool',
      'deburr',
    ],
    RegExp(r'\btoilet\s+flush\s+valve\s+kit\b'): ['toilet flush valve'],
    RegExp(r'\b(liquid\s*tight|liquidtight|sealtite)\b.*\b(conn|connector)\b'):
        ['liquidtight connector', 'flexible raceway part'],
    RegExp(r'\b(wire\s*nut|wirenut|tuerca\s+cable|conector\s+cable)\b'): [
      'wire connector',
      'wire nut',
    ],
    RegExp(r'\b(conector\s+(de\s+)?palanca|lever\s+connector)\b'): [
      'lever connector',
    ],
    RegExp(r'\b(anti\s+corto|bushing\s+anti\s+corto)\b'): [
      'anti short bushing',
    ],
    RegExp(r'\b(interruptor\s+(toggle|3way|3\s*way)|toggle\s+switch)\b'): [
      'toggle switch',
      'switch',
    ],
    RegExp(r'\b(placa\s+(decora|decorador)|decorator\s+plate)\b'): [
      'wall plate',
    ],
    RegExp(
      r'\b(caja\s+(remodel|remodelacion)|old\s+work\s+box|remod(?:el)?\s+box)\b',
    ): [
      'old work',
    ],
    RegExp(r'\bground\s+screw\b'): ['ground screw'],
    RegExp(r'\b(photocell|photoeye|photo eye)\b'): ['photocell'],
    RegExp(r'\b(blank\s+wall\s+plate|wall\s+plate|cover\s+plate)\b'): [
      'wall plate',
      'cover plate',
      'blank',
    ],
    RegExp(r'\b(interruptor)\b.*\b(3\s*via|tres\s+vias?)\b'): [
      '3-way toggle switch',
      'toggle switch',
    ],
    RegExp(r'\b(uf-b|ufb|uf cable|underground feeder|direct burial)\b'): [
      'uf-b cable',
      'direct burial',
    ],
    RegExp(r'\b(contactor|contctr|cntctr)\b'): ['contactor'],
    RegExp(r'\b(transformer|xfmr|transf)\b'): ['transformer'],
    RegExp(r'\b(blade\s+fuse|fuse)\b'): ['fuse'],
    RegExp(r'\b(time\s+delay\s+relay|relay)\b'): ['relay'],
    RegExp(r'\b(tstat|thermostat|termostato)\b'): ['thermostat'],
    RegExp(r'\b(cond|condensate)\b.*\b(pump|pmp|bomba)\b'): ['condensate pump'],
    RegExp(r'\b(bomba)\b.*\b(cond|condensado|condensate)\b'): [
      'condensate pump',
    ],
    RegExp(r'\b(cond|condensate)\b.*\b(float|flotador)\b.*\b(sw|switch)\b'): [
      'condensate safety switch',
      'float switch',
    ],
    RegExp(r'\bflame\s+sensor\b'): ['flame sensor'],
    RegExp(r'\b(hot\s+surface\s+ignitor|hsi|ignitor)\b'): [
      'hot surface ignitor',
      'ignitor',
    ],
    RegExp(r'\b(hot\s+surf\s+ign|hsi\s+ign)\b'): [
      'hot surface ignitor',
      'ignitor',
    ],
    RegExp(r'\b\d{2}/\d(?:\.\d+)?\s*(?:370v|440v)?\s*(?:cap|capacitor)\b'): [
      'dual run capacitor',
      'capacitor',
    ],
    RegExp(r'\b(model\s+(?:10|35)\s+(?:water\s+panel|humidifier\s+pad))\b'): [
      'humidifier',
      'water panel',
      'humidifier pad',
    ],
    RegExp(r'\b(panel|pad)\s+humidificador\s+modelo\s+(?:10|35)\b'): [
      'humidifier',
      'water panel',
      'humidifier pad',
    ],
    RegExp(r'\b(pastillas\s+bandeja|tabletas\s+drenaje\s+cond)\b'): [
      'drain tablets',
      'condensate treatment',
    ],
    RegExp(r'\b(sensor|varilla)\s+flama\b'): ['flame sensor'],
    RegExp(r'\b(hard\s+start|spp6|start kit|start kt)\b'): ['hard start kit'],
    RegExp(r'\b(cinta|foil|ul181|ul 181)\b.*\b(tape|cinta|hvac)\b'): [
      'foil tape',
      'foil hvac tape',
    ],
    RegExp(r'\bduct\s+mastic\b|\bmastic\b'): ['duct mastic', 'mastic'],
    RegExp(r'\b(line\s*set|lineset|refrigerant line)\b'): [
      'line set',
      'refrigerant line',
    ],
    RegExp(r'\b(armaflex|pipe insulation|line insulation)\b'): [
      'pipe insulation',
      'line set insulation',
      'insulation',
    ],
    RegExp(r'\b(condenser pad|equipment pad)\b'): [
      'condenser pad',
      'equipment pad',
      'pad',
    ],
    RegExp(r'\b(condensate|cond)\b.*\b(pan|drain pan)\b'): [
      'condensate pan',
      'drain pan',
      'pan',
    ],
    RegExp(r'\b(condensate|cond)\b.*\b(neutralizer|neutraliser)\b'): [
      'condensate neutralizer',
      'neutralizer',
    ],
    RegExp(r'\b(service valve cap|valve cap)\b'): [
      'service valve cap',
      'valve cap',
    ],
  };
  for (final entry in serviceFamilies.entries) {
    if (entry.key.hasMatch(text) &&
        entry.value.any((phrase) => itemText.contains(phrase))) {
      score += entry.value.contains('p trap') ? 0.24 : 0.16;
      break;
    }
  }
  if (RegExp(r'\badjustable\s+fill\s+valve\b').hasMatch(text) &&
      itemText.contains('fill valve')) {
    score += 0.08;
  }
  if (RegExp(r'\b(valvula\s+check\s+pozo|check\s+bomba)\b').hasMatch(text) &&
      itemText.contains('check valve')) {
    score += 0.16;
  }
  final connectorPortCount = RegExp(
    r'\b(2|3|4|5|6)\s*(?:port|ports|puerto|puertos)\b',
  ).firstMatch(text)?.group(1);
  if (connectorPortCount != null &&
      itemText.contains('$connectorPortCount port')) {
    score += 0.08;
  }
  if (RegExp(r'\b(contactor|contctr|cntctr)\b').hasMatch(text) &&
      itemText.contains('contactor')) {
    score += 0.08;
  }
  if (RegExp(r'\b(transformer|xfmr|transf)\b').hasMatch(text) &&
      itemText.contains('transformer')) {
    score += 0.10;
  }
  if (RegExp(r'\b(blade\s+fuse|fuse)\b').hasMatch(text) &&
      itemText.contains('fuse')) {
    score += 0.10;
  }
  if (RegExp(r'\b(time\s+delay\s+relay|relay)\b').hasMatch(text) &&
      itemText.contains('relay')) {
    score += 0.10;
  }
  if (RegExp(r'\b(hard\s+start|spp6|start kit|start kt)\b').hasMatch(text) &&
      itemText.contains('hard start')) {
    score += 0.08;
  }
  if (RegExp(r'\b(line\s*set|lineset|refrigerant line)\b').hasMatch(text) &&
      itemText.contains('line set')) {
    score += 0.12;
  }
  if (RegExp(r'\b(line\s*set|lineset)\b.*\b(cover|kit)\b').hasMatch(text) &&
      itemText.contains('line set cover')) {
    score += 0.12;
  }
  if (RegExp(r'\b(condensate|cond)\b.*\b(pan|drain pan)\b').hasMatch(text) &&
      (itemText.contains('condensate pan') || itemText.contains('drain pan'))) {
    score += 0.14;
  }
  if (RegExp(
        r'\b(condensate|cond)\b.*\b(pvc|drain)\b.*\b(union|fitting)\b',
      ).hasMatch(text) &&
      itemText.contains('condensate pvc')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(condensate|cond)\b.*\b(neutralizer|neutraliser)\b',
      ).hasMatch(text) &&
      itemText.contains('neutralizer')) {
    score += 0.12;
  }
  if (RegExp(r'\b(service valve cap|valve cap)\b').hasMatch(text) &&
      itemText.contains('service valve cap')) {
    score += 0.12;
  }
  if (RegExp(
        r'\b(well pressure gauge|pressure gauge|well gauge|manometro presion pozo|manometro de presion)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(well|psi|pressure|presion|pozo)\b').hasMatch(text) &&
      itemText.contains('pressure gauge')) {
    score += 0.08;
  }
  if (RegExp(
        r'\b(well pump|jet pump|shallow well|deep well|bomba pozo|bomba de pozo|bomba agua pozo)\b',
      ).hasMatch(text) &&
      itemText.contains('well pump')) {
    score += 0.10;
  }
  return score;
}
