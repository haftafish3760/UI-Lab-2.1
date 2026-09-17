part of '../../work_supply_receipt_parser.dart';

/// Resolves unambiguous plumbing receipt shorthand before broad fast rules.
WorkSupplyItem? _directPlumbingReceiptPrecedenceMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'plumbing') {
    return null;
  }

  WorkSupplyItem? findPlumbing(
    Iterable<String> requiredNameParts,
    bool Function(String name) matches,
  ) {
    for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
      requiredNameParts,
    )) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && matches(name)) return item;
    }
    return null;
  }

  WorkSupplyItem? findPlumbingItem(
    Iterable<String> requiredNameParts,
    bool Function(WorkSupplyItem item) matches,
  ) {
    for (final item in _activeReceiptCatalogItemsForRequiredNameTokens(
      requiredNameParts,
    )) {
      if (item.trade == 'Plumbing' && matches(item)) return item;
    }
    return null;
  }

  if (RegExp(r'\bstem\s+packing\b').hasMatch(text)) {
    final match = findPlumbing(const [
      'stem',
      'packing',
    ], (name) => name.contains('stem packing'));
    if (match != null) return match;
  }

  if (RegExp(r'\bbackwater\s+valve\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      const ['backwater', 'valve'],
      (name) =>
          name.contains('backwater valve') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsPvcCement =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|glue|solvent\s+cement)\b').hasMatch(text) &&
      !RegExp(r'\b(cpvc|primer|paint)\b').hasMatch(text);
  if (wantsPvcCement) {
    final amount = _receiptPackageAmount(text, 'oz');
    final match = findPlumbingItem(
      const ['cement'],
      (item) =>
          item.name.toLowerCase().contains('pvc cement') &&
          (amount == null || _itemMatchesPackageAmount(item, amount, 'oz')),
    );
    if (match != null) return match;
  }

  final wantsCondensatePumpTubing =
      RegExp(r'\b(condensate|cond)\b').hasMatch(text) &&
      RegExp(r'\b(vinyl\s+)?tubing\b').hasMatch(text) &&
      RegExp(r'\bpump\b').hasMatch(text);
  if (wantsCondensatePumpTubing) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      const ['condensate', 'pump', 'tubing'],
      (name) =>
          name.contains('condensate pump tubing') &&
          _nameMatchesReceiptSize(name, size),
    );
    if (match != null) return match;
  }

  final wantsWaterHeaterDrainValve =
      RegExp(r'\b(water\s+heater|wtr\s+htr|heater)\b').hasMatch(text) &&
      RegExp(
        r'\b(drain\s+valve|heater\s+drain|boiler\s+drain)\b',
      ).hasMatch(text) &&
      !RegExp(r'\bpan\b').hasMatch(text);
  if (wantsWaterHeaterDrainValve) {
    final match = findPlumbing(const [
      'drain',
      'valve',
    ], (name) => name.contains('water heater') && name.contains('drain valve'));
    if (match != null) return match;
  }

  final wantsDishwasherBranchTailpiece = RegExp(
    r'\bdishwasher\s+branch\s+tailpiece\b',
  ).hasMatch(text);
  if (wantsDishwasherBranchTailpiece) {
    final match = findPlumbing(
      const ['dishwasher', 'branch', 'tailpiece'],
      (name) =>
          name.contains('dishwasher disposal drain part') &&
          name.contains('dishwasher branch tailpiece'),
    );
    if (match != null) return match;
  }

  final wantsCleanoutCover =
      RegExp(r'\bcleanout\b').hasMatch(text) &&
      RegExp(r'\bcover\b').hasMatch(text);
  if (wantsCleanoutCover) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbingItem(const ['cleanout', 'access'], (item) {
      final name = item.name.toLowerCase();
      final variant = item.variant.toLowerCase();
      return name.contains('cleanout access part') &&
          variant.contains('cleanout cover') &&
          (size == null ||
              _nameMatchesReceiptSize(name, size) ||
              variant.startsWith('$size in'));
    });
    if (match != null) return match;
  }

  final wantsPushFitSupplyStop =
      RegExp(
        r'\b(push|push\s*fit|push[-\s]*to[-\s]*connect|sharkbite)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(angle\s+stop|supply\s+stop|stop\s+valve|shutoff)\b',
      ).hasMatch(text);
  if (wantsPushFitSupplyStop) {
    final match = findPlumbingItem(
      const ['push-fit', 'supply', 'stop'],
      (item) =>
          item.name.toLowerCase().contains('push-fit supply stop') &&
          _matchesHalfByThreeEighthStop(text, item.variant),
    );
    if (match != null) return match;
  }

  final wantsAbsSanitaryTee =
      RegExp(r'\b(abs|black\s+drain|black\s+dwv)\b').hasMatch(text) &&
      RegExp(r'\b(san\s+tee|sanitary\s+tee|sanitary\s+t)\b').hasMatch(text);
  if (wantsAbsSanitaryTee) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbingItem(const ['abs', 'sanitary', 'tee'], (item) {
      final name = item.name.toLowerCase();
      final variant = _normalize(item.variant);
      return name.contains('abs dwv sanitary tee') &&
          (size == null ||
              variant == '$size in' ||
              variant.startsWith('$size in ') ||
              name.startsWith('$size in '));
    });
    if (match != null) return match;
  }

  final wantsPosiTempCartridge =
      RegExp(r'\bposi\s*temp\b').hasMatch(text) &&
      RegExp(r'\b(shower|cartridge|cart)\b').hasMatch(text);
  if (wantsPosiTempCartridge) {
    final match = findPlumbing(const [
      'shower',
      'cartridge',
    ], (name) => name.contains('shower cartridge'));
    if (match != null) return match;
  }

  final wantsCpvcCoupling =
      RegExp(r'\b(cpvc|cpv\s*c)\b').hasMatch(text) &&
      RegExp(r'\b(coupling|cplg|coup)\b').hasMatch(text);
  if (wantsCpvcCoupling) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      const ['cpvc', 'coupling'],
      (name) =>
          name.contains('cpvc coupling') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsCleanoutPlug =
      RegExp(r'\b(cleanout|clean\s*out|co|limpieza)\b').hasMatch(text) &&
      RegExp(r'\b(plug|tapon)\b').hasMatch(text) &&
      !RegExp(r'\b(abs|black)\b').hasMatch(text);
  if (wantsCleanoutPlug) {
    final size = _nominalReceiptSize(text);
    final match = findPlumbing(
      const ['cleanout', 'plug'],
      (name) =>
          name.contains('cleanout access part') &&
          name.contains('cleanout plug') &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsTailpiece = RegExp(
    r'\b(tailpc|tailpiece|tail\s*piece)\b',
  ).hasMatch(text);
  if (wantsTailpiece) {
    final size = _nominalReceiptSize(text);
    final wantsExtension = RegExp(
      r'\b(ext\s*tube|extension\s+tube|tailpiece\s+extension)\b',
    ).hasMatch(text);
    final match = findPlumbing(
      wantsExtension ? const ['extension', 'tube'] : const ['tailpiece'],
      (name) =>
          (wantsExtension
              ? name.contains('tubular extension tube')
              : name.contains('tailpiece')) &&
          (size == null || _nameMatchesReceiptSize(name, size)),
    );
    if (match != null) return match;
  }

  final wantsDisposalDrainElbow =
      RegExp(
        r'\b(disposal\s+drain\s+(elb|elbow)|disposal\s+elbow)\b',
      ).hasMatch(text) &&
      !RegExp(r'\bgasket\b').hasMatch(text);
  if (wantsDisposalDrainElbow) {
    final match = findPlumbing(const [
      'disposal',
      'drain',
      'elbow',
    ], (name) => name.contains('disposal drain elbow'));
    if (match != null) return match;
  }

  return null;
}
