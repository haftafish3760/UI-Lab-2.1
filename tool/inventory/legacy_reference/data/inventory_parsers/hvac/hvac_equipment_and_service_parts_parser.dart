part of '../../work_supply_receipt_parser.dart';

/// Matches HVAC equipment, furnace, control, and service-part receipt lines.
WorkSupplyItem? _directHvacEquipmentAndServicePartsMatch(String text) {
  WorkSupplyItem? findPreferredHvac(
    Iterable<String> requiredNameParts,
    bool Function(String name) matches,
  ) {
    WorkSupplyItem? fallback;
    for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
      requiredNameParts,
    )) {
      final name = item.name.toLowerCase();
      if (item.trade != 'HVAC' || !matches(name)) continue;
      if (item.packTier == WorkSupplyPackTier.core) return item;
      fallback ??= item;
    }
    return fallback;
  }

  final wantsFlameSensor = RegExp(
    r'\b(flame\s*(sensor|rod)|sensor flama|varilla flama)\b',
  ).hasMatch(text);
  if (wantsFlameSensor) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('flame sensor')) return item;
    }
  }

  final wantsIgnitor = RegExp(
    r'\b(hsi|hot\s*surf|hot\s*surface|ignitor|igniter|ignitor superficie)\b',
  ).hasMatch(text);
  if (wantsIgnitor) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          (name.contains('hot surface ignitor') ||
              name.contains('surface ignitor') ||
              name.contains('igniter'))) {
        return item;
      }
    }
  }

  final wantsPressureSwitch =
      RegExp(r'\b(press|pressure|presion|draft)\b').hasMatch(text) &&
      RegExp(r'\b(switch|interruptor)\b').hasMatch(text);
  if (wantsPressureSwitch) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('pressure switch')) {
        return item;
      }
    }
  }

  final wantsLimitSwitch =
      RegExp(r'\b(limit|limite|rollout)\b').hasMatch(text) &&
      RegExp(r'\b(sw|switch|interruptor|fan|vent|ventilador)\b').hasMatch(text);
  if (wantsLimitSwitch) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('limit switch')) {
        return item;
      }
    }
  }

  final wantsCondenserFanMotor =
      RegExp(r'\b(motor)\b').hasMatch(text) &&
      RegExp(
        r'\b(cond|condenser|condensador|outdoor|exterior|vent exterior)\b',
      ).hasMatch(text);
  if (wantsCondenserFanMotor) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('condenser fan motor')) {
        return item;
      }
    }
  }

  final wantsBlowerMotor =
      RegExp(r'\b(motor)\b').hasMatch(text) &&
      RegExp(r'\b(blower|soplador)\b').hasMatch(text);
  if (wantsBlowerMotor) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('blower motor')) {
        return item;
      }
    }
  }

  final wantsHvacFloatSwitch =
      RegExp(r'\b(float|flotador|overflow|wet)\b').hasMatch(text) &&
      RegExp(r'\b(sw|switch|pan|bandeja|inlinea|inline)\b').hasMatch(text);
  if (wantsHvacFloatSwitch) {
    final wantsWetSwitch = RegExp(r'\bwet\s+switch\b').hasMatch(text);
    final wantsSecondaryPan =
        RegExp(r'\b(secondary|sec|pan|bandeja)\b').hasMatch(text) &&
        RegExp(r'\bfloat\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'HVAC') continue;
      if (wantsWetSwitch && name.contains('wet switch')) return item;
      if (wantsSecondaryPan &&
          name.contains('secondary pan') &&
          name.contains('float switch')) {
        return item;
      }
      if (!wantsWetSwitch && name.contains('float switch')) {
        return item;
      }
    }
  }

  final wantsHvacDrainPan =
      RegExp(r'\b(pan|bandeja)\b').hasMatch(text) &&
      RegExp(r'\b(drain|drenaje|secondary|sec|ac)\b').hasMatch(text);
  if (wantsHvacDrainPan) {
    final match = findPreferredHvac(const [
      'drain',
      'pan',
    ], (name) => name.contains('drain pan'));
    if (match != null) return match;
  }

  final wantsCondensateTrap =
      RegExp(r'\b(cond|condensate|condensado|ez)\b').hasMatch(text) &&
      RegExp(r'\b(trap|trampa)\b').hasMatch(text);
  if (wantsCondensateTrap) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('condensate trap')) {
        return item;
      }
    }
  }

  final wantsFilterDrier =
      RegExp(r'\b(filter|filtro|drier|dri|secador)\b').hasMatch(text) &&
      RegExp(r'\b(drier|dri|secador|liquid|liq|linea)\b').hasMatch(text);
  if (wantsFilterDrier) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('filter drier')) {
        return item;
      }
    }
  }

  final wantsThermostatWire =
      RegExp(r'\b(stat|tstat|thermostat|termostato)\b').hasMatch(text) &&
      RegExp(r'\b(wire|cable)\b').hasMatch(text);
  if (wantsThermostatWire) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('thermostat wire')) {
        return item;
      }
    }
  }

  final wantsServiceValveCap =
      RegExp(r'\b(service|serv|servicio|valve|valvula)\b').hasMatch(text) &&
      RegExp(r'\b(cap|tapa)\b').hasMatch(text);
  if (wantsServiceValveCap) {
    final match = findPreferredHvac(const [
      'service',
      'valve',
      'cap',
    ], (name) => name.contains('service valve cap'));
    if (match != null) return match;
  }

  final wantsDefrostBoard =
      RegExp(r'\b(defrost|dfrost|descongelar)\b').hasMatch(text) &&
      RegExp(r'\b(board|ctrl|control|tarjeta)\b').hasMatch(text);
  if (wantsDefrostBoard) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('defrost')) {
        return item;
      }
    }
  }

  final wantsLineSetInsulation =
      RegExp(r'\b(line|linea|armaflex)\b').hasMatch(text) &&
      RegExp(r'\b(insul|insulation|aislamiento|armaflex)\b').hasMatch(text);
  if (wantsLineSetInsulation) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('line set') &&
          name.contains('insulation') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsCondensateCoupling =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler|coup|acople)\b').hasMatch(text) &&
      RegExp(r'\b(cond|condensate|drain)\b').hasMatch(text);
  if (wantsCondensateCoupling) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('condensate pvc coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  return null;
}
