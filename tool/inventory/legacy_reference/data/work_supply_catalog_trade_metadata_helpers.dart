part of 'work_supply_catalog.dart';

List<String> _hvacCoreFamilyTermsFor(WorkSupplyItem item) {
  final text = item.searchableText;
  if (_hasAny(text, _hvacCoreFilterSignals)) {
    return const ['air filter', 'furnace filter', 'merv filter'];
  }
  if (_hasAny(text, _hvacCoreControlSignals)) {
    return const ['hvac control', 'capacitor', 'contactor', 'relay'];
  }
  if (_hasAny(text, _hvacCoreCondensateSignals)) {
    return const ['condensate', 'condensate drain', 'condensate pump'];
  }
  if (_hasAny(text, _hvacCoreSealSignals)) {
    return const ['hvac tape', 'duct mastic', 'duct sealant'];
  }
  if (_hasAny(text, _hvacCoreAirDistributionSignals)) {
    return const ['duct repair', 'flex duct', 'air distribution'];
  }
  if (_hasAny(text, _hvacCoreIgnitionSignals)) {
    return const ['ignition', 'flame sensor', 'hot surface ignitor'];
  }
  return const ['hvac service stock'];
}

bool _isWaterTreatmentCoreText(String text) {
  return text.contains('water treatment') ||
      text.contains('water filter') ||
      text.contains('filter cartridge') ||
      text.contains('reverse osmosis') ||
      text.contains('softener') ||
      text.contains('salt pellet');
}

bool _isPlumbingCoreMetadataTarget(WorkSupplyItem item) {
  return item.trade == 'Plumbing' &&
      _resolvePlumbingPackTier(item) == WorkSupplyPackTier.core &&
      item.marketScopes.contains(WorkSupplyMarketScope.residential);
}

List<String> _plumbingCoreFamilyTermsFor(WorkSupplyItem item, String shape) {
  final text =
      '${item.name} ${item.itemType} ${item.system} ${item.aliases.join(' ')}'
          .toLowerCase();
  if (text.contains('p-trap') || text.contains('p trap')) {
    return const ['p trap', 'p-trap', 'sink trap', 'lav trap'];
  }
  if (text.contains('fill valve')) {
    return const ['fill valve', 'toilet fill valve', 'ballcock'];
  }
  if (text.contains('tank lever')) {
    return const ['tank lever', 'toilet handle', 'flush lever'];
  }
  if (text.contains('aerator')) {
    return const ['aerator', 'faucet aerator', 'faucet screen'];
  }
  if (text.contains('o-ring') || text.contains('o ring')) {
    return const ['o ring', 'o-ring', 'faucet o ring', 'seal kit'];
  }
  if (text.contains('disposal drain elbow')) {
    return const [
      'disposal drain elbow',
      'disposal elbow',
      'garbage disposal elbow',
    ];
  }
  if (text.contains('disposal install kit')) {
    return const [
      'disposal install kit',
      'disposal kit',
      'garbage disposal connector',
    ];
  }
  if (text.contains('continuous waste')) {
    return const ['continuous waste', 'cont waste', 'double bowl waste'];
  }
  if (text.contains('escutcheon')) {
    return const ['escutcheon', 'esc plate', 'cover plate'];
  }
  if (text.contains('angle stop') || text.contains('supply stop')) {
    return const [
      'angle stop',
      'supply stop',
      'stop valve',
      'quarter turn stop',
    ];
  }
  if (text.contains('supply line')) {
    return const [
      'supply line',
      'toilet supply',
      'faucet supply',
      'connector line',
    ];
  }
  if (text.contains('closet flange')) {
    return const [
      'closet flange',
      'toilet flange',
      'flange repair',
      'flange spacer',
    ];
  }
  if (text.contains('cleanout')) {
    return const ['cleanout', 'clean out', 'cleanout plug', 'cleanout cover'];
  }
  if (text.contains('trap adapter')) {
    return const ['trap adapter', 'trap adpt', 'dwv adapter'];
  }
  if (text.contains('wye')) return const ['wye', 'dwv wye', 'combo wye'];
  if (text.contains('pex')) {
    return const ['pex', 'pex crimp', 'pex barb', 'pex fitting', 'poly pipe'];
  }
  if (text.contains('push-fit') ||
      text.contains('push fit') ||
      text.contains('sharkbite')) {
    return const ['push fit', 'push-fit', 'push connect', 'sharkbite'];
  }
  if (text.contains('cpvc')) return const ['cpvc', 'cpvc flowguard'];
  if (text.contains('water heater')) {
    return const ['water heater', 'wtr htr', 'heater connector', 'heater pan'];
  }
  if (text.contains('pressure tank') || text.contains('tank tee')) {
    return const ['pressure tank', 'well tank', 'tank tee', 'pressure gauge'];
  }
  if (text.contains('softener') || text.contains('filter cartridge')) {
    return const [
      'water softener',
      'softener salt',
      'filter cartridge',
      'water filter',
    ];
  }
  if (text.contains('solder')) {
    return const [
      'lead free solder',
      'plumbing solder',
      'sweat solder',
      'lf solder',
    ];
  }
  if (text.contains('flux')) {
    return const ['solder flux', 'plumbing flux', 'tinning flux', 'paste flux'];
  }
  if (text.contains('acid brush')) {
    return const ['acid brush', 'flux brush', 'solder brush'];
  }
  if (text.contains('fitting brush')) {
    return const [
      'fitting brush',
      'copper fitting brush',
      'tube brush',
      'wire brush',
    ];
  }
  if (text.contains('sand cloth') || text.contains('emery cloth')) {
    return const ['sand cloth', 'emery cloth', 'abrasive cloth'];
  }
  if (text.contains('heat shield')) {
    return const ['heat shield', 'flame protector', 'torch shield'];
  }
  if (text.contains('propane') || text.contains('map-pro')) {
    return const ['torch fuel', 'propane fuel', 'map pro fuel'];
  }
  if (text.contains('torch head')) {
    return const ['torch head', 'solder torch', 'plumbing torch'];
  }
  if (text.contains('j hook') ||
      text.contains('pipe hook') ||
      text.contains('pipe hanger') ||
      text.contains('pipe support')) {
    return const ['j hook', 'pipe hook', 'pipe hanger', 'tube strap'];
  }
  if (text.contains('sanitary tee')) {
    return const ['sanitary tee', 'san tee', 'sanitary t'];
  }
  if (text.contains('reducing coupling')) {
    return const ['reducing coupling', 'reducing cplg', 'reducer coupling'];
  }
  if (text.contains('coupling')) return const ['coupling', 'cplg', 'coupler'];
  if (text.contains('elbow') || shape == 'elbow') {
    return const ['elbow', 'elb', 'ell'];
  }
  if (text.contains('adapter') || shape == 'adapter') {
    return const ['adapter', 'adpt', 'adaptor'];
  }
  if (text.contains('tee') || shape == 'tee') return const ['tee', 't fitting'];
  if (text.contains('valve') || shape == 'valve') return const ['valve'];
  if (text.contains('pipe')) return const ['pipe', 'tube', 'tubing'];
  return _cleanList([item.itemType, shape]);
}

List<String> _plumbingCompactFamilyTermsFor(WorkSupplyItem item, String shape) {
  final terms = _plumbingCoreFamilyTermsFor(item, shape);
  return _cleanList([
    for (final term in terms) _compactPlumbingReceiptTerm(term),
    for (final term in terms)
      if (term.toLowerCase().startsWith('disposal '))
        _compactPlumbingReceiptTerm(term.replaceFirst('disposal', 'disp')),
  ]);
}

String _compactPlumbingReceiptTerm(String value) {
  return value
      .toUpperCase()
      .replaceAll(' COUPLING', ' CPLG')
      .replaceAll(' ADAPTER', ' ADPT')
      .replaceAll(' ELBOW', ' ELB')
      .replaceAll(' CONNECTOR', ' CONN')
      .replaceAll(' DISPOSAL', ' DISP')
      .replaceAll(' TOILET', ' TLT')
      .replaceAll(' FAUCET', ' FCT');
}

List<String> _plumbingSpanishCoreFamilyTermsFor(
  WorkSupplyItem item,
  String shape,
) {
  final text = '${item.name} ${item.itemType} ${item.system}'.toLowerCase();
  if (text.contains('p-trap') || text.contains('p trap')) {
    return const ['trampa p', 'trampa lavabo', 'trampa lavamanos'];
  }
  if (text.contains('fill valve')) {
    return const ['valvula llenado', 'valvula de llenado sanitario'];
  }
  if (text.contains('tank lever')) {
    return const ['palanca tanque', 'manija sanitario'];
  }
  if (text.contains('aerator')) return const ['aireador', 'aireador grifo'];
  if (text.contains('o-ring') || text.contains('o ring')) {
    return const ['o ring', 'empaque llave', 'sello llave'];
  }
  if (text.contains('disposal')) {
    return const ['triturador', 'codo triturador', 'kit triturador'];
  }
  if (text.contains('escutcheon')) return const ['chapeton', 'placa cubierta'];
  if (text.contains('angle stop') || text.contains('supply stop')) {
    return const ['llave escuadra', 'valvula cierre', 'valvula angular'];
  }
  if (text.contains('supply line')) {
    return const ['linea suministro', 'manguera suministro'];
  }
  if (text.contains('closet flange')) {
    return const ['brida sanitario', 'brida inodoro'];
  }
  if (text.contains('cleanout')) {
    return const ['registro limpieza', 'tapon limpieza'];
  }
  if (text.contains('trap adapter')) return const ['adaptador trampa'];
  if (text.contains('wye')) return const ['yee sanitaria', 'conector yee'];
  if (text.contains('pex')) return const ['pex', 'conexion pex'];
  if (text.contains('push-fit') ||
      text.contains('push fit') ||
      text.contains('sharkbite')) {
    return const ['conexion rapida', 'push fit'];
  }
  if (text.contains('cpvc')) return const ['cpvc'];
  if (text.contains('water heater')) {
    return const ['calentador agua', 'conector calentador'];
  }
  if (text.contains('pressure tank') || text.contains('tank tee')) {
    return const ['tanque presion', 'tee tanque', 'pozo'];
  }
  if (text.contains('softener') || text.contains('filter cartridge')) {
    return const ['suavizador agua', 'sal suavizador', 'filtro agua'];
  }
  if (text.contains('solder')) return const ['soldadura plomeria'];
  if (text.contains('flux')) return const ['fundente soldadura'];
  if (text.contains('acid brush') || text.contains('fitting brush')) {
    return const ['cepillo soldadura', 'cepillo cobre'];
  }
  if (text.contains('sand cloth') || text.contains('emery cloth')) {
    return const ['tela esmeril', 'lija plomero'];
  }
  if (text.contains('heat shield')) return const ['protector calor'];
  if (text.contains('propane') || text.contains('map-pro')) {
    return const ['gas soplete', 'combustible soplete'];
  }
  if (text.contains('torch head')) return const ['cabezal soplete'];
  if (text.contains('j hook') ||
      text.contains('pipe hook') ||
      text.contains('pipe hanger') ||
      text.contains('pipe support')) {
    return const ['soporte tubo', 'gancho tubo'];
  }
  if (text.contains('sanitary tee')) {
    return const ['tee sanitaria', 't sanitaria'];
  }
  if (text.contains('coupling')) return const ['cople', 'acople'];
  if (text.contains('elbow') || shape == 'elbow') return const ['codo'];
  if (text.contains('adapter') || shape == 'adapter') {
    return const ['adaptador'];
  }
  if (text.contains('valve') || shape == 'valve') return const ['valvula'];
  return const ['plomeria residencial'];
}

List<String> _riskConflictNegativeMatchTokensFor(
  WorkSupplyItem item,
  String text,
) {
  final trade = item.trade.toLowerCase();
  final riskTerms = _catalogRiskTermsFor(item, text);
  return _cleanList([
    if (riskTerms.contains('pvc') && trade != 'plumbing') 'plumbing pvc pipe',
    if (riskTerms.contains('pvc') && trade != 'electrical') 'pvc conduit',
    if (riskTerms.contains('pvc') && trade != 'hvac') 'hvac condensate pvc',
    if (riskTerms.contains('pipe') && trade != 'plumbing') 'plumbing pipe',
    if (riskTerms.contains('pipe') && trade != 'electrical') 'conduit pipe',
    if (riskTerms.contains('connector')) 'electrical connector',
    if (riskTerms.contains('connector')) 'framing connector',
    if (_containsWord(text, 'connectors')) 'electrical connector',
    if (_containsWord(text, 'connectors')) 'framing connector',
    if (riskTerms.contains('kit')) 'generic kit',
    if (riskTerms.contains('kit')) 'assortment kit',
    if (riskTerms.contains('cement')) 'pvc cement',
    if (riskTerms.contains('cement')) 'masonry cement',
    if (riskTerms.contains('primer')) 'pvc primer',
    if (riskTerms.contains('primer')) 'paint primer',
    if (riskTerms.contains('filter')) 'hvac air filter',
    if (riskTerms.contains('filter')) 'water filter',
    if (_hasFinishFilterCollisionRisk(item, text)) 'hvac air filter',
    if (_hasFinishFilterCollisionRisk(item, text)) 'water filter',
    if (riskTerms.contains('tape')) 'electrical tape',
    if (riskTerms.contains('tape')) 'drywall tape',
    if (riskTerms.contains('box')) 'electrical box',
    if (riskTerms.contains('box')) 'storage box',
    if (riskTerms.contains('gauge')) 'tire pressure gauge',
    if (riskTerms.contains('gauge')) 'air compressor gauge',
    if (riskTerms.contains('gauge')) 'fuel pressure gauge',
    if (riskTerms.contains('tank')) 'propane tank',
    if (riskTerms.contains('tank')) 'fuel tank',
    if (riskTerms.contains('tank')) 'air compressor tank',
    if (riskTerms.contains('valve')) 'plumbing valve',
    if (riskTerms.contains('valve')) 'gas valve',
  ]);
}

bool _hasFinishFilterCollisionRisk(WorkSupplyItem item, String text) {
  final haystack = [
    text,
    item.name,
    item.category,
    item.system,
    item.itemType,
    item.variant,
  ].join(' ').toLowerCase();
  return _containsWord(haystack, 'finish') ||
      _containsWord(haystack, 'blade') ||
      _containsWord(haystack, 'abrasive') ||
      _containsWord(haystack, 'underlayment') ||
      _containsWord(haystack, 'sandpaper');
}

bool _containsWord(String text, String word) {
  return RegExp(
    '(^|[^a-z0-9])${RegExp.escape(word)}([^a-z0-9]|\$)',
  ).hasMatch(text.toLowerCase());
}

Set<String> _catalogRiskTermsFor(WorkSupplyItem item, String text) {
  const risks = {
    'box',
    'cement',
    'connector',
    'filter',
    'gauge',
    'kit',
    'pipe',
    'primer',
    'pvc',
    'tank',
    'tape',
    'valve',
  };
  final tokens = _cleanList(
    [
      text,
      item.name,
      item.category,
      item.system,
      item.itemType,
      item.variant,
      ...item.aliases,
    ].join(' ').toLowerCase().split(RegExp(r'[^a-z0-9/.-]+')),
  );
  return risks
      .where(tokens.map((token) => token.toLowerCase()).contains)
      .toSet();
}

bool _needsManualReview(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  if (item.trade == 'Plumbing') {
    return _plumbingNeedsManualReview(item, material, size, shape);
  }
  if (item.trade == 'Electrical') {
    return _electricalNeedsManualReview(item, material, size, shape);
  }
  final text = item.searchableText;
  return material.isEmpty ||
      (size.isEmpty &&
          _hasAny(text, _coreTierSignals) &&
          !_hasAny(text, _genericSizeOptionalSignals)) ||
      shape.isEmpty;
}

const _genericSizeOptionalSignals = [
  'kit',
  'assortment',
  'terminal',
  'compound',
  'sealant',
  'pipe dope',
  'tape',
  'spray',
  'tablet',
  'adapter',
  'wrench',
  'hose set',
  'clip',
  'latch',
  'gasket',
  'flame sensor',
  'line hide',
  'phos copper',
  'standard pack',
  'condensate trap',
  'vent condensate drain tee',
  'flow meter',
  'actuator',
  'air vent',
  'vent tee',
  'putty',
];

List<String> _cleanList(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) continue;
    final key = cleaned.toLowerCase();
    if (seen.add(key)) result.add(cleaned);
  }
  return List.unmodifiable(result);
}
