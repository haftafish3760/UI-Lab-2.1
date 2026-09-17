part of '../../work_supply_receipt_parser.dart';

/// Matches HVAC air-quality, condensate, duct, and installation receipt lines.
WorkSupplyItem? _directHvacAirDrainAndDuctMatch(String text) {
  final wantsFoilTape =
      RegExp(r'\b(foil|hvac|ul181|ul 181)\b').hasMatch(text) &&
      RegExp(r'\btape\b').hasMatch(text);
  if (wantsFoilTape) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('foil tape') &&
          !name.contains('foam') &&
          !name.contains('cork') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  if (_hasHvacAirFilterReceiptEvidence(text)) {
    final size = _nominalReceiptSize(text);
    final wantsBulk = RegExp(r'\b(case|12\s*pack|12pk|box)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          (name.contains('air filter') ||
              name.contains('pleated filter') ||
              name.contains('furnace filter') ||
              name.contains('ac filter')) &&
          (wantsBulk || !RegExp(r'\b(case|12 pack)\b').hasMatch(name)) &&
          !name.contains('return air grille') &&
          !name.contains('filter grille') &&
          !name.contains('filter drier') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _nameMatchesReceiptSize(name, size))) {
        return item;
      }
    }
  }

  final wantsHvacFoilTape =
      RegExp(r'\b(foil|cinta|ul181|ul 181)\b').hasMatch(text) &&
      RegExp(r'\b(tape|cinta|hvac)\b').hasMatch(text);
  if (wantsHvacFoilTape) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('foil tape') &&
          !name.contains('foam') &&
          !name.contains('cork')) {
        return item;
      }
    }
  }

  final wantsCommonWireAdapter =
      RegExp(r'\b(c\s*wire|common\s+wire|wire\s+saver)\b').hasMatch(text) &&
      RegExp(r'\b(adapter|adpt|tstat|thermostat)\b').hasMatch(text);
  if (wantsCommonWireAdapter) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          (name.contains('common wire adapter') ||
              name.contains('wire saver'))) {
        return item;
      }
    }
  }

  final wantsCoilCleaner =
      RegExp(r'\b(coil|evap|evaporator|condenser)\b').hasMatch(text) &&
      RegExp(r'\b(cleaner|clean|no\s*rinse)\b').hasMatch(text);
  if (wantsCoilCleaner) {
    WorkSupplyItem? fallback;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'HVAC' || !name.contains('coil cleaner')) continue;
      if (item.packTier == WorkSupplyPackTier.core) return item;
      fallback ??= item;
    }
    return fallback;
  }

  final wantsEquipmentPad =
      RegExp(r'\b(equip|equipment|condenser)\b').hasMatch(text) &&
      RegExp(r'\b(pad)\b').hasMatch(text);
  if (wantsEquipmentPad) {
    final matrix = _receiptSizeMatrix(text);
    WorkSupplyItem? fallback;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          (name.contains('equipment pad') || name.contains('condenser pad'))) {
        if (matrix != null &&
            item.packTier == WorkSupplyPackTier.core &&
            name.contains(matrix)) {
          return item;
        }
        if (item.packTier == WorkSupplyPackTier.core && matrix == null) {
          return item;
        }
        fallback ??= item;
      }
    }
    return fallback;
  }

  final wantsThermostat =
      RegExp(r'\b(tstat|thermostat|thermo stat|termostato)\b').hasMatch(text) &&
      !RegExp(r'\b(wire|cable)\b').hasMatch(text);
  if (wantsThermostat) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('thermostat')) {
        return item;
      }
    }
  }

  final wantsEquipmentWhip =
      RegExp(r'\b(ac|a/c|equipment|equip|hvac)\b').hasMatch(text) &&
      RegExp(r'\b(whip|liquid\s*tight|liquidtight|sealtite)\b').hasMatch(text);
  if (wantsEquipmentWhip) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('equipment whip') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsSheetMetalScrew = RegExp(
    r'\b(sheet metal screw|sheet mtl scr|zip screw|tek screw|'
    r'self drilling screw|self tapping screw|sms|tornillo lamina|'
    r'tornillo metal)\b',
  ).hasMatch(text);
  if (wantsSheetMetalScrew) {
    final preferredSize = RegExp(r'\b1/2\b').hasMatch(text)
        ? '1/2 in'
        : RegExp(r'\b3/4\b').hasMatch(text)
        ? '3/4 in'
        : RegExp(r'\b1\b').hasMatch(text)
        ? '1 in'
        : null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('sheet metal screw') &&
          (preferredSize == null || name.contains(preferredSize))) {
        return item;
      }
    }
  }

  final wantsDrainTabs = RegExp(
    r'\b(pan tabs|drain tabs|cond drain tabs|condensate tablets|'
    r'pastillas bandeja|tabletas drenaje)\b',
  ).hasMatch(text);
  if (wantsDrainTabs) {
    WorkSupplyItem? fallback;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          (name.contains('condensate drain tablets') ||
              name.contains('drain pan tablet') ||
              name.contains('drain tablet'))) {
        if (item.packTier == WorkSupplyPackTier.core) return item;
        fallback ??= item;
      }
    }
    if (fallback != null) return fallback;
  }

  final wantsCondensateDrainGun =
      RegExp(r'\b(drain|condensate)\b').hasMatch(text) &&
      RegExp(r'\b(gun|cartridge|cartucho)\b').hasMatch(text);
  if (wantsCondensateDrainGun) {
    final wantsCartridge = RegExp(r'\b(cartridge|cartucho)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'HVAC') continue;
      if (wantsCartridge && name.contains('drain gun cartridge')) return item;
      if (!wantsCartridge && name.contains('condensate drain gun')) {
        return item;
      }
    }
  }

  final wantsWaterPanel = RegExp(r'\bwater\s+panel\b').hasMatch(text);
  if (wantsWaterPanel) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('humidifier water panel')) {
        return item;
      }
    }
  }

  final wantsHumidifierPart =
      RegExp(r'\bhumidifier\b').hasMatch(text) || wantsWaterPanel;
  if (wantsHumidifierPart) {
    final wantedName = switch (text) {
      final value when RegExp(r'\b(pad|water\s+panel)\b').hasMatch(value) =>
        RegExp(r'\bwater\s+panel\b').hasMatch(value)
            ? 'humidifier water panel'
            : 'humidifier pad',
      final value when RegExp(r'\bsolenoid\b').hasMatch(value) =>
        'humidifier solenoid valve',
      final value when RegExp(r'\bfeed\s+tube\b').hasMatch(value) =>
        'humidifier feed tube',
      final value when RegExp(r'\bdrain\s+tube\b').hasMatch(value) =>
        'humidifier drain tube',
      final value when RegExp(r'\bsaddle\s+valve\b').hasMatch(value) =>
        'humidifier saddle valve',
      final value when RegExp(r'\bbypass\s+damper\b').hasMatch(value) =>
        'humidifier bypass damper',
      _ => null,
    };
    if (wantedName != null) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'HVAC' && name.contains(wantedName)) return item;
      }
    }
  }

  final wantsAirCleanerPart =
      RegExp(r'\b(air\s+scrubber|air\s+cleaner)\b').hasMatch(text) ||
      RegExp(r'\bionizing\s+wire\b').hasMatch(text);
  if (wantsAirCleanerPart) {
    final wantedName = switch (text) {
      final value when RegExp(r'\bballast\b').hasMatch(value) =>
        'air scrubber ballast',
      final value
          when RegExp(r'\b(cell)\b').hasMatch(value) &&
              RegExp(r'\bair\s+scrubber\b').hasMatch(value) =>
        'air scrubber cell',
      final value when RegExp(r'\bprefilter\b').hasMatch(value) =>
        'electronic air cleaner prefilter',
      final value when RegExp(r'\bionizing\s+wire\b').hasMatch(value) =>
        'electronic air cleaner ionizing wire',
      _ => null,
    };
    if (wantedName != null) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'HVAC' && name.contains(wantedName)) return item;
      }
    }
  }

  final wantsMiniSplitCleaningBib =
      RegExp(r'\b(mini\s*split|ductless)\b').hasMatch(text) &&
      RegExp(
        r'\b(cleaning|limpieza|wash|lavado|bolsa|bib|bag)\b',
      ).hasMatch(text);
  if (wantsMiniSplitCleaningBib) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('cleaning bib')) {
        return item;
      }
    }
  }

  final wantsCondensatePump = RegExp(
    r'\b(condensate pump|cond pump|cond pmp|bomba condensado|bomba cond)\b|'
    r'\b(cond|condensate|condensado)\b.*\b(pump|pmp|bomba)\b|'
    r'\b(bomba|pump|pmp)\b.*\b(cond|condensate|condensado)\b',
  ).hasMatch(text);
  if (wantsCondensatePump) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' && name.contains('condensate pump')) {
        return item;
      }
    }
  }

  final wantsFlexDuct = RegExp(
    r'\b(flex duct|ins flex|insulated flex|ducto flex|flex aislado)\b',
  ).hasMatch(text);
  if (wantsFlexDuct) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('flex duct') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsDuctTakeoff = RegExp(
    r'\b(start collar|duct takeoff|takeoff|spin in|spin-in|'
    r'collarin arranque|toma ducto)\b',
  ).hasMatch(text);
  if (wantsDuctTakeoff) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'HVAC' &&
          name.contains('duct takeoff') &&
          !name.contains('register boot') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  return null;
}
