part of 'work_supply_catalog.dart';

List<WorkSupplyMarketScope> _resolvePlumbingMarketScopes(WorkSupplyItem item) {
  final text = _plumbingTierText(item);
  final scopes = <WorkSupplyMarketScope>{WorkSupplyMarketScope.residential};
  if (_hasAny(text, _plumbingLightIndustrialSignals)) {
    scopes.add(WorkSupplyMarketScope.lightIndustrial);
  }
  if (_hasAny(text, _plumbingCommercialOverlapSignals)) {
    scopes.addAll([
      WorkSupplyMarketScope.lightIndustrial,
      WorkSupplyMarketScope.commercial,
    ]);
  }
  if (_hasAny(text, _commercialOnlySignals)) {
    scopes
      ..remove(WorkSupplyMarketScope.residential)
      ..addAll([
        WorkSupplyMarketScope.lightIndustrial,
        WorkSupplyMarketScope.commercial,
      ]);
  }
  return List.unmodifiable(scopes);
}

WorkSupplyPackTier _resolvePlumbingPackTier(WorkSupplyItem item) {
  final text = _plumbingTierText(item);
  if (_isPlumbingCoreItem(item, text)) return WorkSupplyPackTier.core;
  if (_isCommonRegionalWaterTreatmentServiceItem(item, text)) {
    return WorkSupplyPackTier.standard;
  }
  if (_hasPlumbingCompleteTierSignal(text)) return WorkSupplyPackTier.complete;
  if (_hasPlumbingProfessionalSignal(text)) {
    return WorkSupplyPackTier.professional;
  }
  if (_isPlumbingStandardItem(item, text)) return WorkSupplyPackTier.standard;
  return WorkSupplyPackTier.professional;
}

bool _isCommonRegionalWaterTreatmentServiceItem(
  WorkSupplyItem item,
  String text,
) {
  if (item.system.toLowerCase() != 'water treatment service stock') {
    return false;
  }
  return _hasAny(text, [
    'filter cartridge',
    'filter housing wrench',
    'filter housing o-ring',
    'water softener bypass valve',
    'solar salt crystals',
    'water softener salt pellets',
    'potassium chloride softener pellets',
    'rust remover softener salt',
  ]);
}

bool _isPlumbingCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (category == 'service truck stock' &&
      system == 'plumbing hand tools' &&
      _isEverydayResidentialPlumbingHandTool(text)) {
    return true;
  }
  if (category == 'service truck stock' &&
      (system == 'water treatment service stock' ||
          system == 'plumbing hand tools')) {
    return false;
  }
  if (category == 'valves' && _isOversizedPlumbingValveForCore(item)) {
    return false;
  }
  if (category == 'hangers and supports' &&
      _isOversizedPlumbingSupportForCore(item)) {
    return false;
  }
  if (category == 'pumps' &&
      text.contains('check valve') &&
      (_largestPlumbingVariantSize(item.variant) ?? 0) > 1.5) {
    return false;
  }
  if (_hasAny(text, _plumbingAlwaysCoreServiceSignals)) return true;
  if (category == 'service truck stock') return true;
  if (category == 'drain and finish service stock') {
    return _hasAny(text, _plumbingCoreDrainFinishSignals);
  }
  if (category == 'seals packing and thread service') {
    return _hasAny(text, _plumbingCoreSealServiceSignals);
  }
  if (category == 'supply lines' || category == 'consumables') return true;
  if (category == 'fittings' && _isCommonResidentialNoHubRepair(item)) {
    return true;
  }
  if (category == 'fittings' && _isCommonResidentialSupplyClosure(item)) {
    return true;
  }
  if (_hasPlumbingCommercialCoreExclusion(text)) return false;
  if (category == 'fittings' && _isOversizedPlumbingFittingForCore(item)) {
    return false;
  }
  if (category == 'fittings' && type.contains('street')) {
    return false;
  }
  if (category == 'fittings' && type.contains('expanded')) {
    return false;
  }
  if (type.contains('expanded')) return false;
  if (category == 'toilet repair' || category == 'sink and faucet repair') {
    return true;
  }
  if (category == 'drainage waste vent') {
    return _hasAny(text, _plumbingCoreDrainServiceSignals);
  }
  if (category == 'hangers and supports') {
    return _hasAny(text, _plumbingCoreSupportSignals);
  }
  if (category == 'water heater' || category == 'valves') {
    return _hasAny(text, _plumbingCoreValveAndWaterHeaterSignals) ||
        !_hasPlumbingProfessionalSignal(text);
  }
  if (category == 'pumps' && system == 'sump and condensate') {
    return _hasAny(text, [
      'sump pump',
      'pump check valve',
      'discharge hose',
      'float switch',
      'pump discharge adapter',
      'barbed adapter',
      'pvc adapter',
      'condensate pump tubing',
    ]);
  }
  if (category == 'pumps' && system == 'well service') {
    return _hasAny(text, _plumbingCoreWellServiceSignals);
  }
  if (category == 'fittings') {
    if (system == 'abs dwv') {
      return _hasAny(text, _coreDrainSizes) &&
          _hasAny(type, _coreFittingTypes) &&
          _isCommonPlumbingVariant(item.variant);
    }
    if (system == 'copper' || system == 'brass') {
      if (item.variant.toLowerCase().startsWith('2 x')) return false;
      if (system == 'brass' &&
          type.contains('compression union') &&
          (_primaryPlumbingVariantSize(item.variant) ?? 0) == .375) {
        return true;
      }
      return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
          _hasAny(text, _plumbingCoreFittingFamilySignals) &&
          (_hasAny(text, _residentialSupplySizes) || _hasAny(text, ['1 x'])) &&
          _isCommonPlumbingVariant(item.variant);
    }
    if (system == 'pex' || system == 'cpvc' || system == 'push-fit') {
      if (system == 'push-fit' && type.contains('ball valve')) {
        return (_primaryPlumbingVariantSize(item.variant) ?? 0) <= 1;
      }
      return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
          _hasAny(text, _plumbingCoreFittingFamilySignals) &&
          (_hasAny(text, _residentialSupplySizes) || _hasAny(text, ['1 x'])) &&
          _isCommonPlumbingVariant(item.variant);
    }
    if (system == 'black iron' && type.contains('nipple')) {
      return _isCommonResidentialBlackIronNipple(item);
    }
    return _hasAny(text, _plumbingCoreFittingMaterialSignals) &&
        _hasAny(text, _plumbingCoreFittingFamilySignals) &&
        _hasAny(text, _plumbingCoreFittingSizeSignals) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'pex' || system == 'cpvc' || system == 'push-fit') {
    return _hasAny(text, _residentialSupplySizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'pvc schedule 40' ||
      system == 'pvc dwv' ||
      system == 'abs dwv') {
    return _hasAny(text, _coreDrainSizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (system == 'copper' || system == 'brass') {
    return _hasAny(text, _residentialSupplySizes) &&
        _hasAny(type, _coreFittingTypes) &&
        _isCommonPlumbingVariant(item.variant);
  }
  return false;
}

bool _isEverydayResidentialPlumbingHandTool(String text) => _hasAny(text, [
  'pex crimp tool',
  'pex clamp cinch tool',
  'mini tubing cutter',
  'ratcheting pvc pipe cutter',
  'pvc deburring tool',
  'copper pipe reaming tool',
  'inside pipe cutter',
  'basin wrench',
  'strap wrench',
  'closet auger',
  'toilet auger',
  'hand drain auger',
  'small drain snake',
]);

bool _isCommonResidentialNoHubRepair(WorkSupplyItem item) {
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (system != 'cast iron and no-hub') return false;
  if (!type.contains('no-hub coupling') && !type.contains('no-hub band')) {
    return false;
  }
  return const [
    1.5,
    2,
    3,
    4,
  ].contains(_primaryPlumbingVariantSize(item.variant));
}

bool _isCommonResidentialBlackIronNipple(WorkSupplyItem item) {
  if ((_primaryPlumbingVariantSize(item.variant) ?? 0) != .75) return false;
  return RegExp(
    r'\bx\s+(?:close|2|3|4|6)\s*in\b',
  ).hasMatch(item.variant.toLowerCase());
}

bool _isCommonResidentialSupplyClosure(WorkSupplyItem item) {
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (system != 'copper' && system != 'cpvc' && system != 'push-fit') {
    return false;
  }
  if (type.contains('expanded')) return false;
  if (!type.contains('cap') &&
      !type.contains('reducer') &&
      !type.contains('union')) {
    return false;
  }
  return (_primaryPlumbingVariantSize(item.variant) ?? 0) <= 1 &&
      _isCommonPlumbingVariant(item.variant);
}

bool _isOversizedPlumbingFittingForCore(WorkSupplyItem item) {
  final system = item.system.toLowerCase();
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (largestVariantSize == null) return false;
  if (system == 'copper' ||
      system == 'brass' ||
      system == 'pex' ||
      system == 'cpvc' ||
      system == 'push-fit') {
    return largestVariantSize > 1;
  }
  if (system == 'pvc schedule 40') return largestVariantSize > 2;
  if (system == 'pvc dwv' || system == 'abs dwv') return largestVariantSize > 4;
  return false;
}

bool _isOversizedPlumbingValveForCore(WorkSupplyItem item) {
  final largestVariantSize = _largestPlumbingVariantSize(item.variant);
  if (largestVariantSize == null) return false;
  final text = _plumbingTierText(item);
  if (text.contains('ball valve') ||
      text.contains('gate valve') ||
      text.contains('check valve') ||
      text.contains('backwater valve')) {
    return largestVariantSize > 1;
  }
  return false;
}

bool _isOversizedPlumbingSupportForCore(WorkSupplyItem item) {
  final text = _plumbingTierText(item);
  if (text.contains('stud guard') || text.contains('nail plate')) {
    return false;
  }
  final primarySize = _primaryPlumbingVariantSize(item.variant);
  if (primarySize == null) return false;
  return primarySize > 2;
}

double? _primaryPlumbingVariantSize(String variant) {
  final normalized = variant.toLowerCase().trim();
  final leadingBeforeBy = RegExp(
    r'^(\d+-\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)\s*x\b',
  ).firstMatch(normalized);
  if (leadingBeforeBy != null) {
    return _parsePlumbingNumber(leadingBeforeBy.group(1)!);
  }
  final leading = RegExp(
    r'^(\d+-\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)\s*(?:in|inch|")?\b',
  ).firstMatch(normalized);
  if (leading == null) return null;
  return _parsePlumbingNumber(leading.group(1)!);
}

double? _parsePlumbingNumber(String raw) {
  final mixed = RegExp(r'^(\d+)-(\d+)/(\d+)$').firstMatch(raw);
  if (mixed != null) {
    return double.parse(mixed.group(1)!) +
        double.parse(mixed.group(2)!) / double.parse(mixed.group(3)!);
  }
  final fraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(raw);
  if (fraction != null) {
    return double.parse(fraction.group(1)!) / double.parse(fraction.group(2)!);
  }
  return double.tryParse(raw);
}

bool _isPlumbingStandardItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (category == 'fittings') {
    if (type.contains('expanded')) {
      return _isStandardExpandedPlumbingFitting(item, text);
    }
    return _hasAny(text, _standardPlumbingSizes) &&
        _hasAny(system, _standardResidentialSystems) &&
        (_hasAny(type, _standardFittingTypes) ||
            _hasAny(type, _coreFittingTypes)) &&
        _isCommonPlumbingVariant(item.variant);
  }
  if (category == 'pipe and tubing') {
    return _hasAny(text, _standardPlumbingSizes) &&
        _hasAny(system, _standardResidentialSystems);
  }
  if (category == 'drainage waste vent' ||
      category == 'hangers and supports' ||
      category == 'pumps' ||
      category == 'shower and tub repair') {
    return true;
  }
  return !_hasPlumbingProfessionalSignal(text);
}

bool _isStandardExpandedPlumbingFitting(WorkSupplyItem item, String text) {
  final system = item.system.toLowerCase();
  final type = item.itemType.toLowerCase();
  if (!_isCommonPlumbingVariant(item.variant)) return false;
  if (_hasPlumbingProfessionalSignal(text)) return false;
  if (!_hasAny(system, _standardExpandedResidentialSystems)) return false;
  if (!_hasAny(type, _standardExpandedFittingTypes)) return false;
  return _hasAny(text, _standardExpandedResidentialSizes);
}

bool _isCommonPlumbingVariant(String variant) {
  final normalized = variant.toLowerCase().trim();
  if (!normalized.contains(' x ')) return true;
  if (_hasQuarterInchMatrixBranch(normalized)) return false;
  final dimensions = normalized
      .split(RegExp(r'\s+x\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (dimensions.length >= 3) return dimensions.toSet().length == 1;
  const commonMatrices = [
    '1/2 x 1/2',
    '3/4 x 3/4',
    '1 x 1',
    '1-1/4 x 1-1/4',
    '1-1/2 x 1-1/2',
    '2 x 2',
    '3 x 3',
    '3/4 x 1/2',
    '1/2 x 3/8',
    '1 x 3/4',
    '1 x 1/2',
    '1-1/2 x 1-1/4',
    '2 x 1-1/2',
    '3 x 2',
  ];
  return commonMatrices.contains(normalized);
}

double? _largestPlumbingVariantSize(String variant) {
  final values = <double>[];
  final normalized = variant.toLowerCase();
  final mixed = RegExp(r'(\d+)-(\d+)/(\d+)');
  for (final match in mixed.allMatches(normalized)) {
    values.add(
      double.parse(match.group(1)!) +
          double.parse(match.group(2)!) / double.parse(match.group(3)!),
    );
  }
  final withoutMixed = normalized.replaceAll(mixed, ' ');
  final fraction = RegExp(r'(?<!\d)(\d+)/(\d+)(?!\d)');
  for (final match in fraction.allMatches(withoutMixed)) {
    values.add(double.parse(match.group(1)!) / double.parse(match.group(2)!));
  }
  final withoutFractions = withoutMixed.replaceAll(fraction, ' ');
  final whole = RegExp(r'(?<![\d/])(\d+)(?![\d/])');
  for (final match in whole.allMatches(withoutFractions)) {
    values.add(double.parse(match.group(1)!));
  }
  if (values.isEmpty) return null;
  values.sort();
  return values.last;
}

bool _hasQuarterInchMatrixBranch(String normalizedVariant) {
  return normalizedVariant.startsWith('1/4 x ') ||
      normalizedVariant.contains(' x 1/4 x ') ||
      normalizedVariant.endsWith(' x 1/4');
}

bool _hasPlumbingCompleteTierSignal(String text) {
  return _hasAny(text, _plumbingCompleteTermSignals) ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasPlumbingProfessionalSignal(String text) {
  return _hasAny(text, _plumbingProfessionalTermSignals) ||
      _hasStandaloneInchSize(text, '4') ||
      _hasStandaloneInchSize(text, '5') ||
      _hasStandaloneInchSize(text, '6') ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasPlumbingCommercialCoreExclusion(String text) {
  return _hasAny(text, _plumbingCommercialOnlyCoreTermExclusions) ||
      _hasStandaloneInchSize(text, '8') ||
      _hasStandaloneInchSize(text, '10') ||
      _hasStandaloneInchSize(text, '12');
}

bool _hasStandaloneInchSize(String text, String size) {
  if (_hasAny(text, const ['tailpiece', 'extension tube'])) return false;
  final pattern = RegExp('${RegExp.escape(size)}\\s+in\\b');
  for (final match in pattern.allMatches(text)) {
    if (match.start == 0) return true;
    final previous = text[match.start - 1];
    if (!'0123456789/-'.contains(previous)) return true;
  }
  return false;
}
