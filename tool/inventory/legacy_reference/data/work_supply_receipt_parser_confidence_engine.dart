part of 'work_supply_receipt_parser.dart';

bool _isStrongShortCatalogMatch(int score) => score >= 28;

bool _containsTerm(String haystack, String token) {
  return RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(haystack);
}

double _confidence(
  int matchedTermCount,
  String text,
  WorkSupplyItem item, {
  int score = 0,
  String? tradeScope,
  String originalText = '',
}) {
  var confidence = 0.20 + (matchedTermCount * 0.075);
  if (_isStrongShortCatalogMatch(score)) confidence += 0.24;
  final normalizedName = _normalize(item.name);
  if (text.contains(normalizedName)) confidence += 0.08;
  if (item.aliases.any((alias) => text.contains(_normalize(alias)))) {
    confidence += 0.05;
  }
  if (text.contains(item.variant.toLowerCase())) confidence += 0.04;
  if (_isPTrapReceiptMatch(text, item)) confidence += 0.18;
  confidence += _specificityEvidenceScore(text, item);
  confidence -= _receiptAmbiguityRisk(
    _normalize(originalText.isEmpty ? text : originalText),
    item,
    tradeScope,
  );
  return _boundedReceiptConfidence(confidence);
}

double _directReceiptConfidence(
  String text,
  WorkSupplyItem item, {
  String? tradeScope,
  String originalText = '',
}) {
  final receiptText = _normalize(originalText.isEmpty ? text : originalText);
  final evidence = _directMatchedTerms(text, item);
  var confidence = 0.70 + (evidence.length * 0.035);
  if (_isPTrapReceiptMatch(receiptText, item)) confidence += 0.18;
  confidence += _specificityEvidenceScore(receiptText, item);
  confidence -= _receiptAmbiguityRisk(receiptText, item, tradeScope);
  return _boundedReceiptConfidence(confidence);
}

double _learnedCorrectionConfidence(String rawText, WorkSupplyItem item) {
  final normalized = _normalize(rawText);
  var confidence = 0.88;
  if (_withoutTrailingReceiptPrice(normalized) == normalized) {
    confidence += 0.03;
  }
  confidence += _specificityEvidenceScore(normalized, item);
  return _boundedReceiptConfidence(confidence);
}

double _trustedItemIdentityConfidence(String text, WorkSupplyItem item) {
  // A local item identity is an explicit user-confirmed mapping, not an OCR
  // guess. Keep it distinct from high-confidence parser evidence.
  return 0.99;
}

double _vendorMappingConfidence(
  String text,
  WorkSupplyItem item, {
  String? tradeScope,
}) {
  var confidence = 0.88;
  confidence += _specificityEvidenceScore(text, item);
  confidence -= _receiptAmbiguityRisk(text, item, tradeScope) * 0.35;
  return _boundedReceiptConfidence(confidence);
}

bool _hasPTrapReceiptPhrase(String text) {
  final normalized = ' ${text.toLowerCase()} ';
  return normalized.contains(' p trap ') ||
      normalized.contains(' p-trap ') ||
      normalized.contains(' ptrap ');
}

bool _isPTrapReceiptMatch(String text, WorkSupplyItem item) {
  if (!_hasPTrapReceiptPhrase(text) && !text.toLowerCase().contains('trap')) {
    return false;
  }
  final itemText = '${item.name} ${item.variant} ${item.itemType}'
      .toLowerCase();
  return itemText.contains('p-trap') ||
      itemText.contains('p trap') ||
      (itemText.contains('tubular') && itemText.contains('trap'));
}

double _receiptAmbiguityRisk(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  var risk = 0.0;
  if (_isAmbiguousPlumbingCoreLine(text, item)) risk += 0.18;
  if (_isUnscopedAmbiguousReceiptLine(text, item, tradeScope)) risk += 0.22;
  if (_isCrossTradePvcLine(text, item, tradeScope)) risk += 0.16;
  if (_isCrossTradeCopperLine(text, item, tradeScope)) risk += 0.34;
  if (_isGenericFilterLine(text, item, tradeScope)) risk += 0.38;
  if (_isBrokenElectricalSizeLine(text, item)) risk += 0.30;
  if (_isVaguePushFitLine(text, item)) risk += 0.28;
  if (_isVaguePressureGaugeLine(text, item)) risk += 0.24;
  if (_isVagueSoftenerSaltLine(text, item)) risk += 0.30;
  if (_isVagueHvacCapacitorLine(text, item)) risk += 0.38;
  return risk;
}

bool _isVagueHvacCapacitorLine(String text, WorkSupplyItem item) {
  if (item.trade != 'HVAC') return false;
  final itemText = _indexedReceiptTextFor(item);
  if (!itemText.contains('capacitor')) return false;
  if (!RegExp(r'\bcap\b').hasMatch(text)) return false;
  if (!RegExp(r'\b\d{2}/5\b').hasMatch(text)) return false;
  return !RegExp(
    r'\b(mfd|uf|microfarad|dual\s+run|run\s+cap|440v|370v|volt|v)\b',
  ).hasMatch(text);
}

bool _isBrokenElectricalSizeLine(String text, WorkSupplyItem item) {
  if (item.trade != 'Electrical') return false;
  final normalized = _normalize(text);
  if (!RegExp(
    r'\b(nm-b|nmb|romex|mc|armored|wire|cable)\b',
  ).hasMatch(normalized)) {
    return false;
  }
  if (RegExp(r'(^|\s)/\s*\d+\b').hasMatch(normalized)) return true;
  if (RegExp(r'\b\d+\s*/(\s|$)').hasMatch(normalized)) return true;
  if (RegExp(
    r'\b\d+\s*/\s*\b(nm-b|nmb|romex|mc|wire|cable)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  return false;
}

bool _isVaguePushFitLine(String text, WorkSupplyItem item) {
  if (!RegExp(
    r'\b(push|push fit|push-fit|push connect|sharkbite)\b',
  ).hasMatch(text)) {
    return false;
  }
  if (RegExp(
    r'\b(elbow|ell|elb|tee|coupling|cplg|adapter|adpt|cap|stop|valve|'
    r'shutoff|slip|repair|reducer|reducing|mip|fip|male|female)\b',
  ).hasMatch(text)) {
    return false;
  }
  return _indexedReceiptTextFor(item).contains('push');
}

bool _isVaguePressureGaugeLine(String text, WorkSupplyItem item) {
  if (!RegExp(r'\b(pressure gauge|well gauge|manometro)\b').hasMatch(text)) {
    return false;
  }
  if (RegExp(r'\b(well|pozo|psi|pump|bomba|water|agua)\b').hasMatch(text)) {
    return false;
  }
  return _indexedReceiptTextFor(item).contains('pressure gauge');
}

bool _isVagueSoftenerSaltLine(String text, WorkSupplyItem item) {
  if (!RegExp(r'\b(salt pellets?|sal)\b').hasMatch(text)) return false;
  if (RegExp(
    r'\b(softener|suavizador|ablandador|brine|water treatment|agua)\b',
  ).hasMatch(text)) {
    return false;
  }
  final itemText = _indexedReceiptTextFor(item);
  return itemText.contains('softener') || itemText.contains('salt');
}

bool _isCrossTradePvcLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\bpvc\b').hasMatch(text)) return false;
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  final hasTradeSpecificEvidence = RegExp(
    r'\b(dwv|sch|schedule|s40|cond|conduit|electrical|elec|emt|condensate|hvac)\b',
  ).hasMatch(text);
  if (hasTradeSpecificEvidence) return false;
  final canCrossTrades =
      item.trade == 'Plumbing' ||
      item.trade == 'Electrical' ||
      item.trade == 'HVAC';
  return canCrossTrades &&
      RegExp(r'\b(90|45|ell|el|elb|elbow|cplg|coupling|pipe)\b').hasMatch(text);
}

bool _isCrossTradeCopperLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\bcopper\b').hasMatch(text)) return false;
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  if (RegExp(
    r'\b(refrigerant|acr|hvac|water|dwv|type l|type m)\b',
  ).hasMatch(text)) {
    return false;
  }
  final hasCompletePlumbingFittingEvidence =
      _nominalReceiptSize(text) != null &&
      RegExp(
        r'\b(90|45|ell|elb|elbow|tee|coupling|cplg|adapter|adpt)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(cxc|c\s*x\s*c|copper\s+copper|sweat|wrot|mip|fip|male|female)\b',
      ).hasMatch(text);
  if (hasCompletePlumbingFittingEvidence && item.trade == 'Plumbing') {
    return false;
  }
  return item.trade == 'Plumbing' || item.trade == 'HVAC';
}

bool _isGenericFilterLine(
  String text,
  WorkSupplyItem item,
  String? tradeScope,
) {
  if (!RegExp(r'\b(filter|filt)\b').hasMatch(text)) return false;
  final hasSpecificFilterEvidence =
      _hasHvacAirFilterReceiptEvidence(text) ||
      RegExp(
        r'\b(return grille|return air grille|filter grille|water filter|'
        r'sediment filter|carbon filter|pleated filter|filter cartridge|'
        r'oil filter|fuel filter|pool filter|filter drier|secador)\b',
      ).hasMatch(text);
  if (hasSpecificFilterEvidence) return false;
  final itemText = _indexedReceiptTextFor(item);
  return RegExp(
    r'\b(filter|air filter|filter drier|filter grille|water filter|'
    r'oil filter|fuel filter|pool filter)\b',
  ).hasMatch(itemText);
}

double _boundedReceiptConfidence(double confidence) {
  if (confidence < 0.15) return 0.15;
  if (confidence > 0.95) return 0.95;
  return confidence;
}

bool _hasHvacAirFilterReceiptEvidence(String text) {
  if (!RegExp(r'\b(filter|filt)\b').hasMatch(text)) return false;
  if (RegExp(
    r'\b(drier|dri|secador|liquid|liq|linea|water|oil|fuel|pool|'
    r'grille|register|rack|base|housing)\b',
  ).hasMatch(text)) {
    return false;
  }
  final hasAirFilterWords = RegExp(
    r'\b(air|furn|furnace|pleated|merv\d*|hvac|ac)\b',
  ).hasMatch(text);
  return hasAirFilterWords &&
      (_nominalReceiptSize(text) != null || _receiptSizeMatrix(text) != null);
}
