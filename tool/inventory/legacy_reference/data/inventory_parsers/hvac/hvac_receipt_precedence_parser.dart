part of '../../work_supply_receipt_parser.dart';

/// Resolves unambiguous HVAC receipt wording before broad cross-trade rules.
///
/// The normal candidate scorer remains the fallback. These rules only protect
/// exact HVAC service stock whose receipt wording carries higher information
/// than a generic electrical, plumbing, or broad catalog alias.
WorkSupplyItem? _directHvacReceiptPrecedenceMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'hvac') {
    return null;
  }

  WorkSupplyItem? findHvac(
    bool Function(String name) matches, {
    Iterable<String> requiredNameParts = const [],
  }) {
    WorkSupplyItem? fallback;
    final candidates = requiredNameParts.isEmpty
        ? _activeWorkSupplyCatalogItems
        : _activeReceiptCatalogItemsForRequiredNameTokens(requiredNameParts);
    for (final item in candidates) {
      final name = item.name.toLowerCase();
      if (item.trade != 'HVAC' || !matches(name)) continue;
      if (item.packTier == WorkSupplyPackTier.core) return item;
      fallback ??= item;
    }
    return fallback;
  }

  final wantsWifiThermostat =
      RegExp(r'\bwi[ -]?fi\b').hasMatch(text) &&
      RegExp(r'\b(thermostat|tstat)\b').hasMatch(text);
  if (wantsWifiThermostat) {
    final match = findHvac(
      (name) => name.contains('wifi thermostat'),
      requiredNameParts: const ['wifi', 'thermostat'],
    );
    if (match != null) return match;
  }

  final wantsHeatPumpDefrostBoard =
      RegExp(r'\bheat\s+pump\b').hasMatch(text) &&
      RegExp(r'\bdefrost\b').hasMatch(text) &&
      RegExp(r'\b(board|control)\b').hasMatch(text);
  if (wantsHeatPumpDefrostBoard) {
    final match = findHvac(
      (name) => name.contains('heat pump defrost board'),
      requiredNameParts: const ['heat', 'pump', 'defrost', 'board'],
    );
    if (match != null) return match;
  }

  final wantsTimeDelayRelay =
      RegExp(r'\btime\s+delay\b').hasMatch(text) &&
      RegExp(r'\brelay\b').hasMatch(text);
  if (wantsTimeDelayRelay) {
    final voltage = RegExp(
      r'\b(24|120|208|230)\s*v\b',
    ).firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('time delay relay') &&
          (voltage == null || name.contains('${voltage}v')),
    );
    if (match != null) return match;
  }

  final wantsHardStart =
      RegExp(r'\b(hard\s+start|spp\d+)\b').hasMatch(text) &&
      RegExp(r'\b(kit|kt|start)\b').hasMatch(text);
  if (wantsHardStart) {
    final match = findHvac((name) => name.contains('hard start kit'));
    if (match != null) return match;
  }

  final wantsServiceValveCap =
      RegExp(r'\b(service|serv)\b').hasMatch(text) &&
      RegExp(r'\bvalve\b').hasMatch(text) &&
      RegExp(r'\bcap\b').hasMatch(text);
  if (wantsServiceValveCap) {
    final match = findHvac((name) => name.contains('service valve cap'));
    if (match != null) return match;
  }

  final wantsDrainPan =
      RegExp(r'\b(condensate|drain|secondary|sec)\b').hasMatch(text) &&
      RegExp(r'\bpan\b').hasMatch(text);
  if (wantsDrainPan) {
    final size = _receiptSizeMatrix(text);
    final match = findHvac(
      (name) =>
          name.contains('secondary drain pan') &&
          (size == null || name.contains(size)),
    );
    if (match != null) return match;
  }

  final capacitor = RegExp(r'\b(\d+(?:\.\d+)?/\d+)\b').firstMatch(text);
  if (capacitor != null &&
      RegExp(r'\b(dual\s*run|run\s*cap|capacitor|cap)\b').hasMatch(text)) {
    final wantsRatedDualRunCapacitor =
        RegExp(r'\b(370|440)\s*v\b').hasMatch(text) &&
        RegExp(r'\bdual\s*run\b').hasMatch(text);
    final match = findHvac(
      (name) => wantsRatedDualRunCapacitor
          ? name.contains('${capacitor.group(1)} mfd') &&
                name.contains('dual run capacitor')
          : name == '${capacitor.group(1)} mfd run capacitor',
      requiredNameParts: const ['dual', 'run', 'capacitor'],
    );
    if (match != null) return match;
  }

  final wantsContactor = RegExp(r'\bcontactor\b').hasMatch(text);
  if (wantsContactor) {
    final amps = RegExp(
      r'\b(20|30|40|50|60)\s*(?:a|amp)\b',
    ).firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('contactor') &&
          (amps == null || name.contains('$amps amp')),
    );
    if (match != null) return match;
  }

  // A C-wire adapter is a thermostat accessory, not a thermostat wire roll.
  // Resolve it before the broad thermostat-wire rule below so abbreviated
  // supply-house lines such as "C WIRE ADAPTER TSTAT" retain their identity.
  final wantsCommonWireAdapter =
      RegExp(r'\b(c\s*wire|common\s+wire|wire\s+saver)\b').hasMatch(text) &&
      RegExp(r'\b(adapter|adpt|tstat|thermostat)\b').hasMatch(text);
  if (wantsCommonWireAdapter) {
    final match = findHvac(
      (name) =>
          name.contains('common wire adapter') || name.contains('wire saver'),
    );
    if (match != null) return match;
  }

  final thermostatWire =
      RegExp(r'\b(stat|tstat|thermostat|termostato)\b').hasMatch(text) &&
      RegExp(r'\b(wire|cable)\b').hasMatch(text);
  if (thermostatWire) {
    final gauge = RegExp(r'\b(18)[-/](2|5|8)\b').firstMatch(text);
    final match = findHvac(
      (name) =>
          name.contains('thermostat wire') &&
          (gauge == null ||
              name.contains('${gauge.group(1)}/${gauge.group(2)}')),
    );
    if (match != null) return match;
  }

  final wantsDualPortPressureSwitch =
      RegExp(r'\bdual\s*port\b').hasMatch(text) &&
      RegExp(r'\bpressure\s*switch\b').hasMatch(text);
  if (wantsDualPortPressureSwitch) {
    final match = findHvac(
      (name) => name.contains('dual port') && name.contains('pressure switch'),
    );
    if (match != null) return match;
  }

  final matrix = _receiptSizeMatrix(text);
  final wantsMediaCabinetFilter =
      RegExp(r'\bmedia\s*cabinet\b').hasMatch(text) &&
      RegExp(r'\bfilter\b').hasMatch(text);
  if (wantsMediaCabinetFilter) {
    final merv = RegExp(r'\bmerv\s*(8|11|13|16)\b').firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('media cabinet') &&
          (merv == null || name.contains('merv $merv')) &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsPleatedFilter =
      RegExp(r'\b(furnace|return|air|ac|pleated)\b').hasMatch(text) &&
      RegExp(r'\bfilter\b').hasMatch(text) &&
      !wantsMediaCabinetFilter &&
      !RegExp(
        r'\b(filter\s*rack|return\s*(?:filter\s*)?grille)\b',
      ).hasMatch(text);
  if (wantsPleatedFilter) {
    final merv = RegExp(r'\bmerv\s*(8|11|13|16)\b').firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          (name.contains('pleated air filter') ||
              name.contains('pleated filter')) &&
          (merv == null || name.contains('merv $merv')) &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsAcDisconnect =
      RegExp(r'\b(ac|a/c)\b').hasMatch(text) &&
      RegExp(r'\b(disconnect|disc)\b').hasMatch(text);
  if (wantsAcDisconnect) {
    final amps = RegExp(r'\b(30|60)\s*(?:a|amp)\b').firstMatch(text)?.group(1);
    final match = findHvac(
      (name) =>
          name.contains('ac disconnect') &&
          (amps == null || name.contains('$amps amp')),
    );
    if (match != null) return match;
  }

  final wantsFilterRackOrGrille = RegExp(
    r'\b(filter\s*rack|return\s*(?:filter\s*)?grille)\b',
  ).hasMatch(text);
  if (wantsFilterRackOrGrille) {
    final match = findHvac(
      (name) =>
          name.contains('filter rack or return grille') &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsFloatSwitch =
      RegExp(r'\bfloat\s*switch\b').hasMatch(text) ||
      RegExp(r'\bwet\s*switch\b').hasMatch(text);
  if (wantsFloatSwitch) {
    final wantsWetSwitch = RegExp(r'\bwet\s*switch\b').hasMatch(text);
    final wantsSecondaryPan = RegExp(r'\b(secondary|sec|pan)\b').hasMatch(text);
    final match = findHvac(
      (name) =>
          name.contains('float switch') &&
          (!wantsWetSwitch || name.contains('wet switch')) &&
          (!wantsSecondaryPan || name.contains('secondary pan')),
    );
    if (match != null) return match;
  }

  final wantsSecondaryDrainPan =
      RegExp(r'\b(secondary|sec)\b').hasMatch(text) &&
      RegExp(r'\bdrain\s*pan\b').hasMatch(text);
  if (wantsSecondaryDrainPan) {
    final match = findHvac(
      (name) =>
          name.contains('condensate service material') &&
          name.contains('secondary drain pan') &&
          (matrix == null || name.contains(matrix)),
    );
    if (match != null) return match;
  }

  final wantsLiquidLineDrier =
      RegExp(r'\bliquid\s*line\b').hasMatch(text) &&
      RegExp(r'\bfilter\s*dri(?:er|er)\b').hasMatch(text);
  if (wantsLiquidLineDrier) {
    final size = _nominalReceiptSize(text);
    final match = findHvac(
      (name) =>
          name.contains('liquid line filter drier') &&
          (size == null || name.contains('$size in')),
    );
    if (match != null) return match;
  }

  final wantsCondensateTablets =
      RegExp(r'\b(condensate|cond|drain\s*pan|drain)\b').hasMatch(text) &&
      RegExp(r'\b(tablets?|tabs?)\b').hasMatch(text);
  if (wantsCondensateTablets) {
    final match = findHvac(
      (name) =>
          name.contains('condensate drain tablets') ||
          name.contains('drain pan tablet'),
    );
    if (match != null) return match;
  }

  final wantsLowVoltageFuse =
      RegExp(r'\b(low\s+volt(?:age)?|lv)\b').hasMatch(text) &&
      RegExp(r'\bfuse\b').hasMatch(text);
  if (wantsLowVoltageFuse) {
    final amps = RegExp(r'\b(3|5)\s*(?:a|amp)\b').firstMatch(text)?.group(1);
    final wantsHolder = RegExp(r'\bholder\b').hasMatch(text);
    final match = findHvac(
      (name) =>
          name.contains('low voltage fuse') &&
          (wantsHolder == name.contains('holder')) &&
          (amps == null || name.contains('$amps amp')),
    );
    if (match != null) return match;
  }

  return null;
}
