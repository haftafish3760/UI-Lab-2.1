part of '../../work_supply_receipt_parser.dart';

WorkSupplyItem? _directPlumbingFastMatch(String text) {
  return _directPlumbingAbsDwvMatch(text) ??
      _directPlumbingPvcDwvMatch(text) ??
      _directPlumbingPexServiceFittingMatch(text) ??
      _directPlumbingWaterTreatmentMatch(text) ??
      _directPlumbingRepairKitMatch(text) ??
      _directPlumbingHoseBibbRepairPartMatch(text) ??
      _directPlumbingSolderingConsumableMatch(text) ??
      _directPlumbingHandToolMatch(text);
}

WorkSupplyItem? _directPlumbingAbsDwvMatch(String text) {
  if (!RegExp(r'\b(abs|black\s+dwv|black\s+drain)\b').hasMatch(text)) {
    return null;
  }
  final targetName = switch (text) {
    final value
        when RegExp(
          r'\b(trap\s+adapter|trap\s+adpt|marvel\s+adapter)\b',
        ).hasMatch(value) =>
      'abs dwv trap adapter',
    final value
        when RegExp(
          r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t|santee)\b',
        ).hasMatch(value) =>
      'abs dwv sanitary tee',
    final value
        when RegExp(r'\b(wye|y\s+fitting|why\s+fitting)\b').hasMatch(value) =>
      'abs dwv wye',
    final value when RegExp(r'\b(cleanout|clean\s*out|co)\b').hasMatch(value) =>
      'abs dwv cleanout',
    final value when RegExp(r'\b45\b').hasMatch(value) => 'abs dwv 45 elbow',
    final value when RegExp(r'\b(90|ell|elb|elbow)\b').hasMatch(value) =>
      'abs dwv 90 elbow',
    final value
        when RegExp(r'\b(cpl|cplg|coupling|coupler)\b').hasMatch(value) =>
      'abs dwv coupling',
    _ => null,
  };
  if (targetName == null) return null;
  final size = _nominalReceiptSize(text);
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens([
    targetName,
  ])) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(targetName)) continue;
    if (_nameMatchesReceiptMatrix(name, text) ||
        _receiptMatchesVariant(text, item.variant) ||
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingHoseBibbRepairPartMatch(String text) {
  final wantedName = switch (text) {
    final value when RegExp(r'\bhose\s+bibb\s+washer\b').hasMatch(value) =>
      'hose bibb washer',
    final value when RegExp(r'\bhose\s+washer\b').hasMatch(value) =>
      'hose washer',
    final value when RegExp(r'\bsillcock\s+stem\s+packing\b').hasMatch(value) =>
      'sillcock stem packing',
    final value when RegExp(r'\bsillcock\s+handle\s+screw\b').hasMatch(value) =>
      'sillcock handle screw',
    final value when RegExp(r'\bsillcock\s+packing\s+nut\b').hasMatch(value) =>
      'sillcock packing nut',
    final value
        when RegExp(r'\bfrost\s+free\s+stem\s+washer\b').hasMatch(value) =>
      'frost free stem washer',
    final value
        when RegExp(
          r'\bfrost\s+free\s+vacuum\s+breaker\s+kit\b',
        ).hasMatch(value) =>
      'frost free vacuum breaker kit',
    final value
        when RegExp(
          r'\banti[-\s]*siphon\s+vacuum\s+breaker\s+kit\b',
        ).hasMatch(value) =>
      'anti-siphon vacuum breaker kit',
    final value when RegExp(r'\bvacuum\s+breaker\s+cap\b').hasMatch(value) =>
      'vacuum breaker cap',
    final value when RegExp(r'\bvacuum\s+breaker\s+washer\b').hasMatch(value) =>
      'vacuum breaker washer',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName, ['hose bibb repair part']);
}

WorkSupplyItem? _directPlumbingPvcDwvMatch(String text) {
  // Generic PVC fittings default to Schedule 40 unless the receipt actually
  // supplies DWV/drain evidence. Without this guard, a bare `PVC COUPLING`
  // line is captured here before the later Schedule 40 coupling precedence.
  if (!RegExp(
    r'\b(dwv|drain|sanitary|san\s+tee|wye|cleanout|trap\s+ad)\b',
  ).hasMatch(text)) {
    return null;
  }
  if (RegExp(r'\bcleanout\b').hasMatch(text) &&
      RegExp(r'\bcover\b').hasMatch(text)) {
    return null;
  }
  if (RegExp(r'\b(abs|black\s+dwv|black\s+drain)\b').hasMatch(text)) {
    return null;
  }
  final targetName = switch (text) {
    final value
        when RegExp(
          r'\b(reducing\s+san\s+tee|reducing\s+sanitary|reducing\s+sanitary\s+tee)\b',
        ).hasMatch(value) =>
      'pvc dwv reducing sanitary tee',
    final value
        when RegExp(
          r'\b(reducing\s+cplg|reducing\s+coupling|reducer\s+coupling|dwv\s+reducer)\b',
        ).hasMatch(value) =>
      'pvc dwv reducing coupling',
    final value
        when RegExp(r'\b(test\s+tee|cleanout\s+tee)\b').hasMatch(value) =>
      'pvc dwv test tee',
    final value
        when RegExp(
          r'\b(trap\s+adapter|trap\s+adpt|marvel\s+adapter)\b',
        ).hasMatch(value) =>
      'pvc dwv trap adapter',
    final value
        when RegExp(
          r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t|santee)\b',
        ).hasMatch(value) =>
      'pvc dwv sanitary tee',
    final value
        when RegExp(r'\b(wye|y\s+fitting|why\s+fitting)\b').hasMatch(value) =>
      'pvc dwv wye',
    final value when RegExp(r'\b(cleanout|clean\s*out|co)\b').hasMatch(value) =>
      'pvc dwv cleanout',
    final value when RegExp(r'\b45\b').hasMatch(value) => 'pvc dwv 45 elbow',
    final value when RegExp(r'\b(90|ell|elb|elbow)\b').hasMatch(value) =>
      'pvc dwv 90 elbow',
    final value when RegExp(r'\b(cplg|coupling|coupler)\b').hasMatch(value) =>
      'pvc dwv coupling',
    _ => null,
  };
  if (targetName == null) return null;
  final size = _nominalReceiptSize(text);
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens([
    targetName,
  ])) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(targetName)) continue;
    if (_nameMatchesReceiptMatrix(name, text) ||
        _receiptMatchesVariant(text, item.variant) ||
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingPexServiceFittingMatch(String text) {
  if (!RegExp(r'\bpex\b').hasMatch(text)) return null;
  final size = _nominalReceiptSize(text);
  final wantedItemType = switch (text) {
    final value
        when RegExp(
          r'\b(drop\s*ear|drop-ear|shower\s+elbow|stub\s*out\s+elbow)\b',
        ).hasMatch(value) =>
      'drop-ear elbows',
    final value
        when RegExp(
          r'\b(mip|male\s+adapter|m\s+adapter|m\s+adpt|crimp\s+male)\b',
        ).hasMatch(value) =>
      'male adapters',
    final value
        when RegExp(
          r'\b(fip|female\s+adapter|f\s+adapter|f\s+adpt|crimp\s+female)\b',
        ).hasMatch(value) =>
      'female adapters',
    final value
        when RegExp(
          r'\b(crimp\s+ring|crmp\s+ring|pex\s+ring)\b',
        ).hasMatch(value) =>
      'crimp rings',
    final value
        when RegExp(
          r'\b(clamp\s+ring|cinch\s+ring|cinch\s+clamp)\b',
        ).hasMatch(value) =>
      'clamp rings',
    final value when RegExp(r'\b(tee|t)\b').hasMatch(value) => 'tees',
    final value when RegExp(r'\b(cplg|coupling|coupler)\b').hasMatch(value) =>
      RegExp(r'\b(transition|trans)\b').hasMatch(value)
          ? 'transition couplings'
          : 'couplings',
    final value when RegExp(r'\b(90|ell|elb|elbow|codo)\b').hasMatch(value) =>
      '90 elbows',
    _ => null,
  };
  if (wantedItemType == null) return null;
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens([
    'pex',
    wantedItemType,
  ])) {
    final name = _normalize(item.name);
    final itemType = _normalize(item.itemType);
    final system = _normalize(item.system);
    final variant = _normalize(item.variant);
    if (item.trade == 'Plumbing' &&
        system == 'pex' &&
        itemType == wantedItemType &&
        (size == null ||
            variant == '$size in' ||
            (wantedItemType == 'tees' &&
                name.startsWith('$size x $size x $size ')))) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingWaterTreatmentMatch(String text) {
  final wantedName = switch (text) {
    final value
        when RegExp(
          r'\b(brine\s+valve|brine\s+pickup|brine\s+pick\s*up)\b',
        ).hasMatch(value) =>
      'water softener brine valve',
    final value
        when RegExp(
          r'\b(brine\s+line|flow\s+control|flow\s+restrictor)\b',
        ).hasMatch(value) =>
      'water softener brine line flow control',
    final value when RegExp(r'\b(bypass\s+valve|bypass)\b').hasMatch(value) =>
      'water softener bypass valve',
    final value when RegExp(r'\b(resin|resina)\b').hasMatch(value) =>
      'softener resin bag',
    final value
        when RegExp(r'\b(ro|reverse\s+osmosis)\b').hasMatch(value) &&
            RegExp(r'\b(membrane|membrana)\b').hasMatch(value) =>
      'reverse osmosis membrane',
    final value
        when RegExp(r'\b(uv|ultraviolet)\b').hasMatch(value) &&
            RegExp(r'\b(quartz\s+sleeve|sleeve|manga)\b').hasMatch(value) =>
      'uv quartz sleeve',
    final value
        when RegExp(r'\b(uv|ultraviolet)\b').hasMatch(value) &&
            RegExp(r'\b(lamp|bulb|lampara)\b').hasMatch(value) =>
      'uv water treatment lamp',
    final value
        when RegExp(
          r'\b(softener\s+salt|salt\s+pellets|solar\s+salt|potassium\s+chloride)\b',
        ).hasMatch(value) =>
      RegExp(r'\b(solar)\b').hasMatch(value)
          ? 'solar salt crystals'
          : RegExp(r'\b(potassium)\b').hasMatch(value)
          ? 'potassium chloride softener pellets'
          : 'water softener salt pellets',
    final value
        when RegExp(
          r'\b(sal\s+suavizador|sal\s+ablandador|sal\s+para\s+suavizador)\b',
        ).hasMatch(value) =>
      'water softener salt pellets',
    final value
        when RegExp(
          r'\b(osmosis\s+inversa|osmosis inversa|membrana\s+osmosis)\b',
        ).hasMatch(value) =>
      'reverse osmosis membrane',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName);
}

WorkSupplyItem? _directPlumbingRepairKitMatch(String text) {
  if (RegExp(
    r'\b(toilet repair kit|kit reparacion sanitario|'
    r'kit reparacion inodoro)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('toilet', ['fill valve']);
  }
  if (RegExp(
    r'\b(sink repair kit|lavatory repair kit|basin repair kit|'
    r'kit reparacion lavabo|kit reparacion fregadero)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('sink repair kit');
  }
  if (RegExp(
    r'\b(faucet repair kit|o-ring and seat kit|o ring and seat kit|'
    r'kit reparacion llave|kit reparacion grifo)\b',
  ).hasMatch(text)) {
    return _firstPlumbingItemNamed('faucet o-ring and seat kit');
  }
  return null;
}

WorkSupplyItem? _directPlumbingSolderingConsumableMatch(String text) {
  final wantedName = switch (text) {
    final value
        when RegExp(
          r'\b(lead\s*free\s+solder|lf\s+solder|plumbing\s+solder|sweat\s+solder|silver\s+bearing\s+solder|tin\s+antimony)\b',
        ).hasMatch(value) =>
      'lead-free plumbing solder',
    final value
        when RegExp(
          r'\b(solder\s+flux|plumbing\s+flux|tinning\s+flux|paste\s+flux|water\s+soluble\s+flux)\b',
        ).hasMatch(value) =>
      'water soluble flux',
    final value
        when RegExp(
          r'\b(acid\s+brush|flux\s+brush|solder\s+brush)\b',
        ).hasMatch(value) =>
      'acid brush',
    final value
        when RegExp(
          r'\b(fitting\s+brush|fit\s+brush|copper\s+brush|tube\s+brush|wire\s+fitting\s+brush)\b',
        ).hasMatch(value) =>
      'copper fitting brush',
    final value
        when RegExp(
          r'\b(sand\s+cloth|emery\s+cloth|abrasive\s+cloth)\b',
        ).hasMatch(value) =>
      'plumber sand cloth',
    final value
        when RegExp(
          r'\b(heat\s+shield|flame\s+protector|torch\s+shield|flame\s+shield)\b',
        ).hasMatch(value) =>
      'soldering heat shield',
    final value
        when RegExp(
          r'\b(ma[pb]{1,2}[-\s]*pro|ma[pb]{1,2}\s+gas|map\s+gas)\b',
        ).hasMatch(value) =>
      'map-pro torch fuel',
    final value
        when RegExp(
              r'\b(propane|lp\s+fuel|propane\s+cylinder)\b',
            ).hasMatch(value) &&
            RegExp(r'\b(torch|fuel|cyl|cylinder|bottle)\b').hasMatch(value) =>
      'propane torch fuel',
    final value
        when RegExp(
          r'\b(torch\s+head|solder\s+torch|plumbing\s+torch|trigger\s+start\s+torch|self\s+lighting\s+torch)\b',
        ).hasMatch(value) =>
      'soldering torch head',
    _ => null,
  };
  if (wantedName == null) return null;
  return _firstPlumbingItemNamed(wantedName);
}

WorkSupplyItem? _firstPlumbingItemNamed(
  String requiredName, [
  List<String> additionalNameTokens = const [],
]) {
  for (final item in _activeReceiptCatalogItemsForRequiredNameTokens([
    requiredName,
    ...additionalNameTokens,
  ])) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Plumbing' || !name.contains(requiredName)) continue;
    if (additionalNameTokens.every(name.contains)) return item;
  }
  return null;
}
