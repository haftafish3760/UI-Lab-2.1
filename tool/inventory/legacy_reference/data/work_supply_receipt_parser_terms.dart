part of 'work_supply_receipt_parser.dart';

const receiptMerchantAliases = {
  'lowes': ['lowe s', 'lowe\'s', 'lowes', 'lowe'],
  'home depot': ['home depot', 'the home depot', 'homedepot', 'h depot', 'hd'],
  'home depot pro': ['hd supply', 'home depot pro', 'hdsupply', 'hd pro'],
  'harbor freight': ['harbor freight', 'h freight', 'hft'],
  'ferguson': ['ferguson', 'ferg', 'ferguson plumbing', 'ferguson supply'],
  'ace hardware': ['ace', 'ace hardware', 'ace hdwe'],
  'true value': ['true value', 'truevalue', 'true value hardware'],
  'menards': ['menards', 'menard'],
  'grainger': ['grainger', 'ww grainger', 'w w grainger'],
  'tractor supply': ['tractor supply', 'tractor supply co', 'tsc'],
  'walmart': ['walmart', 'wal mart'],
  'do it best': ['do it best', 'doitbest', 'do it best hardware'],
  'mccoys': ['mccoys', 'mc coy', 'mccoy building supply'],
  'supplyhouse': ['supplyhouse', 'supply house', 'supplyhouse com'],
  'winsupply': ['winsupply', 'win supply', 'winwater', 'winsupply plumbing'],
  'hajoca': ['hajoca', 'hughes supply', 'hajoca plumbing'],
  'reece': ['reece', 'reece plumbing', 'morsco', 'morrison supply'],
  'fw webb': ['fw webb', 'f w webb', 'webb supply'],
  'core and main': ['core and main', 'core main', 'coremain'],
  'amazon': ['amazon', 'amzn'],
};

const receiptTermAliases = {
  ...receiptElectricalAndHvacTermAliases,
  ...receiptConstructionAndApplianceTermAliases,
  ...receiptCabinetsDoorsAndFinishesTermAliases,
  ...receiptRoofingSidingAndFlooringTermAliases,
  ...receiptTileAndInsulationTermAliases,
  ...receiptFencingMasonryLandscapeAndToolTermAliases,
};

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'(?<=[a-z])0(?=[a-z])'), 'o')
      .replaceAll(RegExp(r'\bi\s*/\s*2\b'), '1/2')
      .replaceAll(RegExp(r'\bi\s*/\s*4\b'), '1/4')
      .replaceAll(RegExp(r'\bpyc\b'), 'pvc')
      .replaceAll(RegExp(r'\bcpyg\b'), 'cpvc')
      .replaceAll(RegExp(r'\bcpv\s*g\b'), 'cpvc')
      .replaceAll(RegExp(r'\be1b\b'), 'elb')
      .replaceAll(RegExp(r'\be18\b'), 'elb')
      .replaceAll(RegExp(r'\bun1on\b'), 'union')
      .replaceAll(RegExp(r'\bsw1tch\b'), 'switch')
      .replaceAll(RegExp(r'\bpress\s+sw\b'), 'pressure switch')
      .replaceAll(RegExp(r'\bvac\s+brkr\b'), 'vacuum breaker')
      .replaceAll(RegExp(r'\boutdr\b'), 'outdoor')
      .replaceAll(RegExp(r'\blgt\b'), 'light')
      .replaceAll(RegExp(r'\bctrl\b'), 'control')
      .replaceAll(RegExp(r'\blineset\b'), 'line set')
      .replaceAll(RegExp(r'\bsoftner\b'), 'softener')
      .replaceAll(RegExp(r'\bshl?eld\b'), 'shield')
      .replaceAll(RegExp(r'\bprotctr\b'), 'protector')
      .replaceAll(RegExp(r'\bmap\s+pr0\b'), 'map pro')
      .replaceAll(RegExp(r'\bkt\b'), 'kit')
      .replaceAll(RegExp(r'(?<=\d)"'), ' in')
      .replaceAll(RegExp(r'(?<=\d)x(?=\d)'), ' x ')
      .replaceAll(RegExp(r'(?<=\d)\s*/\s*(?=\d)'), '/')
      .replaceAll(RegExp(r'(?<=\d)(ft|feet)\b'), ' ft')
      .replaceAll(RegExp(r'(?<=\d)(in|inch)\b'), ' in')
      .replaceAll(RegExp(r'(?<=\d)(lb|lbs|pound|pounds)\b'), ' lb')
      .replaceAll(RegExp(r'(?<=\d)(oz|ounce|ounces)\b'), ' oz')
      .replaceAll(RegExp(r'\bqt\b'), 'quart')
      .replaceAll(RegExp(r'\bpt\b'), 'pint')
      .replaceAll(RegExp(r'(?<=\d)(gal|gallon|gallons)\b'), ' gal')
      .replaceAll(RegExp(r'(?<=\d)(pk|pack|ct|count)\b'), ' pack')
      .replaceAllMapped(
        RegExp(r'\br\s*-?\s*(\d{2})\b'),
        (match) => 'r-${match.group(1)}',
      )
      .replaceAllMapped(
        RegExp(r'\b(10|12|14|18)\s*-\s*([23578])\b'),
        (match) => '${match.group(1)}/${match.group(2)}',
      )
      .replaceAll(RegExp(r'\bnm\s*-?\s*b\b'), 'nm-b')
      .replaceAll(RegExp(r'\blow\s+volt\b'), 'low voltage')
      .replaceAll(RegExp(r'\blv\s+wire\b'), 'low voltage wire')
      .replaceAll(RegExp(r'\bsch\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bsched\s*40\b'), 'schedule 40')
      .replaceAll(RegExp(r'\bs\s*40\b'), 'schedule 40')
      .replaceAllMapped(
        RegExp(r'\b(\d{1,3})\s*a\b'),
        (match) => '${match.group(1)} amp',
      )
      .replaceAll(RegExp(r'\bw\s*/\s*g\b'), 'with ground')
      .replaceAll(RegExp(r'\bw\s+g\b'), 'with ground')
      .replaceAll(RegExp(r'\b1\s*p\b'), '1p')
      .replaceAll(RegExp(r'\b2\s*p\b'), '2p')
      .replaceAll(RegExp(r'\b1p\s+24v\b'), '1 pole 24v')
      .replaceAll(RegExp(r'\b2p\s+24v\b'), '2 pole 24v')
      .replaceAll(RegExp(r'\bvalv\b'), 'valve')
      .replaceAll(RegExp(r'\bbv\b'), 'ball valve')
      .replaceAll(RegExp(r'\bc\s*x\s*m\b'), 'copper male adapter')
      .replaceAll(RegExp(r'\bc\s*x\s*f\b'), 'copper female adapter')
      .replaceAll(RegExp(r'\bc\s*x\s*c\b'), 'copper copper')
      .replaceAll(RegExp(r'\bs\s*x\s*s\b'), 'slip slip')
      .replaceAll(RegExp(r'\bsx\s*m\b'), 'slip male')
      .replaceAll(RegExp(r'\bsx\s*f\b'), 'slip female')
      .replaceAll(RegExp(r'\bsxm\b'), 'slip male')
      .replaceAll(RegExp(r'\bsxf\b'), 'slip female')
      .replaceAll(RegExp(r'\bslip\s*x\s*mip\b'), 'male adapter')
      .replaceAll(RegExp(r'\bslip\s*x\s*fip\b'), 'female adapter')
      .replaceAll(RegExp(r'\bm\.?i\.?p\.?\b'), 'mip')
      .replaceAll(RegExp(r'\bf\.?i\.?p\.?\b'), 'fip')
      .replaceAll(RegExp(r'\bm\.?p\.?t\.?\b'), 'mpt')
      .replaceAll(RegExp(r'\bf\.?p\.?t\.?\b'), 'fpt')
      .replaceAll(RegExp(r'\bs\s*/\s*j\b'), 'slip joint')
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _expandAliases(String value, {String localePackId = ''}) {
  var expanded = value;
  for (final entry in _localeReceiptTermAliases(localePackId).entries) {
    if (entry.value.any((alias) => _containsAlias(value, alias))) {
      expanded = '$expanded ${entry.key}';
    }
  }
  for (final entry in receiptTermAliases.entries) {
    if (entry.value.any((alias) => _containsAlias(value, alias))) {
      expanded = '$expanded ${entry.key}';
    }
  }
  return expanded;
}

bool _containsAlias(String text, String alias) {
  final normalizedAlias = _normalize(alias);
  if (normalizedAlias.isEmpty) return false;
  return RegExp('(^| )${RegExp.escape(normalizedAlias)}( |\$)').hasMatch(text);
}
