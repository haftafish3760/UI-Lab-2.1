part of 'work_supply_catalog.dart';

const _catalogIntelligenceVersion = 'catalog-intelligence-2026-06-29';
const _parserRuleVersion = 'parser-rules-2026-06-29';

List<WorkSupplyMarketScope> _resolveWorkSupplyMarketScopes(
  WorkSupplyItem item,
) {
  if (item.trade == 'Plumbing') return _resolvePlumbingMarketScopes(item);
  final text = _workSupplyTierText(item);
  final scopes = <WorkSupplyMarketScope>{WorkSupplyMarketScope.residential};
  if (_hasAny(text, _lightIndustrialSignals)) {
    scopes.add(WorkSupplyMarketScope.lightIndustrial);
  }
  if (_hasAny(text, _commercialSignals)) {
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

WorkSupplyPackTier _resolveWorkSupplyPackTier(WorkSupplyItem item) {
  if (item.trade == 'Plumbing') return _resolvePlumbingPackTier(item);
  final text = _workSupplyTierText(item);
  if (item.trade == 'Electrical') {
    if (_isElectricalLowVoltageCoreCable(text)) return WorkSupplyPackTier.core;
    if (_isElectricalResidentialDisconnect(item)) {
      return WorkSupplyPackTier.core;
    }
    if (_isElectricalCoreItem(item, text)) return WorkSupplyPackTier.core;
    if (_hasAny(text, _electricalProfessionalTierSignals)) {
      return WorkSupplyPackTier.professional;
    }
    if (_hasAny(text, _completeTierSignals)) return WorkSupplyPackTier.complete;
    return WorkSupplyPackTier.standard;
  }
  if (_hasAny(text, _completeTierSignals)) return WorkSupplyPackTier.complete;
  if (item.trade == 'HVAC') {
    if (_isHvacCoreItem(item, text)) return WorkSupplyPackTier.core;
    if (_hasAny(text, _hvacProfessionalTierSignals)) {
      return WorkSupplyPackTier.professional;
    }
    return WorkSupplyPackTier.standard;
  }
  if (_isEverydayNonPlumbingCore(item, text)) return WorkSupplyPackTier.core;
  if (_hasAny(text, _professionalTierSignals)) {
    return WorkSupplyPackTier.professional;
  }
  if (_hasAny(text, _coreTierSignals)) return WorkSupplyPackTier.core;
  return WorkSupplyPackTier.standard;
}

WorkSupplyParserPriority _resolveWorkSupplyParserPriority(WorkSupplyItem item) {
  if (item.trade == 'Plumbing') {
    return switch (_resolvePlumbingPackTier(item)) {
      WorkSupplyPackTier.core => WorkSupplyParserPriority.everydayCore,
      WorkSupplyPackTier.standard => WorkSupplyParserPriority.common,
      WorkSupplyPackTier.professional => WorkSupplyParserPriority.occasional,
      WorkSupplyPackTier.complete => WorkSupplyParserPriority.specialty,
    };
  }
  final text = item.searchableText;
  if (_hasAny(text, _completeTierSignals)) {
    return WorkSupplyParserPriority.specialty;
  }
  if (item.trade == 'Electrical') {
    if (_isElectricalCoreItem(item, text)) {
      return WorkSupplyParserPriority.everydayCore;
    }
    if (_hasAny(text, _electricalProfessionalTierSignals)) {
      return WorkSupplyParserPriority.occasional;
    }
    return WorkSupplyParserPriority.common;
  }
  if (item.trade == 'HVAC') {
    if (_isHvacCoreItem(item, text)) {
      return WorkSupplyParserPriority.everydayCore;
    }
    if (_hasAny(text, _hvacProfessionalTierSignals)) {
      return WorkSupplyParserPriority.occasional;
    }
    return WorkSupplyParserPriority.common;
  }
  if (_isEverydayNonPlumbingCore(item, text)) {
    return WorkSupplyParserPriority.everydayCore;
  }
  if (_hasAny(text, _professionalTierSignals)) {
    return WorkSupplyParserPriority.occasional;
  }
  if (_hasAny(text, _coreTierSignals)) {
    return WorkSupplyParserPriority.everydayCore;
  }
  return WorkSupplyParserPriority.common;
}

String _workSupplyTierText(WorkSupplyItem item) =>
    '${item.name} ${item.category} ${item.system} ${item.itemType} ${item.variant}'
        .toLowerCase();

bool _isElectricalLowVoltageCoreCable(String text) {
  return _hasAny(text, ['low voltage cable', 'thermostat wire', 'stat wire']) &&
      _hasAny(text, ['18/2', '18/4', '18/5', '16/2', '14/2']) &&
      !text.contains('500 ft');
}

bool _isElectricalResidentialDisconnect(WorkSupplyItem item) {
  final text = '${item.name} ${item.variant} ${item.itemType} ${item.system}'
      .toLowerCase();
  return _hasAny(text, ['disconnect', 'non-fusible', 'fusible', 'pullout']) &&
      _hasAny(text, ['30 amp', '60 amp']) &&
      !_hasAny(text, ['100 amp', '200 amp', 'safety switch']);
}

bool _isEverydayNonPlumbingCore(WorkSupplyItem item, String text) {
  if (item.trade == 'HVAC' && text.contains('condensate pump')) return true;
  return false;
}

bool _isElectricalCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  if (category == 'bulk electrical catalog pack') {
    if (_hasAny(text, ['mc cable', 'armored cable']) &&
        _hasAny(text, ['14/2', '12/2', '10/2'])) {
      return _isCommonElectricalCableRoll(item);
    }
    if (_hasAny(text, ['flexible raceway', 'flexible metal', 'fmc']) &&
        _hasExactElectricalSize(text, const ['3/8', '1/2', '3/4', '1'])) {
      return _isCommonElectricalFlexibleRaceway(item);
    }
    if (text.contains('photocell')) return _isCommonElectricalPhotocell(item);
    if (_hasAny(text, ['wall plate', 'cover plate', 'blank plate']) &&
        !_hasAny(text, ['4 gang', '5 gang', '6 gang'])) {
      return _isCommonElectricalWallPlate(item);
    }
    return _isExpandedElectricalServiceCore(item, system, text);
  }
  if (category == 'expanded electrical service stock' ||
      category == 'electrical core supplemental service stock') {
    return _isExpandedElectricalServiceCore(item, system, text);
  }
  if (category == 'wire and cable') {
    if (system == 'nm-b cable') return _hasAny(text, _electricalCoreCableSizes);
    if (system == 'conduit wire') {
      return _hasAny(text, _electricalCoreWireSizes);
    }
  }
  if (category == 'devices') return _hasAny(text, _electricalCoreDeviceSignals);
  if (category == 'breakers') {
    return _hasAny(text, _electricalCoreBreakerSignals);
  }
  if (category == 'panels and service equipment') {
    return _hasAny(text, _electricalCoreServiceEquipmentSignals);
  }
  if (category == 'boxes and covers') {
    return _hasAny(text, _electricalCoreBoxSignals);
  }
  if (category == 'connectors and consumables') {
    return _hasAny(text, _electricalCoreConsumableSignals);
  }
  if (category == 'grounding and bonding') {
    return _hasAny(text, _electricalCoreConsumableSignals) ||
        _hasAny(text, _electricalCoreGroundingSignals);
  }
  if (category == 'lighting') {
    return _hasAny(text, _electricalCoreLightingSignals);
  }
  if (category == 'conduit and fittings') {
    return _hasAny(text, _electricalCoreRacewaySignals) &&
        _hasExactElectricalSize(text, const ['1/2', '3/4', '1']);
  }
  return false;
}

bool _isExpandedElectricalServiceCore(
  WorkSupplyItem item,
  String system,
  String text,
) {
  if (system == 'expanded wire and cable') {
    if (text.contains('service entrance')) return false;
    if (_hasAny(text, ['uf-b cable', 'underground feeder', 'direct burial']) &&
        _hasAny(text, ['14/2', '14/3', '12/2', '12/3', '10/2', '10/3'])) {
      return _isCommonElectricalCableRoll(item);
    }
    if (_hasAny(text, ['mc cable', 'armored cable']) &&
        _hasAny(text, ['14/2', '12/2', '10/2'])) {
      return _isCommonElectricalCableRoll(item);
    }
    if (_hasAny(text, ['thhn copper wire', 'thwn', 'building wire']) &&
        _hasAny(text, _electricalCoreWireSizes)) {
      return _isCommonElectricalCableRoll(item);
    }
    return _hasAny(text, _electricalCoreCableSignals) &&
        !_hasAny(text, _electricalLargeWireSignals);
  }
  if (system == 'expanded breakers and disconnects') {
    return (_hasAny(text, _electricalCoreBreakerSignals) ||
            _hasAny(text, _electricalCoreServiceEquipmentSignals)) &&
        !text.contains('safety switch') &&
        !text.contains('100 amp') &&
        !text.contains('200 amp');
  }
  if (system == 'expanded devices and plates') {
    if (item.itemType == 'Expanded Wall Plates') {
      return _isCommonElectricalWallPlate(item);
    }
    return _hasAny(text, _electricalCoreDeviceSignals) ||
        _hasAny(text, _electricalCoreBoxSignals) ||
        _hasAny(text, _electricalCoreFixtureSignals);
  }
  if (system == 'device box and plate service stock') {
    return _hasAny(text, _electricalCoreBoxSignals);
  }
  if (system == 'cable connector and wire termination stock') {
    return _hasAny(text, _electricalCoreConsumableSignals);
  }
  if (system == 'breaker and panel service stock') {
    return _hasAny(text, _electricalCoreBreakerSignals) ||
        _hasAny(text, _electricalCoreServiceEquipmentSignals) ||
        _hasAny(text, [
          'plug fuse',
          'cartridge fuse',
          'fuse pair',
          'surge protector',
          'ground bar kit',
          'neutral bar kit',
          'bonding screw',
          'panel screw',
          'handle tie',
        ]);
  }
  if (system == 'residential safety and control stock') {
    return _hasAny(text, _electricalCoreFixtureSignals) ||
        _hasAny(text, _electricalCoreDeviceSignals) ||
        _hasAny(text, _electricalCoreLightingSignals);
  }
  if (system == 'grounding bonding and small hardware stock') {
    return _hasAny(text, _electricalCoreGroundingSignals) ||
        _hasAny(text, ['anti oxidant', 'noalox', 'split bolt']);
  }
  if (system == 'expanded boxes and covers') {
    return _hasAny(text, _electricalCoreBoxSignals) &&
        !_hasAny(text, _electricalLargeBoxSignals);
  }
  if (system == 'expanded raceway and fittings') {
    if (_hasAny(text, _electricalCoreServiceEquipmentSignals)) return true;
    if (_hasAny(text, _electricalServiceEntranceSignals)) return false;
    if (item.itemType == 'Expanded Conduit Bodies and Covers') {
      return _isCommonElectricalConduitBody(item);
    }
    return _hasAny(text, _electricalCoreRacewaySignals) &&
        _hasExactElectricalSize(text, const ['1/2', '3/4', '1']);
  }
  if (system == 'expanded connectors grounding and consumables') {
    return _hasAny(text, _electricalCoreConsumableSignals) ||
        _hasAny(text, _electricalCoreGroundingSignals);
  }
  if (system == 'expanded lighting and lamps') {
    return _hasAny(text, _electricalCoreLightingSignals);
  }
  return false;
}

bool _isHvacCoreItem(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  if (_isHvacSpecialtyCategoryForCore(item, text)) return false;
  if (category == 'hvac core supplemental service stock') return true;
  if (category == 'air filters' || system == 'expanded air filters') {
    return _hasAny(text, _hvacCoreFilterSignals);
  }
  if (_hasAny(text, _hvacCoreCondensateSignals)) return true;
  if (_hasAny(text, _hvacCoreSealSignals)) return true;
  if (_hasAny(text, _hvacCoreIgnitionSignals)) return true;
  if (_hasAny(text, _hvacCoreControlSignals)) return true;
  if (_hasAny(text, _hvacCoreAirDistributionSignals)) return true;
  if (_hasAny(text, _hvacProfessionalTierSignals)) return false;
  if (category == 'controls and electrical') {
    return _hasAny(text, _hvacCoreControlSignals);
  }
  if (category == 'condensate') {
    return _hasAny(text, _hvacCoreCondensateSignals);
  }
  if (category == 'tape and sealants') {
    return _hasAny(text, _hvacCoreSealSignals);
  }
  if (category == 'motors and blower parts') {
    return _hasAny(text, _hvacCoreMotorSignals);
  }
  if (category == 'ignition and gas heat') {
    return _hasAny(text, _hvacCoreIgnitionSignals);
  }
  if (system.contains('service truck') || text.contains('service truck')) {
    return _hasAny(text, _hvacCoreServiceTruckSignals);
  }
  return false;
}

List<String> _resolveWorkSupplyAliases(WorkSupplyItem item) {
  final text = item.searchableText;
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalSize(item, text)
      : _extractSize(text);
  final material = item.trade == 'Plumbing'
      ? _resolvePlumbingMaterial(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalShape(item, text)
      : _firstMatched(text, _shapeSignals);
  final compactShape = _compactAliasShape(shape);
  return _cleanList([
    ...item.aliases,
    item.name,
    ..._spanishSignalsFor(item, material, size, shape),
    ..._electricalCoreAliasTermsFor(item, material, size, shape),
    if (item.variant.isNotEmpty) '${item.variant} ${item.itemType}',
    if (size.isNotEmpty || material.isNotEmpty || compactShape.isNotEmpty)
      '$size $material $compactShape',
    if (size.isNotEmpty && compactShape.isNotEmpty) '$size $compactShape',
    if (material.isNotEmpty && compactShape.isNotEmpty)
      '$material $compactShape',
    if (size.isNotEmpty && material.isNotEmpty && item.itemType.isNotEmpty)
      '$size $material ${item.itemType}',
    if (item.itemType.isNotEmpty) item.itemType,
  ]).take(10).toList(growable: false);
}

String _compactAliasShape(String shape) {
  final value = shape.toLowerCase();
  if (value == 'elbow') return 'elb';
  if (value == 'tee') return 'tee';
  if (value == 'coupling') return 'cplg';
  if (value == 'adapter') return 'adpt';
  if (value == 'connector') return 'conn';
  return shape;
}

WorkSupplyItemIntelligence _resolveWorkSupplyItemIntelligence(
  WorkSupplyItem item,
) {
  if (_hasMeaningfulIntelligence(item.intelligence)) return item.intelligence;
  final text = item.searchableText;
  final material = item.trade == 'Plumbing'
      ? _resolvePlumbingMaterial(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalMaterial(item, text)
      : _firstMatched(text, _materialSignals);
  final size = item.trade == 'Plumbing'
      ? _resolvePlumbingSize(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalSize(item, text)
      : _extractSize(text);
  final connectionType = _firstMatched(text, _connectionSignals);
  final shape = item.trade == 'Plumbing'
      ? _resolvePlumbingShape(item, text)
      : item.trade == 'Electrical'
      ? _resolveElectricalShape(item, text)
      : _firstMatched(text, _shapeSignals);
  final packQuantity = _extractPackQuantity(text);
  return WorkSupplyItemIntelligence(
    material: material,
    size: size,
    connectionType: connectionType,
    shapeOrStyle: shape,
    packQuantity: packQuantity.isEmpty ? '1 each' : packQuantity,
    isConsumable: _hasAny(text, _consumableSignals),
    isDurable: !_hasAny(text, _consumableSignals),
    isBrandSpecific: _hasAny(text, _brandSignals),
    receiptPatterns: _receiptPatternsFor(item, material, size, shape),
    ocrMistakePatterns: _ocrLikeMistakePatternsFor(text),
    vendorMappings: _vendorMappingsFor(item, material, size, shape),
    attributeTokens: _attributeTokensFor(item, material, size, connectionType),
    negativeMatchTokens: _negativeMatchTokensFor(item, material, shape, text),
    highImportanceTokens: _highImportanceTokensFor(
      item,
      material,
      size,
      connectionType,
      shape,
      text,
    ),
    mediumImportanceTokens: _cleanList([
      item.category,
      item.system,
      item.itemType,
      packQuantity,
    ]),
    lowImportanceTokens: _cleanList([item.unit, item.trade]),
    ignoreTokens: const ['aisle', 'bay', 'shelf', 'dept', 'department'],
    classification: WorkSupplyItemClassification(
      inventoryCategory: item.category,
      expenseCategory: '${item.trade} materials',
      jobMaterialCategory: item.system,
      taxReportingCategory: 'materials',
      maintenanceRelevance: item.itemType,
      billableMaterial: true,
      defaultUnitCostBehavior: 'receipt-line-unit-cost',
      defaultMarkupBehavior: 'business-profile-material-markup',
    ),
    catalogVersion: _catalogIntelligenceVersion,
    parserVersion: _parserRuleVersion,
    sourceConfidence: 'auto-derived-from-catalog-fields',
    autoGenerated: true,
    needsReview: _needsManualReview(item, material, size, shape),
  );
}

List<WorkSupplyVendorMapping> _vendorMappingsFor(
  WorkSupplyItem item,
  String material,
  String size,
  String shape,
) {
  final family = _vendorFamilyCode(item, material, shape);
  final sizeCode = _vendorSafeCode(size.isEmpty ? item.variant : size);
  final itemCode = _vendorSafeCode(item.id);
  final label = _cleanList([
    item.name,
    item.trade,
    item.category,
    item.system,
    item.itemType,
    material,
    size,
    shape,
    'non-proprietary merchant-style receipt pattern',
  ]).join(' ');
  return [
    WorkSupplyVendorMapping(
      vendor: 'home depot style',
      code: 'HD-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'lowe style',
      code: 'LOWE-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'ace true value menards walmart local hardware style',
      code: 'HW-$family-$sizeCode-$itemCode',
      label: label,
    ),
    WorkSupplyVendorMapping(
      vendor: 'ferguson grainger supplyhouse tractor supply style',
      code: 'SUPPLY-$family-$sizeCode-$itemCode',
      label: label,
    ),
  ];
}

String _vendorFamilyCode(WorkSupplyItem item, String material, String shape) {
  return _vendorSafeCode(
    _cleanList([
      item.trade,
      item.system,
      item.itemType,
      material,
      shape,
    ]).join('-'),
  );
}

String _vendorSafeCode(String value) {
  final normalized = value
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (normalized.isEmpty) return 'GEN';
  return normalized.length <= 48 ? normalized : normalized.substring(0, 48);
}
