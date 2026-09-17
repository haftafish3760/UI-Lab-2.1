part of 'work_supply_receipt_parser.dart';

/// Matches electrical service, protection, raceway, and safety receipt lines.
///
/// This stays separate from the electrical consumable matcher so the rules that
/// choose a breaker, conduit body, disconnect, or safety device remain easy to
/// find and audit.
WorkSupplyItem? _directElectricalProfessionalMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'electrical') {
    return null;
  }

  bool nameHas(WorkSupplyItem item, String phrase) =>
      item.trade == 'Electrical' && item.name.toLowerCase().contains(phrase);

  final wantsDualFunctionBreaker =
      RegExp(r'\bdual\s*function\b').hasMatch(text) &&
      RegExp(r'\b(brkr|breaker|circuit)\b').hasMatch(text);
  if (wantsDualFunctionBreaker) {
    final amperage = RegExp(
      r'\b(15|20|30|40)\s*(?:a|amp)\b',
    ).firstMatch(text)?.group(1);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('dual function') &&
          name.contains('breaker') &&
          (amperage == null || name.contains('$amperage amp'))) {
        return item;
      }
    }
  }

  final wantsAfciBreaker =
      RegExp(r'\b(afci|arc\s*fault)\b').hasMatch(text) &&
      RegExp(r'\b(brkr|breaker|circuit)\b').hasMatch(text);
  if (wantsAfciBreaker) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (nameHas(item, 'afci') && nameHas(item, 'breaker')) return item;
    }
  }

  final wantsDoublePoleBreaker =
      RegExp(r'\b(2p|2\s*pole|double\s*pole|dbl\s*pole)\b').hasMatch(text) &&
      RegExp(r'\b(brkr|breaker|circuit)\b').hasMatch(text);
  if (wantsDoublePoleBreaker) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (nameHas(item, 'double-pole') && nameHas(item, 'breaker')) {
        return item;
      }
    }
  }

  final wantsSmokeCarbonMonoxideAlarm =
      RegExp(r'\b(smoke|smk)\b').hasMatch(text) &&
      RegExp(r'\b(co|carbon\s*monoxide)\b').hasMatch(text) &&
      RegExp(r'\b(alarm|detector)\b').hasMatch(text);
  if (wantsSmokeCarbonMonoxideAlarm) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (nameHas(item, 'combination smoke and carbon monoxide alarm')) {
        return item;
      }
    }
  }

  final wantsDimmer = RegExp(r'\b(dimmer|atenuador)\b').hasMatch(text);
  if (wantsDimmer) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (nameHas(item, 'dimmer')) return item;
    }
  }

  final wantsWeatherproofBox =
      RegExp(r'\b(wp|weatherproof|outdoor|exterior)\b').hasMatch(text) &&
      RegExp(r'\b(box|caja)\b').hasMatch(text);
  if (wantsWeatherproofBox) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('weatherproof') &&
          name.contains('box')) {
        return item;
      }
    }
  }

  final wantsInUseCover =
      RegExp(
        r'\b(in\s*use|while\s*in\s*use|bubble|burbuja|exterior|wp)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(cover|tapa|cubierta)\b').hasMatch(text);
  if (wantsInUseCover) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          (name.contains('in-use cover') ||
              name.contains('in use cover') ||
              name.contains('weatherproof cover'))) {
        return item;
      }
    }
  }

  final wantsAcDisconnect =
      RegExp(
        r'\b(ac|a/c|non\s*fused|non\s*fusible|disc|disconnect|'
        r'desconectador)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(disc|disconnect|desconectador)\b').hasMatch(text) &&
      !RegExp(r'\b(wire\s*nut|wirenut)\b').hasMatch(text);
  final explicitlyAirConditioning = RegExp(r'\b(ac|a/c)\b').hasMatch(text);
  final explicitlyElectrical = tradeScope?.trim().toLowerCase() == 'electrical';
  // An unscoped AC disconnect is HVAC service equipment. Let the HVAC
  // precedence matcher resolve it; preserve this rule for an Electrical flow
  // and for generic disconnect wording without AC evidence.
  if (wantsAcDisconnect &&
      (explicitlyElectrical || !explicitlyAirConditioning)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('disconnect') &&
          !name.contains('breaker')) {
        return item;
      }
    }
  }

  final wantsFanBraceBox =
      RegExp(r'\b(fan|ventilador)\b').hasMatch(text) &&
      RegExp(r'\b(brace|rated|box|caja)\b').hasMatch(text);
  if (wantsFanBraceBox) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('fan') &&
          (name.contains('brace') || name.contains('rated')) &&
          name.contains('box')) {
        return item;
      }
    }
  }

  final wantsPanelFiller =
      RegExp(r'\b(panel|brkr|breaker|load\s*center)\b').hasMatch(text) &&
      RegExp(r'\b(filler|blank|relleno|tapa)\b').hasMatch(text);
  if (wantsPanelFiller) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          (name.contains('panel filler') ||
              name.contains('breaker filler') ||
              name.contains('filler plate'))) {
        return item;
      }
    }
  }

  final wantsLbConduitBody =
      RegExp(r'\b(lb)\b').hasMatch(text) &&
      RegExp(r'\b(body|conduit|cond|cuerpo)\b').hasMatch(text);
  if (wantsLbConduitBody) {
    final size = _nominalReceiptSize(text);
    final wantsPvc = RegExp(r'\b(pvc|schedule\s*40|sch\s*40)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('conduit body assembly') &&
          name.contains('lb') &&
          (!wantsPvc || name.contains('pvc')) &&
          // Generated conduit-body variants lead with their material (for
          // example, "PVC 3/4 in LB"), unlike the legacy catalog entries.
          // Match the nominal size wherever that generated variant places it.
          (size == null || name.contains('$size in '))) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('lb') &&
          name.contains('conduit body')) {
        return item;
      }
    }
  }

  final wantsLiquidtightConnector =
      RegExp(r'\b(liquid\s*tight|liquidtight|sealtite)\b').hasMatch(text) &&
      RegExp(r'\b(conn|connector)\b').hasMatch(text);
  if (wantsLiquidtightConnector) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('liquidtight connector') &&
          (size == null || _nameMatchesReceiptSize(name, size))) {
        return item;
      }
    }
  }

  final wantsToggleSwitch =
      RegExp(
        r'\b(toggle|tog|palanca|wall|3way|3\s*way|3\s*via|tres\s+vias?)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(sw|switch|interruptor)\b').hasMatch(text);
  if (wantsToggleSwitch) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          (name.contains('toggle') || name.contains('wall switch')) &&
          name.contains('switch')) {
        return item;
      }
    }
  }

  final wantsGroundClamp =
      RegExp(r'\b(ground|grounding|tierra)\b').hasMatch(text) &&
      RegExp(r'\b(clamp|abrazadera)\b').hasMatch(text);
  if (wantsGroundClamp) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Electrical' &&
          name.contains('ground') &&
          name.contains('clamp')) {
        return item;
      }
    }
  }

  final wantsGroundRod =
      RegExp(r'\b(grd|ground|grounding|tierra)\b').hasMatch(text) &&
      RegExp(r'\b(rod|varilla)\b').hasMatch(text);
  if (wantsGroundRod) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (nameHas(item, 'ground rod') && !nameHas(item, 'clamp')) {
        return item;
      }
    }
  }

  return null;
}
