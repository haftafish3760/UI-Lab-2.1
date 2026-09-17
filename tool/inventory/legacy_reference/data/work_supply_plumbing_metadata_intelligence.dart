part of 'work_supply_catalog.dart';

String _resolvePlumbingMaterial(WorkSupplyItem item, String text) {
  final direct = _firstMatched(text, _materialSignals);
  if (direct.isNotEmpty) return direct;
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  final variant = item.variant.toLowerCase();
  final source = '$system $type $variant';
  for (final entry in _plumbingSystemMaterialSignals.entries) {
    if (source.contains(entry.key)) return entry.value;
  }
  if (_hasAny(source, _mixedMaterialSignals)) return 'mixed material';
  if (_hasAny(source, _finishOnlySignals)) return 'finish-specific';
  return '';
}

String _resolvePlumbingSize(WorkSupplyItem item, String text) {
  final direct = _extractSize(text);
  if (direct.isNotEmpty) return direct;
  final source = '${item.variant} ${item.name}'.toLowerCase();
  final matrix = RegExp(
    r'\b\d+(?:-\d+/\d+|/\d+)?(?:\.\d+)?(?:\s*x\s*\d+(?:-\d+/\d+|/\d+)?(?:\.\d+)?){1,2}\b',
  ).firstMatch(source);
  if (matrix != null) return matrix.group(0)!.trim();
  final threaded = RegExp(r'\b\d{1,2}/\d{1,2}-\d{1,2}\b').firstMatch(source);
  if (threaded != null) return threaded.group(0)!.trim();
  final closeNipple = RegExp(
    r'\b\d+(?:-\d+/\d+|/\d+)?(?:\.\d+)?\s*x\s*close\b',
  ).firstMatch(source);
  if (closeNipple != null) return closeNipple.group(0)!.trim();
  final measured = RegExp(
    r'\b\d+(?:\.\d+)?\s*(?:gal|gallon|gpm|watt|volt|ft|feet|qt|quart)\b',
  ).firstMatch(source);
  if (measured != null) return measured.group(0)!.trim();
  final compactMeasured = RegExp(
    r'\b\d+(?:-\d+/\d+|/\d+)?(?:\.\d+)?\s*(?:hp|oz|v)\b',
  ).firstMatch(source);
  if (compactMeasured != null) return compactMeasured.group(0)!.trim();
  return '';
}

String _resolvePlumbingShape(WorkSupplyItem item, String text) {
  final direct = _firstMatched(text, _shapeSignals);
  if (direct.isNotEmpty) return direct;
  final source = '${item.system} ${item.itemType} ${item.name}'.toLowerCase();
  for (final entry in _plumbingShapeSignals.entries) {
    if (source.contains(entry.key)) return entry.value;
  }
  return '';
}

bool _plumbingNeedsManualReview(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  final text = item.searchableText;
  final missingRequiredSize =
      size.isEmpty &&
      _hasAny(text, _coreTierSignals) &&
      !_plumbingCanOmitSize(item);
  final missingRequiredMaterial =
      material.isEmpty && !_plumbingCanOmitMaterial(item);
  return missingRequiredMaterial || missingRequiredSize || shape.isEmpty;
}

bool _plumbingCanOmitSize(WorkSupplyItem item) {
  final text = item.searchableText;
  return _hasAny(text, _plumbingNaturallyUnsizedSignals);
}

bool _plumbingCanOmitMaterial(WorkSupplyItem item) {
  final text = item.searchableText;
  return _hasAny(text, _plumbingMaterialOptionalSignals);
}

const _plumbingSystemMaterialSignals = {
  'push-fit': 'push-fit',
  'pvc schedule 40': 'PVC',
  'pvc dwv': 'PVC DWV',
  'abs dwv': 'ABS DWV',
  'abs': 'ABS',
  'cpvc': 'CPVC',
  'pex': 'PEX',
  'copper': 'copper',
  'brass': 'brass',
  'black iron': 'black iron',
  'galvanized steel': 'galvanized steel',
  'cast iron': 'cast iron',
  'no-hub': 'cast iron',
  'rubber': 'rubber',
  'neoprene': 'neoprene',
  'ptfe': 'PTFE',
  'graphite': 'graphite',
  'wax': 'wax',
  'plastic': 'plastic',
  'poly': 'polymer',
  'stainless': 'stainless steel',
  'ball valve': 'mixed valve material',
  'gate valve': 'mixed valve material',
  'check valve': 'mixed valve material',
  'backwater valve': 'mixed valve material',
  'shutoff': 'mixed valve material',
  'angle stop': 'mixed valve material',
  'straight stop': 'mixed valve material',
  'hose bibb': 'mixed valve material',
  'sillcock': 'mixed valve material',
  'pressure reducing valve': 'mixed valve material',
  'vacuum breaker': 'mixed valve material',
  'cleanout cover': 'cover material',
  'floor drain grate': 'grate material',
  'strainer': 'strainer material',
  'sediment bucket': 'bucket material',
  'escutcheon': 'finish-specific',
  'pipe strap': 'support-specific material',
  'riser clamp': 'support-specific material',
  'split ring hanger': 'support-specific material',
  'j-hook': 'support-specific material',
  'bell hanger': 'support-specific material',
  'threaded rod': 'zinc-plated steel',
  'all thread': 'zinc-plated steel',
  'rod and strut hardware': 'zinc-plated steel',
  'rod nuts washers and strut hardware': 'zinc-plated steel',
  'hex nut': 'zinc-plated steel',
  'fender washer': 'zinc-plated steel',
  'flat washer': 'zinc-plated steel',
  'rod coupling nut': 'zinc-plated steel',
  'strut nut': 'zinc-plated steel',
  'concrete screws and masonry anchors': 'coated steel',
  'concrete screw anchor': 'coated steel',
  'masonry screw': 'coated steel',
  'rod hanger anchor': 'steel anchor',
  'drop-in anchor': 'steel anchor',
  'wedge anchor': 'steel anchor',
  'beam clamp': 'zinc-plated steel',
  'ceiling flange': 'zinc-plated steel',
  'stud guard': 'steel',
  'pipe insulation': 'foam',
  'pump': 'pump assembly',
  'float switch': 'switch assembly',
  'corrugated connector': 'stainless steel',
  'water heater connector': 'stainless steel',
  'anode rod': 'anode material',
  'drain pan': 'pan material',
  'earthquake strap': 'steel',
  'seismic strap': 'steel',
  'trap adapters': 'tubular drain material',
  'tubular drain': 'tubular drain material',
  'closet flange': 'flange material',
  'thread sealant': 'thread sealant',
  'pipe joint compound': 'thread sealant',
  'pipe dope': 'thread sealant',
  'thread tape': 'PTFE tape',
  'plumber putty': 'plumber putty',
  'plumber\'s putty': 'plumber putty',
  'shower cartridge': 'cartridge material',
  'cartridge': 'cartridge material',
  'waste and overflow': 'drain trim assembly',
  'closet bolt': 'closet bolt material',
  'tub spout': 'fixture trim material',
  'shower head': 'fixture trim material',
  'tub drain shoe': 'tub drain material',
  'trap primer adapter': 'trap primer material',
  'corrugated drain pipe': 'corrugated drain material',
  'stub-out': 'copper',
  'silicone sealant': 'silicone',
  'pipe lubricant': 'pipe lubricant',
  'flange spacer': 'flange spacer material',
  'basket strainer': 'strainer material',
  'tub drain stopper': 'tub drain stopper material',
  'shower arm': 'fixture trim material',
};

const _plumbingShapeSignals = {
  'pipe and tubing': 'pipe',
  'pipe': 'pipe',
  'tubing': 'tubing',
  'supply connector': 'supply line',
  'connector': 'connector',
  'extension tube': 'extension tube',
  'stub-out': 'stub-out',
  'trap primer adapter': 'trap primer adapter',
  'drain shoe': 'drain shoe',
  'basket strainer': 'basket strainer',
  'drain stopper': 'drain stopper',
  'shower arm': 'shower arm',
  'cross': 'cross',
  'wye': 'wye',
  'supply line': 'supply line',
  'supply stop': 'supply stop',
  'stop valve': 'stop valve',
  'angle stop': 'angle stop',
  'straight stop': 'straight stop',
  'cleanout': 'cleanout',
  'cover': 'cover',
  'grate': 'grate',
  'strainer': 'strainer',
  'sediment bucket': 'sediment bucket',
  'tailpiece': 'tailpiece',
  'aerator': 'aerator',
  'cartridge': 'cartridge',
  'stem': 'stem',
  'seat': 'seat',
  'seal': 'seal',
  'gasket': 'gasket',
  'packing': 'packing',
  'tape': 'tape',
  'compound': 'compound',
  'putty': 'putty',
  'hanger': 'hanger',
  'support': 'support',
  'strap': 'strap',
  'threaded rod': 'threaded rod',
  'rod and strut hardware': 'rod hardware',
  'rod coupling nut': 'coupling nut',
  'strut nut': 'strut nut',
  'concrete screw anchor': 'concrete screw anchor',
  'drop-in anchor': 'drop-in anchor',
  'wedge anchor': 'wedge anchor',
  'beam clamp': 'beam clamp',
  'ceiling flange': 'ceiling flange',
  'guard plate': 'guard plate',
  'stud guard': 'guard plate',
  'insulation': 'insulation',
  'air gap': 'air gap',
  'disposal': 'disposal part',
  'splash guard': 'splash guard',
  'spout': 'spout',
  'flapper': 'flapper',
  'fill valve': 'fill valve',
  'flush valve': 'flush valve',
  'tank lever': 'tank lever',
  'closet bolt': 'closet bolt',
  'bolt': 'bolt',
  'nut': 'nut',
  'ferrule': 'ferrule',
  'sleeve': 'sleeve',
  'handle': 'handle',
  'pop-up': 'pop-up assembly',
  'waste and overflow': 'waste and overflow',
  'tub spout': 'tub spout',
  'shower head': 'shower head',
  'escutcheon': 'escutcheon',
  'expansion tank': 'expansion tank',
  'anode rod': 'anode rod',
  'element': 'heating element',
  'thermostat': 'thermostat',
  'relief valve': 'relief valve',
  'drain valve': 'drain valve',
  'dielectric nipple': 'dielectric nipple',
  'pan': 'pan',
  'bracket': 'bracket',
  'sediment trap': 'sediment trap',
  'pump': 'pump',
  'float switch': 'float switch',
  'hose': 'hose',
  'hand tool': 'tool',
  'tubing cutter': 'tool',
  'pipe cutter': 'tool',
  'deburring tool': 'tool',
};

const _mixedMaterialSignals = [
  'kit',
  'repair',
  'assortment',
  'assorted',
  'faucet',
  'toilet',
  'fixture',
  'water heater',
  'disposal',
];

const _finishOnlySignals = [
  'chrome',
  'brushed nickel',
  'matte black',
  'oil rubbed bronze',
  'white',
  'almond',
];

const _plumbingNaturallyUnsizedSignals = [
  'cartridge',
  'stem',
  'seat',
  'seal',
  'gasket',
  'packing',
  'ptfe tape',
  'pipe joint compound',
  'putty',
  'air gap',
  'splash guard',
  'tank lever',
  'flapper',
  'fill valve',
  'flush valve',
  'thermostat',
  'repair kit',
  'assortment',
  'assorted',
  'waste and overflow',
  'trip lever',
  'toe touch',
  'lift and turn',
  'tub drain shoe',
  'tub drain stopper',
  'basket strainer',
  'closet bolt',
  'repair ring',
  'pop-up',
  'tub spout',
  'shower head',
  'mounting bracket',
  'earthquake strap',
  'gas sediment trap',
  'handle screw',
  'oval handle',
  'lever handle',
  'compression sleeve puller',
  'escutcheon',
  'hand tool',
  'tubing cutter',
  'pipe cutter',
  'deburring tool',
];

const _plumbingMaterialOptionalSignals = [
  'mixed material',
  'finish-specific',
  'repair kit',
  'assortment',
  'assorted',
  'hand tool',
  'tool',
];
