import 'work_supply_catalog.dart' as catalog;
import 'work_supply_models.dart';
import 'work_supply_receipt_confidence.dart';

part 'work_supply_receipt_parser_terms.dart';
part 'work_supply_receipt_parser_locale_terms.dart';
part 'inventory_parsers/plumbing/plumbing_fast_matcher.dart';
part 'inventory_parsers/plumbing/plumbing_receipt_term_aliases.dart';
part 'work_supply_receipt_parser_fastener_terms.dart';
part 'work_supply_receipt_parser_electrical_service_matcher.dart';
part 'work_supply_receipt_parser_electrical_service_and_safety_matcher.dart';
part 'inventory_parsers/hvac/hvac_core_parser.dart';
part 'inventory_parsers/hvac/hvac_air_drain_and_duct_parser.dart';
part 'inventory_parsers/hvac/hvac_equipment_and_service_parts_parser.dart';
part 'inventory_parsers/hvac/hvac_receipt_precedence_parser.dart';
part 'inventory_parsers/hvac/hvac_unscoped_evidence_parser.dart';
part 'inventory_parsers/plumbing/plumbing_receipt_precedence_parser.dart';
part 'inventory_parsers/electrical/electrical_receipt_score.dart';
part 'inventory_parsers/plumbing/plumbing_receipt_score.dart';
part 'inventory_parsers/hvac/hvac_receipt_score.dart';
part 'inventory_parsers/hvac/hvac_equipment_and_air_filter_receipt_score.dart';
part 'inventory_parsers/hvac/hvac_air_distribution_and_gas_receipt_score.dart';
part 'inventory_parsers/hvac/hvac_service_equipment_and_tool_receipt_score.dart';
part 'inventory_parsers/shared/receipt_confidence_specificity.dart';
part 'inventory_parsers/shared/receipt_catalog_context.dart';
part 'inventory_parsers/shared/receipt_catalog_index_parity_qa.dart';
part 'inventory_parsers/shared/receipt_noise.dart';
part 'inventory_parsers/shared/term_aliases/receipt_electrical_and_hvac_term_aliases.dart';
part 'inventory_parsers/shared/term_aliases/receipt_construction_and_appliance_term_aliases.dart';
part 'inventory_parsers/shared/term_aliases/receipt_cabinets_doors_and_finishes_term_aliases.dart';
part 'inventory_parsers/shared/term_aliases/receipt_roofing_siding_and_flooring_term_aliases.dart';
part 'inventory_parsers/shared/term_aliases/receipt_tile_and_insulation_term_aliases.dart';
part 'inventory_parsers/shared/term_aliases/receipt_fencing_masonry_landscape_and_tool_term_aliases.dart';
part 'work_supply_receipt_parser_fallback_specificity.dart';
part 'work_supply_receipt_parser_trade_scores.dart';
part 'work_supply_receipt_parser_confidence_engine.dart';
part 'work_supply_receipt_parser_trade_scores_appliances.dart';
part 'work_supply_receipt_parser_trade_scores_core.dart';
part 'inventory_parsers/cabinets_countertops/cabinets_and_countertops_receipt_score.dart';
part 'work_supply_receipt_parser_trade_scores_drywall.dart';
part 'work_supply_receipt_parser_trade_scores_painting.dart';
part 'work_supply_receipt_parser_trade_scores_roofing.dart';
part 'work_supply_receipt_parser_trade_scores_tile.dart';
part 'work_supply_receipt_parser_trade_scores_tile_waterproofing.dart';
part 'work_supply_receipt_parser_trade_scores_tile_tools.dart';
part 'work_supply_receipt_parser_trade_scores_flooring.dart';
part 'work_supply_receipt_parser_trade_scores_insulation.dart';
part 'work_supply_receipt_parser_trade_scores_siding_exterior.dart';
part 'work_supply_receipt_parser_trade_scores_fencing.dart';
part 'work_supply_receipt_parser_trade_scores_masonry_concrete.dart';
part 'work_supply_receipt_parser_trade_scores_landscaping.dart';
part 'work_supply_receipt_parser_trade_scores_tools_safety.dart';
part 'work_supply_receipt_parser_trade_scores_finishes.dart';
part 'work_supply_receipt_parser_trade_scores_exterior.dart';
part 'work_supply_receipt_parser_trade_scores_garage.dart';
part 'work_supply_receipt_parser_trade_scores_low_voltage_tools.dart';
part 'work_supply_receipt_parser_trade_scores_well_septic.dart';
part 'work_supply_receipt_parser_ambiguity_helpers.dart';

class ReceiptLineMatch {
  const ReceiptLineMatch({
    required this.rawText,
    required this.item,
    required this.confidence,
    required this.matchedTerms,
    this.source = ReceiptMatchSource.catalog,
  });

  final String rawText;
  final WorkSupplyItem item;
  final double confidence;
  final List<String> matchedTerms;
  final ReceiptMatchSource source;

  ReceiptConfidenceLevel get confidenceLevel =>
      receiptConfidenceLevelFor(confidence);

  bool get needsReview => true;

  String get confidenceLabel => receiptConfidenceLabel(confidenceLevel);

  String get confidenceGuidance => receiptConfidenceGuidance(confidenceLevel);
}

enum ReceiptMatchSource { catalog, learnedCorrection, trustedItemIdentity }

typedef _ReceiptCatalogEntry = ({
  WorkSupplyItem item,
  String searchableText,
  String normalizedText,
  String variantText,
});

typedef _ReceiptVendorMappingEntry = ({
  WorkSupplyItem item,
  String code,
  String label,
});

final Map<String, String> _receiptTextCacheByItemId = {};

class ReceiptParserLearningMemory {
  ReceiptParserLearningMemory([Map<String, String>? learnedItemIds])
    : _learnedItemIds = {...?learnedItemIds};

  final Map<String, String> _learnedItemIds;

  void confirmCorrection({
    required String receiptLine,
    required WorkSupplyItem item,
  }) {
    _learnedItemIds[_normalize(receiptLine)] = item.id;
  }

  WorkSupplyItem? learnedMatchFor(String receiptLine) {
    final normalized = _normalize(receiptLine);
    final learnedId =
        _learnedItemIds[normalized] ??
        _learnedItemIds[_withoutTrailingReceiptPrice(normalized)] ??
        _learnedPrefixMatchId(normalized, _learnedItemIds);
    if (learnedId == null) return null;
    for (final item in _activeWorkSupplyCatalogItems) {
      if (item.id == learnedId) return item;
    }
    return null;
  }
}

String? _learnedPrefixMatchId(
  String normalized,
  Map<String, String> learnedItemIds,
) {
  final clean = _withoutTrailingReceiptPrice(normalized);
  for (final entry in learnedItemIds.entries) {
    final key = entry.key.trim();
    if (key.length < 5) continue;
    if (clean == key ||
        clean.startsWith('$key ') ||
        key.startsWith('$clean ')) {
      return entry.value;
    }
  }
  return null;
}

String _withoutTrailingReceiptPrice(String normalized) {
  return normalized.replaceFirst(RegExp(r'\s+\d+\s+\d{2}$'), '').trim();
}

ReceiptLineMatch? matchReceiptLineToCatalog(
  String rawText, {
  ReceiptParserLearningMemory? memory,
  Map<String, String> trustedItemIdentityIds = const {},
  int maxCandidates = 80,
  String? tradeScope,
  String localePackId = '',
  List<WorkSupplyItem>? catalogItems,
}) {
  return _runWithReceiptCatalogItems(
    catalogItems,
    tradeScope: tradeScope,
    action: () => _matchReceiptLineToActiveCatalog(
      rawText,
      memory: memory,
      trustedItemIdentityIds: trustedItemIdentityIds,
      maxCandidates: maxCandidates,
      tradeScope: tradeScope,
      localePackId: localePackId,
    ),
  );
}

ReceiptLineMatch? _matchReceiptLineToActiveCatalog(
  String rawText, {
  ReceiptParserLearningMemory? memory,
  Map<String, String> trustedItemIdentityIds = const {},
  int maxCandidates = 80,
  String? tradeScope,
  String localePackId = '',
}) {
  final learned = memory?.learnedMatchFor(rawText);
  if (learned != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: learned,
      confidence: _learnedCorrectionConfidence(rawText, learned),
      matchedTerms: const ['learned'],
      source: ReceiptMatchSource.learnedCorrection,
    );
  }
  if (maxCandidates <= 0) return null;
  final normalized = _normalize(rawText);
  if (_isReceiptNoiseLine(normalized)) return null;
  if (_looksLikeHostileInputText(rawText, normalized)) return null;
  final directPvcDwvSanitaryTee = _directPvcDwvSanitaryTeeReceiptMatch(
    normalized,
  );
  if (directPvcDwvSanitaryTee != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: directPvcDwvSanitaryTee,
      confidence: _directReceiptConfidence(
        normalized,
        directPvcDwvSanitaryTee,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, directPvcDwvSanitaryTee),
    );
  }
  if (tradeScope != null && tradeScope.trim().toLowerCase() == 'plumbing') {
    final sumpBarbedAdapter = _directScopedPlumbingSumpBarbedAdapterMatch(
      normalized,
    );
    if (sumpBarbedAdapter != null) {
      return ReceiptLineMatch(
        rawText: rawText,
        item: sumpBarbedAdapter,
        confidence: _directReceiptConfidence(
          normalized,
          sumpBarbedAdapter,
          tradeScope: tradeScope,
          originalText: normalized,
        ),
        matchedTerms: _directMatchedTerms(normalized, sumpBarbedAdapter),
      );
    }
  }
  if (_isScopedPlumbingDangerousElbowReviewLine(normalized, tradeScope)) {
    return null;
  }
  if (_isUnscopedDangerousShortLine(normalized, tradeScope)) return null;
  final trustedIdentity = _directTrustedItemIdentityMatch(
    normalized,
    trustedItemIdentityIds,
    tradeScope: tradeScope,
  );
  if (trustedIdentity != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: trustedIdentity,
      confidence: _trustedItemIdentityConfidence(normalized, trustedIdentity),
      matchedTerms: const ['trusted-item-identity'],
      source: ReceiptMatchSource.trustedItemIdentity,
    );
  }
  if (tradeScope?.trim().toLowerCase() == 'electrical') {
    final electricalDevice = _directElectricalDeviceMatch(
      normalized,
      tradeScope: tradeScope,
    );
    if (electricalDevice != null) {
      return ReceiptLineMatch(
        rawText: rawText,
        item: electricalDevice,
        confidence: _directReceiptConfidence(
          normalized,
          electricalDevice,
          tradeScope: tradeScope,
          originalText: normalized,
        ),
        matchedTerms: _directMatchedTerms(normalized, electricalDevice),
      );
    }
  }
  if (tradeScope?.trim().toLowerCase() == 'hvac') {
    final hvac = _directHvacReceiptPrecedenceMatch(
      normalized,
      tradeScope: tradeScope,
    );
    if (hvac != null) {
      return ReceiptLineMatch(
        rawText: rawText,
        item: hvac,
        confidence: _directReceiptConfidence(
          normalized,
          hvac,
          tradeScope: tradeScope,
          originalText: normalized,
        ),
        matchedTerms: _directMatchedTerms(normalized, hvac),
      );
    }
  }
  final masonryConcreteAnchor = _directMasonryConcreteAnchorReceiptMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (masonryConcreteAnchor != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: masonryConcreteAnchor,
      confidence: _directReceiptConfidence(
        normalized,
        masonryConcreteAnchor,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, masonryConcreteAnchor),
    );
  }
  final landscapingDrainage = _directLandscapingDrainageReceiptMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (landscapingDrainage != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: landscapingDrainage,
      confidence: _directReceiptConfidence(
        normalized,
        landscapingDrainage,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, landscapingDrainage),
    );
  }
  final plumbingPrecedence = _directPlumbingReceiptPrecedenceMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (plumbingPrecedence != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: plumbingPrecedence,
      confidence: _directReceiptConfidence(
        normalized,
        plumbingPrecedence,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, plumbingPrecedence),
    );
  }
  final electricalProfessional = _directElectricalProfessionalMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (electricalProfessional != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: electricalProfessional,
      confidence: _directReceiptConfidence(
        normalized,
        electricalProfessional,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, electricalProfessional),
    );
  }
  final fastDirect = _directFastReceiptMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (fastDirect != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: fastDirect,
      confidence: _directReceiptConfidence(
        normalized,
        fastDirect,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(normalized, fastDirect),
    );
  }
  if (tradeScope != null && tradeScope.trim().toLowerCase() == 'plumbing') {
    final pexServiceFitting = _directPlumbingPexServiceFittingMatch(normalized);
    if (pexServiceFitting != null) {
      return ReceiptLineMatch(
        rawText: rawText,
        item: pexServiceFitting,
        confidence: _directReceiptConfidence(
          normalized,
          pexServiceFitting,
          tradeScope: tradeScope,
          originalText: normalized,
        ),
        matchedTerms: const ['pex-service-fitting'],
      );
    }
  }
  final expanded = _expandAliases(normalized, localePackId: localePackId);
  final direct = _directHighSpecificityReceiptMatch(
    expanded,
    tradeScope: tradeScope,
    originalText: normalized,
  );
  if (direct != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: direct,
      confidence: _directReceiptConfidence(
        expanded,
        direct,
        tradeScope: tradeScope,
        originalText: normalized,
      ),
      matchedTerms: _directMatchedTerms(expanded, direct),
    );
  }
  final vendorMapped = _directVendorMappingReceiptMatch(
    normalized,
    tradeScope: tradeScope,
  );
  if (vendorMapped != null) {
    return ReceiptLineMatch(
      rawText: rawText,
      item: vendorMapped,
      confidence: _vendorMappingConfidence(
        normalized,
        vendorMapped,
        tradeScope: tradeScope,
      ),
      matchedTerms: const ['vendor-mapping'],
    );
  }
  final fallbackCandidates = _fallbackReceiptCandidates(
    expanded,
    maxCandidates: maxCandidates,
    tradeScope: tradeScope,
  );
  final searchLimit = maxCandidates < 16 ? maxCandidates : 16;
  final candidatePool = fallbackCandidates.isNotEmpty
      ? fallbackCandidates
      : _searchActiveReceiptCatalogItems(_parserSearchText(expanded))
            .where((item) => _matchesTradeScope(item, tradeScope))
            .take(searchLimit)
            .toList();
  if (candidatePool.isEmpty) return null;
  final scored =
      [
        for (final item in candidatePool)
          _scoredReceiptCandidate(expanded, item),
      ]..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        return a.item.name.compareTo(b.item.name);
      });
  final best = scored.first;
  if (best.terms.length < 3 && !_isStrongShortCatalogMatch(best.score)) {
    return null;
  }
  final confidence = _confidence(
    best.terms.length,
    expanded,
    best.item,
    score: best.score,
    tradeScope: tradeScope,
    originalText: rawText,
  );
  return ReceiptLineMatch(
    rawText: rawText,
    item: best.item,
    confidence: confidence,
    matchedTerms: best.terms,
  );
}

String normalizeMerchantName(String rawText) {
  final normalized = _normalize(rawText);
  if (_looksLikeHostileInputText(rawText, normalized)) return normalized;
  for (final entry in receiptMerchantAliases.entries) {
    if (entry.value.any(normalized.contains)) return entry.key;
  }
  return normalized;
}

bool _looksLikeHostileInputText(String rawText, String normalized) {
  final raw = rawText.toLowerCase();
  if (raw.contains('\u0000') || raw.contains('\u0001')) return true;
  if (raw.contains('\u202e') || raw.contains('\u202d')) return true;
  if (raw.contains('<') || raw.contains('>')) return true;
  if (raw.contains(r'$ne') || raw.contains(r'\system32')) return true;
  final compact = normalized.replaceAll(' ', '');
  if (compact.contains('..') || raw.contains('\\')) return true;
  if (RegExp(
    r'\b(drop\s+table|select\s+.+\s+from|insert\s+into|delete\s+from|'
    r'update\s+.+\s+set|where\s+.+\s*=)\b',
  ).hasMatch(normalized)) {
    return true;
  }
  const hostileTokens = {
    'script',
    'hyperlink',
    'http',
    'https',
    'cmd',
    'powershell',
  };
  final tokens = normalized.split(RegExp(r'\s+'));
  return tokens.any(hostileTokens.contains);
}

String _parserSearchText(String value) {
  final tokens = value
      .split(RegExp(r'\s+'))
      .where((token) => !_isParserNoiseToken(token))
      .toList();
  return tokens.join(' ');
}

bool _isParserNoiseToken(String token) {
  return switch (token) {
    'lowes' ||
    'lowe' ||
    'home' ||
    'depot' ||
    'hd' ||
    'hdsupply' ||
    'menards' ||
    'menard' ||
    'ferguson' ||
    'ferg' ||
    'grainger' ||
    'ace' ||
    'true' ||
    'value' ||
    'truevalue' ||
    'wal' ||
    'mart' ||
    'walmart' ||
    'tractor' ||
    'tsc' ||
    'best' ||
    'doitbest' ||
    'mccoys' ||
    'mccoy' ||
    'supplyhouse' ||
    'winsupply' ||
    'winwater' ||
    'hajoca' ||
    'hughes' ||
    'reece' ||
    'morsco' ||
    'morrison' ||
    'webb' ||
    'coremain' ||
    'the' ||
    'sku' ||
    'item' ||
    'qty' ||
    'ea' ||
    'ft' => true,
    _ => false,
  };
}

List<WorkSupplyItem> _fallbackReceiptCandidates(
  String text, {
  required int maxCandidates,
  String? tradeScope,
}) {
  final tokens = _receiptCandidateTokens(text);
  if (tokens.isEmpty) return const [];
  final candidateScores = <String, int>{};
  for (final token in tokens) {
    for (final alternate in _receiptTokenAlternates(token)) {
      final entries = _receiptCatalogTokenIndex[alternate];
      if (entries == null) continue;
      for (final entry in entries) {
        candidateScores.update(
          entry.item.id,
          (score) => score + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }
  if (candidateScores.isEmpty) return const [];
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final id in candidateScores.keys) {
    final entry = _receiptCatalogEntryById[id];
    if (entry == null) continue;
    if (!_matchesTradeScope(entry.item, tradeScope)) continue;
    var score = candidateScores[id] ?? 0;
    final packCount = RegExp(r'\b(\d+)\s*pack\b').firstMatch(text);
    if (packCount != null &&
        entry.normalizedText.contains('${packCount.group(1)} pack')) {
      score += 80;
    }
    if (RegExp(r'\b(drywall|sheetrock|gypsum)\s+screws?\b').hasMatch(text) &&
        entry.item.trade == 'Drywall' &&
        entry.normalizedText.contains('screw')) {
      score += 120;
    }
    if (text.contains('condenser pad') && entry.item.trade == 'HVAC') {
      if (entry.normalizedText.contains('condenser pad')) {
        score += 140;
      } else if (entry.normalizedText.contains('equipment pad')) {
        score -= 40;
      }
    }
    if (entry.variantText.isNotEmpty && text.contains(entry.variantText)) {
      score += 20;
    }
    score += _receiptFallbackSpecificityScore(text, entry);
    score += _tradeContextScore(text, entry.item);
    if (score > 0) scored.add((item: entry.item, score: score));
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(maxCandidates).toList();
}

List<String> _receiptCandidateTokens(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where(
        (token) =>
            token.isNotEmpty &&
            !_isParserNoiseToken(token) &&
            (token.length > 2 || token.contains('/') || token.contains('-')),
      )
      .toList();
}

Map<String, List<_ReceiptCatalogEntry>> _buildReceiptCatalogTokenIndex(
  List<_ReceiptCatalogEntry> entries,
) {
  final index = <String, List<_ReceiptCatalogEntry>>{};
  for (final entry in entries) {
    final tokens = _receiptCandidateTokens(entry.normalizedText).toSet();
    for (final token in tokens) {
      index.putIfAbsent(token, () => []).add(entry);
    }
  }
  return {
    for (final entry in index.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}

bool _matchesTradeScope(WorkSupplyItem item, String? tradeScope) {
  if (tradeScope == null || tradeScope.trim().isEmpty) return true;
  return item.trade.toLowerCase() == tradeScope.trim().toLowerCase();
}

WorkSupplyItem? _directTrustedItemIdentityMatch(
  String normalized,
  Map<String, String> trustedItemIdentityIds, {
  String? tradeScope,
}) {
  if (trustedItemIdentityIds.isEmpty) return null;
  final compactReceipt = _compactVendorCode(normalized);
  if (compactReceipt.length < 4) return null;
  final normalizedReceipt = _withoutTrailingReceiptPrice(normalized);
  for (final entry in trustedItemIdentityIds.entries) {
    final trustedKey = _normalize(entry.key);
    final compactKey = _compactVendorCode(entry.key);
    if (trustedKey.length < 4 && compactKey.length < 4) continue;
    final matchesTrustedKey =
        (trustedKey.length >= 4 &&
            (normalizedReceipt == trustedKey ||
                normalizedReceipt.contains(trustedKey))) ||
        (compactKey.length >= 4 && compactReceipt.contains(compactKey));
    if (!matchesTrustedKey) continue;
    final catalogEntry = _receiptCatalogEntryById[entry.value.trim()];
    if (catalogEntry == null) continue;
    if (!_matchesTradeScope(catalogEntry.item, tradeScope)) continue;
    return catalogEntry.item;
  }
  return null;
}

WorkSupplyItem? _directVendorMappingReceiptMatch(
  String normalized, {
  String? tradeScope,
}) {
  final compactReceipt = _compactVendorCode(normalized);
  if (compactReceipt.length < 4) return null;
  for (final entry in _receiptVendorMappingIndex) {
    final item = entry.item;
    if (!_matchesTradeScope(item, tradeScope)) continue;
    final code = entry.code;
    final label = entry.label;
    if ((code.length >= 4 && compactReceipt.contains(code)) ||
        (label.length >= 4 && normalized.contains(label))) {
      return item;
    }
  }
  return null;
}

String _compactVendorCode(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

WorkSupplyItem? _directPlumbingHandToolMatch(String text) {
  if (!_looksLikePlumbingHandTool(text)) return null;
  final target = _plumbingHandToolTarget(text);
  if (target == null) return null;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Plumbing' &&
        item.system == 'Plumbing Hand Tools' &&
        name.contains(target)) {
      return item;
    }
  }
  return null;
}

bool _looksLikePlumbingHandTool(String text) {
  return RegExp(
    r'\b(tool|cutter|deburr|reamer|wrench|auger|snake|hole saw|'
    r'blade|sawzall|recip|propress|press jaw|press fitting|'
    r'expander|expansion head|expander head)\b',
  ).hasMatch(text);
}

String? _plumbingHandToolTarget(String text) {
  if (RegExp(r'\b(cinch clamp|pex cinch|pex clamp)\b').hasMatch(text)) {
    return 'pex clamp cinch tool';
  }
  if (RegExp(r'\b(expander head|expansion head)\b').hasMatch(text)) {
    return 'pex tubing expander head kit';
  }
  if (RegExp(r'\b(pex expander|pex expansion)\b').hasMatch(text)) {
    return 'pex expansion tool';
  }
  if (RegExp(r'\b(1/2|half).*(propress|press jaw)\b').hasMatch(text)) {
    return '1/2 in propress jaw';
  }
  if (RegExp(r'\b(3/4).*(propress|press jaw)\b').hasMatch(text)) {
    return '3/4 in propress jaw';
  }
  if (RegExp(
    r'\b(propress|press fitting tool jaw|press jaw)\b',
  ).hasMatch(text)) {
    return 'copper press fitting tool jaw';
  }
  if (RegExp(
    r'\bpex\s+(crimp|crmp)\s+tool|(crimp|crmp)\s+tool\b',
  ).hasMatch(text)) {
    return 'pex crimp tool';
  }
  if (RegExp(r'\bbasin wrench\b').hasMatch(text)) return 'basin wrench';
  if (RegExp(r'\bstrap wrench\b').hasMatch(text)) return 'strap wrench';
  if (RegExp(r'\b(closet auger|toilet auger)\b').hasMatch(text)) {
    return 'closet auger';
  }
  if (RegExp(r'\bhand drain auger\b').hasMatch(text)) return 'hand drain auger';
  if (RegExp(r'\b(drain snake|small drain snake)\b').hasMatch(text)) {
    return 'small drain snake';
  }
  if (RegExp(r'\b2-?1/8.*hole saw\b').hasMatch(text)) {
    return '2-1/8 in hole saw';
  }
  if (RegExp(r'\b1-?1/2.*hole saw\b').hasMatch(text)) {
    return '1-1/2 in hole saw';
  }
  if (RegExp(
    r'\bcast iron.*(recip|sawzall).*blade|carbide.*cast iron',
  ).hasMatch(text)) {
    return 'carbide cast iron reciprocating saw blade';
  }
  if (RegExp(r'\bpvc|plastic\b').hasMatch(text) &&
      RegExp(r'\b(recip|sawzall).*blade|blade\b').hasMatch(text)) {
    return 'pvc plastic reciprocating saw blade';
  }
  if (RegExp(r'\b9\s*in|9in\b').hasMatch(text) &&
      RegExp(r'\b(recip|sawzall).*blade|blade\b').hasMatch(text)) {
    return 'bi-metal reciprocating saw blade 9 in';
  }
  if (RegExp(r'\b6\s*in|6in\b').hasMatch(text) &&
      RegExp(r'\b(recip|sawzall).*blade|blade\b').hasMatch(text)) {
    return 'bi-metal reciprocating saw blade 6 in';
  }
  if (RegExp(r'\bmini tubing cutter|tubing cutter\b').hasMatch(text)) {
    return 'mini tubing cutter';
  }
  if (RegExp(r'\b(pipe cutter|pvc cutter|ratchet cutter)\b').hasMatch(text)) {
    return 'ratcheting pvc pipe cutter';
  }
  if (RegExp(
    r'\b(deburring tool|deburr tool|pvc deburring)\b',
  ).hasMatch(text)) {
    return 'pvc deburring tool';
  }
  if (RegExp(r'\b(reaming tool|reamer|pipe reamer)\b').hasMatch(text)) {
    return 'copper pipe reaming tool';
  }
  if (RegExp(r'\binside pipe cutter\b').hasMatch(text)) {
    return 'inside pipe cutter';
  }
  return null;
}

WorkSupplyItem? _directElectricalConsumableMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'electrical') {
    return null;
  }
  if (!RegExp(
    r'\b(elec|electric|electrical)\s+tape\b|'
    r'\bcinta\s+(electrica|aislante)\b',
  ).hasMatch(text)) {
    return null;
  }
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' && name.contains('electrical tape')) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directElectricalControlMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope == null ||
      tradeScope.trim().isEmpty ||
      tradeScope.trim().toLowerCase() != 'electrical') {
    return null;
  }
  final wantedName = switch (text) {
    final value when RegExp(r'\bcontactor\b').hasMatch(value) => 'contactor',
    final value
        when RegExp(r'\b(time\s+clock|timer\s+clock)\b').hasMatch(value) =>
      'time clock',
    final value
        when RegExp(r'\bfan\s+speed\s+(control|ctrl)\b').hasMatch(value) =>
      'fan speed control',
    final value
        when RegExp(r'\b(photo\s*cell|photocell|photoeye)\b').hasMatch(value) =>
      'photocell',
    final value
        when RegExp(r'\brelay\b').hasMatch(value) &&
            !RegExp(r'\b(time\s+delay|delay)\b').hasMatch(value) =>
      'relay',
    _ => null,
  };
  if (wantedName == null) return null;
  final amp = RegExp(r'\b(15|20|30|40)\s*amp\b').firstMatch(text)?.group(1);
  final voltage = RegExp(r'\b(120|240)\s*v\b').firstMatch(text)?.group(1);
  WorkSupplyItem? fallback;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade != 'Electrical' || !name.contains(wantedName)) continue;
    if (amp != null && !name.contains('$amp amp')) continue;
    if (voltage != null && !name.contains('${voltage}v')) continue;
    if (item.packTier == WorkSupplyPackTier.core) return item;
    fallback ??= item;
  }
  return fallback;
}

WorkSupplyItem? _directElectricalRacewayMatch(
  String text, {
  String? tradeScope,
}) {
  final scope = tradeScope?.trim().toLowerCase();
  if (scope != null && scope.isNotEmpty && scope != 'electrical') {
    return null;
  }
  if ((scope == null || scope.isEmpty) &&
      !RegExp(r'\b(conduit|electrical|elec)\b').hasMatch(text)) {
    return null;
  }
  final isPvcConduit =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cond|conduit|elec|electrical)\b').hasMatch(text);
  if (!isPvcConduit) return null;
  final wantedName = switch (text) {
    final value when RegExp(r'\b(90|ell|elbow)\b').hasMatch(value) =>
      'pvc electrical 90 elbow',
    final value when RegExp(r'\b(cpl|cplg|coupling)\b').hasMatch(value) =>
      'pvc electrical coupling',
    final value
        when RegExp(
          r'\b(male|mip|terminal adapter|male adapter)\b',
        ).hasMatch(value) =>
      'pvc electrical male adapter',
    final value
        when RegExp(r'\b(female|fip|female adapter)\b').hasMatch(value) =>
      'pvc electrical female adapter',
    _ => 'pvc electrical conduit',
  };
  final size = _nominalReceiptSize(text);
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' &&
        name.contains(wantedName) &&
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directElectricalBoxMatch(String text, {String? tradeScope}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'electrical') {
    return null;
  }
  final saysBox = RegExp(
    r'\b(box|caja|remod(?:el)?|remodelacion|old work)\b',
  ).hasMatch(text);
  if (!saysBox || !RegExp(r'\b(1g|1 gang|2g|2 gang)\b').hasMatch(text)) {
    return null;
  }
  final desiredGang = RegExp(r'\b(2g|2 gang)\b').hasMatch(text)
      ? '2 gang'
      : '1 gang';
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' &&
        name.contains('electrical box') &&
        name.contains('old work') &&
        name.contains(desiredGang)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directElectricalCableStapleMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'electrical') {
    return null;
  }
  final wantsStaple = RegExp(
    r'\b(romex|nm|nm-b|cable|grapa)\s+(staple|grapa)|'
    r'\b(staple|grapa)\s+(romex|nm|nm-b|cable)\b',
  ).hasMatch(text);
  if (!wantsStaple) return null;
  final prefersLarge = RegExp(r'\b(10/2|8/2|3/4)\b').hasMatch(text);
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' && name.contains('cable staple')) {
      if (!prefersLarge || name.contains('10/2') || name.contains('8/2')) {
        return item;
      }
    }
  }
  return null;
}

WorkSupplyItem? _directApplianceInstallMatch(
  String text, {
  String? tradeScope,
}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'appliance installation and repair') {
    return null;
  }
  final wantedName = switch (text) {
    final value
        when RegExp(r'\b(dishwasher|dw)\b').hasMatch(value) &&
            RegExp(
              r'\b(connector|connecter|conn|supply|line|kit|compression)\b',
            ).hasMatch(value) =>
      'compression dishwasher connector kit',
    final value
        when RegExp(r'\b(dishwasher|dw)\b').hasMatch(value) &&
            RegExp(r'\b(drain\s+hose|hose)\b').hasMatch(value) =>
      'dishwasher drain hose',
    final value
        when RegExp(r'\b(dishwasher|dw)\b').hasMatch(value) &&
            RegExp(r'\b(power\s+cord|cord)\b').hasMatch(value) =>
      'dishwasher power cord kit',
    _ => null,
  };
  if (wantedName == null) return null;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Appliance Installation and Repair' &&
        name.contains(wantedName)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directHighSpecificityReceiptMatch(
  String text, {
  String? tradeScope,
  String? originalText,
}) {
  final receiptText = originalText ?? text;
  final hvacPrecedence = _directHvacReceiptPrecedenceMatch(
    text,
    tradeScope: tradeScope,
  );
  if (hvacPrecedence != null) return hvacPrecedence;
  final fastDirect = _directFastReceiptMatch(text, tradeScope: tradeScope);
  if (fastDirect != null) return fastDirect;
  if (tradeScope == null || tradeScope.trim().isEmpty) {
    final unscopedHvac = _directUnscopedHvacEvidenceMatch(receiptText);
    if (unscopedHvac != null) return unscopedHvac;
  }
  final electricalServiceRepair = _directElectricalServiceRepairMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalServiceRepair != null) return electricalServiceRepair;
  final electricalConsumable = _directElectricalConsumableMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalConsumable != null) return electricalConsumable;
  final electricalLowVoltageCable = _directElectricalLowVoltageCableMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalLowVoltageCable != null) return electricalLowVoltageCable;
  final electricalWireCable = _directElectricalWireCableMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalWireCable != null) return electricalWireCable;
  final electricalDevice = _directElectricalDeviceMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalDevice != null) return electricalDevice;
  final electricalControl = _directElectricalControlMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalControl != null) return electricalControl;
  final electricalRaceway = _directElectricalRacewayMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalRaceway != null) return electricalRaceway;
  final electricalBox = _directElectricalBoxMatch(text, tradeScope: tradeScope);
  if (electricalBox != null) return electricalBox;
  final electricalCableStaple = _directElectricalCableStapleMatch(
    text,
    tradeScope: tradeScope,
  );
  if (electricalCableStaple != null) return electricalCableStaple;
  final hvacCore = _directHvacCoreMatch(text, tradeScope: tradeScope);
  if (hvacCore != null) return hvacCore;
  if (tradeScope == null || tradeScope.trim().isEmpty) {
    final unscopedElectrical = _directUnscopedElectricalEvidenceMatch(text);
    if (unscopedElectrical != null) return unscopedElectrical;
    final unscopedHvac = _directUnscopedHvacEvidenceMatch(text);
    if (unscopedHvac != null) return unscopedHvac;
  }
  final applianceDirect = _directApplianceInstallMatch(
    text,
    tradeScope: tradeScope,
  );
  if (applianceDirect != null) return applianceDirect;
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'plumbing') {
    return null;
  }
  final plumbingDirect = _directPlumbingFastMatch(text);
  if (plumbingDirect != null) return plumbingDirect;
  if (RegExp(
    r'\b(trampa p|trampa lavamanos|trampa lavabo|p trap|p-trap)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text) ?? _explicitTubularTrapSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular p-trap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(kit triturador|conector disposal|disposal install kit|'
    r'disposal kit|garbage disposal connector)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('disposal install kit')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(drenaje pop up|lav pop up|pop up drain|pop-up drain)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pop-up')) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(conector calentador|linea calentador|water heater|wtr htr)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(conector|linea|conn|connector|line|hose|water heater line|'
        r'heater supply)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('water heater connector')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(rompedor vacio|vac brkr|vac breaker|vacuum breaker|backflow preventer)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('vacuum breaker') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(manguera lavadora|manguera lavanderia|washing machine hose|'
    r'washer hose|washer supply hose|laundry hose)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('washing machine hose')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(valvula angulo|llave angular|llave escuadra|br ang stop|comp stop)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          !name.contains('push-fit') &&
          (name.contains('quarter turn angle stop') ||
              name.contains('angle stop valve'))) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(manometro presion pozo|manometro de presion|presion pozo|well pressure gauge|pressure gauge|well gauge)\b',
      ).hasMatch(text) &&
      !RegExp(r'\b(switch|interruptor|presostato)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pressure gauge')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(well pressure switch|pump pressure switch|pressure switch|well switch|switch presion pozo|interruptor bomba|presostato)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('well pressure switch')) {
        if ((text.contains('40/60') || text.contains('40 60')) &&
            !name.contains('40/60')) {
          continue;
        }
        if ((text.contains('30/50') || text.contains('30 50')) &&
            !name.contains('30/50')) {
          continue;
        }
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(well pump|jet pump|shallow well|deep well|bomba pozo|bomba de pozo|bomba agua pozo)\b',
      ).hasMatch(text) &&
      !RegExp(r'\b(check|chk|valve|valv|switch|sw|gauge)\b').hasMatch(text)) {
    final wantsShallow = RegExp(
      r'\b(shallow|jet|superficial)\b',
    ).hasMatch(text);
    final wantsDeep = RegExp(
      r'\b(deep|submersible|sumergible|profundo)\b',
    ).hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' || !name.contains('well pump')) continue;
      if (wantsShallow && !name.contains('shallow')) continue;
      if (wantsDeep && !name.contains('deep')) continue;
      return item;
    }
  }
  if (RegExp(
        r'\b(valvula llenado|valvula de llenado|toilet fill|fill valve|ballcock)\b',
      ).hasMatch(text) &&
      RegExp(
        r'\b(wc|toilet|inodoro|sanitario|universal|tank)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('toilet fill valve')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(sediment|carbon|pleated|water)\b').hasMatch(text) &&
      RegExp(r'\b(filter|flt)\b').hasMatch(text) &&
      RegExp(r'\b(cartridge|cart|element)\b').hasMatch(text)) {
    final wantsSediment = text.contains('sediment');
    final wantsCarbon = text.contains('carbon');
    final wantsPleated = text.contains('pleated');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (!name.contains('water filter service part')) continue;
      if (!name.contains('filter cartridge')) continue;
      if (wantsSediment && !name.contains('sediment')) continue;
      if (wantsCarbon && !name.contains('carbon')) continue;
      if (wantsPleated && !name.contains('pleated')) continue;
      return item;
    }
  }
  if (RegExp(r'\b(poly|polyethylene|well pipe)\b').hasMatch(text) &&
      RegExp(
        r'\b(insert|barb|barbed|coupling|cplg|adapter|adpt)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final wantsCoupling = RegExp(r'\b(coupling|cplg)\b').hasMatch(text);
    final wantsBarb = RegExp(r'\b(barb|barbed)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      final isWellFitting =
          name.contains('well pipe adapter') ||
          name.contains('well service fitting');
      if (!isWellFitting) continue;
      if (wantsBarb && !name.contains('well service fitting')) continue;
      if (wantsCoupling && !name.contains('coupling')) continue;
      if (size == null || name.contains(size)) return item;
    }
  }
  if (RegExp(r'\b(continuous waste|cont waste)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      if (item.trade == 'Plumbing' &&
          item.variant.toLowerCase().contains('continuous waste')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(toilet flange and seal part|toilet service stock|toilet seal)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet flange and seal part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\btoilet flange repair ring\b').hasMatch(receiptText) &&
      !RegExp(r'\bcloset\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet flange repair ring')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(cleanout|clean out|co)\b').hasMatch(text) &&
      RegExp(r'\b(plug|plugs|cover|covers)\b').hasMatch(text) &&
      !RegExp(r'\b(abs|black)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final wantsPlug = RegExp(r'\b(plug|plugs)\b').hasMatch(text);
    final wantsCover = RegExp(r'\b(cover|covers)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      final variant = item.variant.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cleanout access part') &&
          ((wantsPlug && variant.contains('cleanout plug')) ||
              (wantsCover && variant.contains('cleanout cover'))) &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black)\b').hasMatch(text) &&
      RegExp(r'\b(trap adapt|trap adapter|trap adpt)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('abs dwv trap adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(marvel|desanco)\b').hasMatch(text) &&
      RegExp(r'\b(adapter|adpt)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final wantsDesanco = RegExp(r'\bdesanco\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (wantsDesanco
              ? name.contains('desanco adapter')
              : name.contains('marvel adapter')) &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(ball valve|ball valves|shutoff|shut off)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc ball valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(gate valve|gate valves)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('gate valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\binside pipe cutter\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('inside pipe cutter') &&
          name.contains('plumbing hand tool')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(plumbing hand tool|pex crimp tool|tubing cutter|'
    r'pvc pipe cutter|pipe cutter|deburring tool|inside pipe cutter|'
    r'pex clamp tool|pex cinch tool|cinch clamp tool|pex expander|'
    r'pex expansion tool|expander head|press jaw|propress jaw|'
    r'basin wrench|strap wrench|closet auger|drain auger|drain snake|'
    r'hole saw|recip blade|reciprocating blade|sawzall blade|sawzall)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('plumbing hand tool') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(continuous waste|cont waste)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final searchable = item.searchableText.toLowerCase();
      if (item.trade == 'Plumbing' && searchable.contains('continuous waste')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(sink drain finish part|sink drain finish parts|'
    r'dw disposal drain part|dw drain hose|dw hose|disposal conn kit|'
    r'disposal elb gasket kit|tubular drain adpt|tubular drain adpts|'
    r'slip joint trap adpt|marvel adpt|desanco adpt|'
    r'slip joint trim part|slip joint trim hardware|'
    r'cleanout access part|cleanout covers and plugs|cleanout cover|'
    r'floor drain finish part|floor drain finish parts|floor drain grate|'
    r'snap-in strainer|screw-down strainer|sediment bucket|'
    r'trap primer adpt|trap primer adapter|toilet finish and flange repair|'
    r'closet flange repair hardware|closet flange repair part|'
    r'flange spacer|repair ring|repair plate|repair flange|'
    r'flange extension kit|closet bolt repair kit|toilet finish trim|'
    r'toilet finish trim part|toilet bolt caps|closet bolt caps|'
    r'hinge bolt caps|supply line escutcheon|tank lever trim nut)\b',
  ).hasMatch(text)) {
    if (RegExp(r'\btoilet flange repair\b').hasMatch(text) &&
        !RegExp(r'\bcloset\b').hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            name.contains('toilet flange repair ring')) {
          return item;
        }
      }
    }
    if (RegExp(r'\binside fit repair flange\b').hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            name.contains('inside fit repair flange') &&
            name.contains('closet flange repair part')) {
          return item;
        }
      }
    }
    final hasGeneratedToiletFinishContext = RegExp(
      r'\b(toilet finish and flange repair|closet flange repair part|'
      r'closet flange repair hardware|toilet finish trim|'
      r'toilet finish trim part)\b',
    ).hasMatch(text);
    if (hasGeneratedToiletFinishContext) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            (name.contains('closet flange repair part') ||
                name.contains('toilet finish trim part')) &&
            _receiptContainsVariantTokens(text, item.variant)) {
          return item;
        }
      }
    }
    if (RegExp(r'\b(toilet flange repair|toilet bolt caps)\b').hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            (name.contains('closet flange repair part') ||
                name.contains('toilet finish trim part')) &&
            _receiptStartsWithVariant(text, item.variant)) {
          return item;
        }
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('floor drain finish part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('dishwasher disposal drain part') ||
              name.contains('tubular drain adapter') ||
              name.contains('slip joint trim part') ||
              name.contains('cleanout access part')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet washer|seat washer|bib washer|'
    r'faucet washers and seats)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet washer and seat part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(toilet tank seal part|tank and flush seals|toilet gasket|'
    r'flush valve seal|tank bolt gasket|fill valve locknut|'
    r'flush valve locknut|fill valve shank washer|'
    r'toilet supply shank washer|dual flush seal)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet tank seal part') &&
          (_receiptContainsVariantTokens(text, item.variant) ||
              (text.contains('tank bolt gasket') &&
                  name.contains('tank bolt gasket')))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(closet seal part|closet seal detail|toilet and tank seals|'
    r'closet seal|rubber toilet seal|wax free seal)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('closet seal part') &&
          _receiptContainsVariantTokens(text, item.variant) &&
          !RegExp(r'\btoilet seal\b').hasMatch(text)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(hose bibb repair part|hose bibb repair seals|'
    r'hose bibb and vacuum breaker repair|hose bibb washer|hose washer|'
    r'sillcock stem packing|sillcock handle screw|sillcock packing nut|'
    r'frost free stem washer|vacuum breaker cap|vacuum breaker washer)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('hose bibb repair part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(supply stop repair part|stop repair parts|handle screw|stop handle|'
    r'oval handle|compression nut and ferrule|compression sleeve puller|'
    r'stop valve escutcheon|split escutcheon)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('supply stop repair part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(stop valve and supply repairs|quarter turn stops)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('quarter turn angle stop') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(stop valve and supply repairs|straight stops)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('quarter turn straight stop') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(br ang stop|comp stop)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('supply stop') ||
              name.contains('quarter turn angle stop')) &&
          (name.contains('angle') ||
              name.contains('compression') ||
              _nameMatchesReceiptMatrix(name, text))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(quarter turn angle stop|angle stop)\b').hasMatch(text) &&
      RegExp(
        r'\b(qt|quarter turn|od|compression|oval handle|lever handle)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          !name.contains('push-fit') &&
          (name.contains('quarter turn angle stop') ||
              name.contains('angle stop valve')) &&
          (_receiptMatchesVariant(text, item.variant) ||
              _receiptContainsVariantTokens(text, item.variant) ||
              _matchesHalfByThreeEighthStop(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(quarter turn straight stop|straight stop)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(fip|od|compression)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('quarter turn straight stop') &&
          (_receiptMatchesVariant(text, item.variant) ||
              _receiptContainsVariantTokens(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(straight stop|straight stops|straight stop valve)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('straight stop valve') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('straight stop valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(press reducing valve|pressure reducing valve|prv)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pressure reducing valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(vac brkr|vac breaker|vacuum breaker|backflow preventer)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('vacuum breaker') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater|wh)\b').hasMatch(text) &&
      RegExp(
        r'\b(element|elem|4500w|5500w|4500 watt|5500 watt)\b',
      ).hasMatch(text)) {
    final watt = text.contains('5500') ? '5500' : '4500';
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater repair part') &&
          name.contains('$watt watt') &&
          name.contains('element')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater|wh)\b').hasMatch(text) &&
      RegExp(r'\b(anode|magnesium|aluminum zinc)\b').hasMatch(text)) {
    final wantsAluminumZinc =
        text.contains('aluminum') || text.contains('zinc');
    final wants42 = RegExp(r'\b42\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' ||
          !name.contains('water heater repair part') ||
          !name.contains('anode rod')) {
        continue;
      }
      if (wantsAluminumZinc && name.contains('aluminum zinc')) return item;
      if (wants42 && name.contains('42 in magnesium')) return item;
      if (!wants42 && name.contains('24 in magnesium')) return item;
    }
  }
  if (RegExp(
    r'\b(upper thermostat|lower thermostat|wtr htr thermostat|'
    r'water heater thermostat|thermostat and element|tune[- ]up kit)\b',
  ).hasMatch(text)) {
    final wantsUpper = text.contains('upper');
    final wantsLower = text.contains('lower');
    final wantsTuneUp = text.contains('tune') || text.contains('element');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' ||
          !name.contains('water heater repair part')) {
        continue;
      }
      if (wantsTuneUp && name.contains('tune-up kit')) return item;
      if (wantsUpper && name.contains('upper thermostat')) return item;
      if (wantsLower && name.contains('lower thermostat')) return item;
      if (!wantsUpper && !wantsLower && name.contains('thermostat')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(t and p|t p|t&p|tpr|temperature and pressure|temp pressure|'
    r'valvula alivio|valvula t p|valvula t&p)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('temperature and pressure relief valve') ||
              (name.contains('water heater repair part') &&
                  name.contains('relief valve')))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater)\b').hasMatch(text) &&
      RegExp(r'\b(drain pan|heater pan)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('water heater drain pan') ||
              (name.contains('water heater install accessory') &&
                  name.contains('drain pan')))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater)\b').hasMatch(text) &&
      RegExp(
        r'\b(restraint strap|seismic strap|heater strap)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater restraint strap')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(earthquake strap|sediment trap|drip leg)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater install accessory')) {
        if (text.contains('earthquake') && name.contains('earthquake')) {
          return item;
        }
        if ((text.contains('sediment') || text.contains('drip leg')) &&
            name.contains('sediment')) {
          return item;
        }
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater|thermal)\b').hasMatch(text) &&
      RegExp(r'\b(exp tank|expansion tank)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('expansion tank')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater|boiler)\b').hasMatch(text) &&
      RegExp(r'\b(drain valve|heater drain|boiler drain)\b').hasMatch(text) &&
      !text.contains('pan')) {
    WorkSupplyItem? fallback;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          ((name.contains('water heater drain valve')) ||
              (name.contains('water heater repair part') &&
                  name.contains('drain valve')))) {
        if (item.packTier == WorkSupplyPackTier.core) return item;
        fallback ??= item;
      }
    }
    if (fallback != null) return fallback;
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater)\b').hasMatch(text) &&
      RegExp(
        r'\b(mixing valve|service fitting|wtr htr union)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater service fitting')) {
        if (text.contains('mixing') && name.contains('mixing')) return item;
        if (text.contains('union') && name.contains('union')) return item;
        if (text.contains('service fitting')) return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater)\b').hasMatch(text) &&
      RegExp(r'\b(vacuum relief|vac relief)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater install accessory') &&
          name.contains('vacuum relief') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('water heater service fitting') ||
              name.contains('water heater install accessory')) &&
          name.contains('vacuum relief')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(wtr htr|water heater|heater connector|heater supply|'
    r'corrugated stainless)\b',
  ).hasMatch(text)) {
    if (RegExp(
      r'\b(conn|connector|line|hose|water heater line|heater supply)\b',
    ).hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            name.contains('water heater connector')) {
          return item;
        }
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('water heater repair part') ||
              name.contains('water heater install accessory')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater connector') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet conn|faucet conns|faucet connector|faucet supply|'
    r'linea lavamanos|linea lavabo|linea suministro llave|conector grifo)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet supply line') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(toilet conn|toilet conns|toilet connector|toilet supply)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet supply line') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(gas appliance conn|gas appliance conns|gas connector)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('gas appliance connector') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(appliance conn|appliance conns|appliance supply|dw line|dishwasher line)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('appliance supply line') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv)\b').hasMatch(text) &&
      !RegExp(r'\b(abs|black)\b').hasMatch(text) &&
      RegExp(
        r'\b(trap adpt|trap adpts|trap adapter|trap adapters)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv trap adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  final hasServiceStockDrainContext = RegExp(
    r'\b(tubular drain part|tubular drain service stock|'
    r'trap and tailpiece detail|drain repair kits?|slip joint hardware|'
    r'dw branch|dishwasher branch)\b',
  ).hasMatch(text);
  if (hasServiceStockDrainContext &&
      RegExp(
        r'\b(tubular drain part|trap and tailpiece detail|drain repair kit|'
        r'slip joint hardware|p-trap|p trap|j-bend|j bend|wall tube|'
        r'flanged tailpiece|extension tube|slip joint elbow|continuous waste|'
        r'center outlet waste|end outlet waste|'
        r'basket strainer|pop-up drain|pop up drain|lavatory drain|'
        r'rubber washers|poly washers|beveled washers|slip nuts|'
        r'nut and washer kit)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('tubular drain part') ||
              name.contains('drain repair kit') ||
              name.contains('slip joint hardware')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pump and discharge service stock|sump pump discharge parts|'
    r'sump pump discharge part|pump controls and alarms|pump control part|'
    r'sump pump check valve|discharge hose kit|rubber coupling|'
    r'pvc adapter|barbed adapter|float switch|high water alarm|'
    r'condensate pump safety switch|battery backup sensor)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('sump pump discharge part') ||
              name.contains('pump control part')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(plumbing hand tool|pex crimp tool|tubing cutter|'
    r'pvc pipe cutter|pipe cutter|deburring tool|inside pipe cutter|'
    r'pex clamp tool|pex cinch tool|cinch clamp tool|pex expander|'
    r'pex expansion tool|expander head|press jaw|propress jaw|'
    r'basin wrench|strap wrench|closet auger|drain auger|drain snake|'
    r'hole saw|recip blade|reciprocating blade|sawzall blade|sawzall)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('plumbing hand tool') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(sink drain finish part|sink drain finish parts|'
    r'basket strainers and sink drains|dishwasher disposal drain part|'
    r'dw drain hose|dishwasher drain hose|dw hose|sink strainer)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('sink drain finish part') ||
              name.contains('dishwasher disposal drain part')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(p-trap|p trap|tubular p-trap|tubular p trap)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text) ?? _explicitTubularTrapSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular p-trap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(trampa lavamanos|trampa lavabo|trampa sanitaria|trampa p)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular p-trap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(tubular drain traps|drain traps)\b').hasMatch(text) &&
      !RegExp(r'\b(adpt|adapter)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular p-trap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(slip joint nut|slip joint nuts|nut and washer|nuts and washers)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('slip joint nut and washer') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(disposal drain elb|disposal drain elbow|disposal drain parts)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('disposal drain elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(dishwasher branch tailpiece|dishwasher branch)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('dishwasher branch') &&
          name.contains('tailpiece')) {
        return item;
      }
    }
  }
  final hasToiletServiceContext = RegExp(
    r'\b(toilet service stock|toilet tank repair part|'
    r'toilet tank parts detail|toilet flange and seal detail|'
    r'toilet flange and seal part)\b',
  ).hasMatch(text);
  final hasGeneratedToiletServiceAlias = RegExp(
    r'\b(toilet flapper|toilet seal toilet seal|'
    r'wax ring.*toilet seal|flange spacer.*toilet seal|'
    r'flange repair ring.*toilet seal)\b',
  ).hasMatch(text);
  if (RegExp(
    r'\b(tank bolt gasket|fill valve shank washer|flush valve locknut|'
    r'fill valve locknut|toilet supply shank washer)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet tank seal part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tank to bowl bolts|toilet tank bolt kit|tank bolt kit)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('toilet tank bolt kit')) {
        return item;
      }
    }
  }
  if (hasToiletServiceContext || hasGeneratedToiletServiceAlias) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('toilet tank repair part') ||
              name.contains('toilet flange and seal part')) &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(toilet seal|wax ring|closet seal)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' || !name.contains('toilet wax ring')) {
        continue;
      }
      if (_receiptMatchesVariant(text, item.variant) ||
          (text.contains('wax free') && name.contains('wax free')) ||
          (text.contains('with horn') && name.contains('with horn')) ||
          (text.contains('extra thick') && name.contains('extra thick')) ||
          (text.contains('standard') && name.contains('standard'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(toilet handle|tank lever|flush lever)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet tank lever') &&
          _receiptMatchesVariant(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(toilet flange spacer|closet flange spacer|flange spacer)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet flange spacer') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(toilet flange|closet flange)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name == '$size in toilet flange') {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(fixture and faucet service stock|faucet repair assortments?|'
    r'faucet repair assortment|seat washer assortment|o-ring assortment|'
    r'cartridge clip assortment|ceramic cartridge|single handle cartridge|'
    r'bonnet nut assortment)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet repair assortment') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet cartridge|faucet cart|fct cart|cartridge|cartridges)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' || !name.contains('faucet cartridge')) {
        continue;
      }
      if (_receiptMatchesVariant(text, item.variant) ||
          (text.contains('single handle') && name.contains('single handle')) ||
          (text.contains('hot stem') && name.contains('hot stem')) ||
          (text.contains('cold stem') && name.contains('cold stem'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet stem|stem repair|stem hot repair|hot stem repair|'
    r'cold stem repair|valve stem|stem assembly)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' || !name.contains('faucet stem')) {
        continue;
      }
      if (_receiptMatchesVariant(text, item.variant) ||
          (text.contains('hot') && name.contains('hot')) ||
          (text.contains('cold') && name.contains('cold'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(o-ring and seat kit|o ring and seat kit|faucet repair kit|'
    r'faucet o ring|faucet o-ring|faucet seat washer|seat washer kit)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' ||
          !name.contains('faucet o-ring and seat kit')) {
        continue;
      }
      if (_receiptMatchesVariant(text, item.variant) ||
          (text.contains('assorted') && name.contains('assorted')) ||
          (text.contains('small') && name.contains('small')) ||
          (text.contains('large') && name.contains('large'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet and valve seals|o-rings and packing|o-ring|o ring|'
    r'stem packing)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet o-ring and packing part') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(fixture and faucet service stock|aerators and adapters|'
    r'faucet aerator and adapter|gpm)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet aerator and adapter') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(fixture and faucet service stock|faucet repair assortments?|'
    r'faucet repair assortment|seat washer assortment|o-ring assortment|'
    r'cartridge clip assortment|ceramic cartridge|single handle cartridge|'
    r'stem packing|bonnet nut assortment)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet repair assortment') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(aerator|aerators|faucet screen)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('faucet aerator') &&
          (_receiptMatchesVariant(text, item.variant) ||
              (text.contains('15/16') && name.contains('15/16')) ||
              (text.contains('55/64') && name.contains('55/64')) ||
              (text.contains('15/16-27') && name.contains('15/16-27')) ||
              (text.contains('55/64-27') && name.contains('55/64-27')))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(exp tank|expansion tank|thermal expansion)\b',
  ).hasMatch(text)) {
    final capacity = RegExp(r'\b(2|4\.5)\s+gal\b').firstMatch(text)?.group(1);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('expansion tank') &&
          (capacity == null || name.startsWith('$capacity gal '))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pipe strap|pipe straps)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe strap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(split ring hanger|split ring hangers|split ring)\b',
      ).hasMatch(text) &&
      !RegExp(r'\b(flange|repair|closet|toilet)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('split ring hanger') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(j hook|j-hook|j-hooks|pipe hook|pipe j-hook|pex j hook)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe j-hook') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(bell hanger|bell hangers|copper bell hanger)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('bell hanger') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(stud guard|stud guards|nail plate|stud guard plate)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('stud guard plate') &&
          (_receiptMatchesVariant(text, item.variant) ||
              _nameMatchesReceiptMatrix(name, text))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe insulation|foam pipe wrap|pipe wrap)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe insulation') &&
          _receiptMatchesVariant(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(thread sealing detail|thread sealant detail|thread sealant supply|'
    r'thread sealant|thread paste|ptfe paste|pipe dope|teflon tape|ptfe tape)\b',
  ).hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    final wantsPasteOrDope = RegExp(
      r'\b(pipe dope|thread paste|ptfe paste|paste|compound)\b',
    ).hasMatch(text);
    final wantsGasTape =
        RegExp(r'\b(gas|yellow)\b').hasMatch(text) &&
        RegExp(r'\b(ptfe|teflon)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('thread sealant supply') &&
          (_receiptContainsVariantTokens(text, item.variant) ||
              (amount != null &&
                  _itemMatchesPackageAmount(item, amount, 'oz')) ||
              (wantsPasteOrDope &&
                  (name.contains('pipe joint compound') ||
                      name.contains('ptfe paste') ||
                      name.contains('thread sealant'))) ||
              (wantsGasTape && name.contains('yellow gas ptfe tape')))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe joint compound|pipe dope|thread sealant)\b',
  ).hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe joint compound') &&
          _itemMatchesPackageAmount(item, amount, 'oz')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(plumber putty|plumbers putty)\b').hasMatch(text)) {
    final ozAmount = _receiptPackageAmount(text, 'oz');
    final lbAmount = _receiptPackageAmount(text, 'lb');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('plumber putty') &&
          (_itemMatchesPackageAmount(item, ozAmount, 'oz') ||
              _itemMatchesPackageAmount(item, lbAmount, 'lb'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(silicone sealant|silicone caulk|silicone)\b',
  ).hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    final wantsClear = RegExp(r'\bclear\b').hasMatch(text);
    final wantsWhite = RegExp(r'\bwhite\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' ||
          !name.contains('silicone sealant') ||
          !_itemMatchesPackageAmount(item, amount, 'oz')) {
        continue;
      }
      if ((wantsClear && name.contains('clear')) ||
          (wantsWhite && name.contains('white')) ||
          (!wantsClear && !wantsWhite)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(ptfe thread tape|thread tape|teflon tape)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('ptfe thread tape') &&
          (_receiptMatchesVariant(text, item.variant) ||
              _nameMatchesReceiptMatrix(name, text))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc primer|purple primer|primer)\b').hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc primer') &&
          _itemMatchesPackageAmount(item, amount, 'oz')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pipe hanger|pipe hangers)\b').hasMatch(text) &&
      !RegExp(r'\b(j hook|j-hook|pipe hook|pex j hook)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('split ring hanger') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(tailpiece|tailpieces)\b').hasMatch(text) &&
      !RegExp(r'\b(extension tube|extension tubes)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tailpiece') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _nameMatchesReceiptSize(name, size))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(extension tube|extension tubes)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular extension tube') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _nameMatchesReceiptSize(name, size))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(marvel adapter|marvel adpt|desanco|desanco adapter|desanco adpt)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final wantsDesanco = RegExp(r'\bdesanco\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (wantsDesanco
              ? name.contains('desanco adapter')
              : name.contains('marvel adapter')) &&
          (_nameMatchesReceiptSize(name, size) ||
              _receiptContainsVariantTokens(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(trap adpt|trap adpts|trap adapter|trap adapters)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          !RegExp(r'\b(abs|black)\b').hasMatch(text) &&
          name == '$size in trap adapter') {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(hose bib|hose bibb|hose bibbs|outside faucet|sill faucet)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('hose bibb') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(frost free|frost-free|sillcock|sill cock)\b',
      ).hasMatch(text) &&
      !RegExp(r'\bhose bib').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('frost-free sillcock') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('frost-free sillcock') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if ((RegExp(
            r'\b(threaded ball valve|threaded ball valves)\b',
          ).hasMatch(text) ||
          (RegExp(r'\b(fip|mip|ips|full port)\b').hasMatch(text) &&
              RegExp(r'\bball valve\b').hasMatch(text))) &&
      !RegExp(r'\bpvc\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('threaded ball valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(ball valve|ball valves)\b').hasMatch(text) &&
      RegExp(r'\b(shutoff|shut off|valve|valves)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('ball valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\bdwv\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing cplg|reducing cplgs|reducing coupling|reducer)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc dwv reducing coupling') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\bdwv\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\bdwv\b').hasMatch(text) &&
      RegExp(
        r'\b(trap adpt|trap adpts|trap adapter|trap adapters)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv trap adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black)\b').hasMatch(text) &&
      RegExp(
        r'\b(trap adpt|trap adpts|trap adapter|trap adapters)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('abs dwv trap adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\bdwv\b').hasMatch(text) &&
      RegExp(r'\b(test tee|test tees)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv test tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\bdwv\b').hasMatch(text) &&
      RegExp(r'\b(cleanout|clean out)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv cleanout') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(90|ell|elb|elbow|90d)\b').hasMatch(text) &&
      RegExp(r'\b(crimp|brass)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(text)?.group(0);
    final targetPrefix = size == null ? '' : '$size in ';
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name == '${targetPrefix}pex 90 elbow') {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tune up kit|tune-up kit|element thermostat kit|thermostat and element)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('tune-up kit') || name.contains('tune up kit'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(wtr htr|water heater|wh)\b').hasMatch(text) &&
      RegExp(r'\b(element|elem|4500w|5500w)\b').hasMatch(text)) {
    final watt = text.contains('5500') ? '5500' : '4500';
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('$watt watt') &&
          name.contains('element')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(exp tank|expansion tank|thermal expansion)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('expansion tank')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(water heater pan|heater pan|wtr htr pan|drain pan)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('drain pan')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(earthquake strap|seismic strap|water htr strap|wtr htr strap|heater strap|restraint strap)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater restraint strap')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(sediment trap|drip leg)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('sediment trap')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(water htr|wtr htr|water heater)\b').hasMatch(text) &&
      RegExp(
        r'\b(flex connector|connector|supply connector|water heater line|'
        r'heater supply)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('water heater') &&
          name.contains('connector')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(dielectric nipple|water heater nipple)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('dielectric') &&
          name.contains('nipple')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(boiler drain|heater drain valve)\b').hasMatch(text) &&
      !RegExp(r'\bpan\b').hasMatch(text)) {
    WorkSupplyItem? fallback;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('drain valve')) {
        if (item.packTier == WorkSupplyPackTier.core) return item;
        fallback ??= item;
      }
    }
    if (fallback != null) return fallback;
  }
  if (RegExp(
    r'\b(press reducing valve|pressure reducing valve|prv)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pressure reducing valve')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(backwater valve|sewer check valve|drain backflow)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('backwater valve')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b((well|pozo)\b.*\b(check valve|chk valve|one way valve)|(valvula check pozo|check bomba))\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('well pump check valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      !RegExp(r'\b(cpvc|primer|trap\s+primer|paint)\b').hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc cement') &&
          (amount == null || _itemMatchesPackageAmount(item, amount, 'oz'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(sump|pump)\b.*\b(check valve|chk valve|one way valve)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pump check valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(check valve|chk valve|one way valve)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('check valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|slip)\b').hasMatch(text) &&
      RegExp(r'\bball valve\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pvc ball valve')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(fip|mip|ips|threaded)\b').hasMatch(text) &&
      RegExp(r'\bball valve\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('threaded ball valve')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bgate valve\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('gate valve')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(ptfe|teflon|thread tape)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('ptfe thread tape')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bthread sealant\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('thread sealant')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe joint compound|thread paste|pipe dope)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('pipe joint compound') ||
              name.contains('thread sealant'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(purple primer|pvc primer|pipe primer)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pvc primer')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(plumber putty|sink putty|putty)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('plumber putty')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(silicone caulk|silicone sealant|kitchen bath silicone)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('silicone sealant')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(stem packing|valve packing|bonnet packing)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('stem packing')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(faucet stem|valve stem|stem assembly|hot stem|cold stem|diverter stem)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('faucet stem')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(showerhead|shower head)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('shower head')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(frost free|frost-free|anti siphon|sillcock)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('frost-free sillcock')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black drain)\b').hasMatch(receiptText) &&
      RegExp(r'\b(san tee|sanitary tee|sanitary t)\b').hasMatch(receiptText)) {
    final size = _nominalReceiptSize(receiptText);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('abs dwv sanitary tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black drain)\b').hasMatch(receiptText) &&
      RegExp(r'\b(cleanout|clean out|co plug)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('abs dwv cleanout')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(black iron|black pipe)\b').hasMatch(receiptText) &&
      RegExp(r'\b(tee|threaded tee)\b').hasMatch(receiptText)) {
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2)\b',
    ).firstMatch(receiptText)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('black iron tee') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(black iron|black pipe)\b').hasMatch(receiptText) &&
      RegExp(r'\b(union|threaded union)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('black iron union')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(black iron|black pipe)\b').hasMatch(receiptText) &&
      RegExp(r'\b(bushing|reducing bushing)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('black iron reducer bushing')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(compression sleeve puller|sleeve puller|ferrule puller)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('sleeve puller')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(upper thermostat|lower thermostat|wtr htr thermostat|water heater thermostat)\b',
  ).hasMatch(text)) {
    final wantsUpper = text.contains('upper');
    final wantsLower = text.contains('lower');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing' || !name.contains('thermostat')) continue;
      if (wantsUpper && name.contains('upper thermostat')) return item;
      if (wantsLower && name.contains('lower thermostat')) return item;
      if (!wantsUpper && !wantsLower) return item;
    }
  }
  if (RegExp(
    r'\b(ferrule|compression nut|comp nut|compression sleeve)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('ferrule')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(stop handle|oval handle|lever handle|handle screw)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('oval handle') ||
              name.contains('lever handle') ||
              name.contains('handle screw'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe lube|gasket lubricant|joint lubricant|lubricant)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('lubricant')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tank to bowl bolt|tank bolt|tank bolts|tank to bowl bolt gasket)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('tank bolt')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tank to bowl gasket|tank gasket|tank bolt gasket)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tank') &&
          (name.contains('gasket') || name.contains('seal'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(fill valve shank washer|toilet supply shank washer)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('washer') &&
          name.contains('toilet')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(hose bibb washer|hose bib washer|hose washer|vacuum breaker washer)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('hose') &&
          name.contains('washer')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(strut nut|unistrut nut|rod coupling nut|coupling nut)\b',
  ).hasMatch(receiptText)) {
    final wantsStrut = RegExp(r'\b(strut|unistrut)\b').hasMatch(receiptText);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsStrut && name.contains('strut nut')) {
        return item;
      }
      if (!wantsStrut && name.contains('coupling nut')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bhex nut\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('hex nut')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bfender washer\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('fender washer')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tapcon|masonry screw|blue screw|concrete anchor screw)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('concrete screw')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(soft copper|copper roll|refrigeration copper)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('soft copper tubing')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(receiptText) &&
      RegExp(r'\b(pipe|stick|10 ft|20 ft|10ft|20ft)\b').hasMatch(receiptText) &&
      !RegExp(
        r'\b(elbow|ell|tee|adapter|coupling|fitting|strap|hanger)\b',
      ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('copper pipe')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(receiptText) &&
      RegExp(
        r'\b(tubing|pipe|roll|100 ft|100ft|300 ft|300ft)\b',
      ).hasMatch(receiptText) &&
      !RegExp(
        r'\b(elbow|ell|tee|adapter|coupling|fitting|stop|hook|j hook|j-hook|hanger|strap)\b',
      ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex tubing') &&
          _receiptContainsVariantTokens(receiptText, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black drain)\b').hasMatch(receiptText) &&
      RegExp(r'\b(pipe|stick|10 ft|10ft|20 ft|20ft)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('abs dwv pipe') &&
          _receiptContainsVariantTokens(receiptText, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(wedge anchor|drop in anchor|beam clamp|ceiling flange)\b',
  ).hasMatch(receiptText)) {
    final wantsWedge = RegExp(r'\bwedge anchor\b').hasMatch(receiptText);
    final wantsDropIn = RegExp(r'\bdrop in anchor\b').hasMatch(receiptText);
    final wantsBeam = RegExp(r'\bbeam clamp\b').hasMatch(receiptText);
    final wantsFlange = RegExp(r'\bceiling flange\b').hasMatch(receiptText);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsWedge && name.contains('wedge anchor')) {
        return item;
      }
      if (wantsDropIn && name.contains('drop-in anchor')) {
        return item;
      }
      if (wantsBeam && name.contains('beam clamp')) {
        return item;
      }
      if (wantsFlange && name.contains('ceiling flange')) {
        return item;
      }
    }
  }
  if (RegExp(r'\briser clamp\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('riser clamp')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(j hook|j-hook|pex j hook|pipe hook|pipe hanger)\b',
  ).hasMatch(receiptText)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(receiptText)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe j-hook') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(pipe insulation|foam pipe wrap|pipe sleeve)\b',
      ).hasMatch(receiptText) ||
      RegExp(
        r'\b(pipe insulation|foam pipe wrap|pipe sleeve)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pipe insulation')) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(stud guard|nail plate|stud plate|protection plate)\b',
      ).hasMatch(receiptText) ||
      RegExp(
        r'\b(stud guard|nail plate|stud plate|protection plate)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('stud guard')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(split ring|pipe hanger)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('split ring')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(bell hanger|copper bell hanger)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('bell hanger')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bdishwasher\b').hasMatch(receiptText) &&
      RegExp(r'\b(drain hose|hose)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('dishwasher') &&
          name.contains('hose')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(continuous waste|cont waste)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      final searchable = item.searchableText.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('continuous waste') ||
              item.variant.toLowerCase().contains('continuous waste') ||
              searchable.contains('continuous waste'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(dishwasher branch|branch tailpiece|dishwasher branch tailpiece)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('dishwasher') &&
          name.contains('tailpiece')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(air gap|dishwasher air gap)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('air gap')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(disposal elbow gasket|disposal gasket|garbage disposal gasket)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('disposal') &&
          name.contains('gasket')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(trap washer|beveled washer|reducing washer|slip washer|nut and washer)\b',
  ).hasMatch(receiptText)) {
    final wantsNut = RegExp(r'\bnut\b').hasMatch(receiptText);
    final wantsReducing = RegExp(r'\breducing\b').hasMatch(receiptText);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsNut && name.contains('nut') && name.contains('washer')) {
        return item;
      }
      if (wantsReducing &&
          name.contains('reducing') &&
          name.contains('washer')) {
        return item;
      }
      if (!wantsNut && !wantsReducing && name.contains('washer')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(escutcheon|esc plate|cover plate)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('escutcheon') || name.contains('cover plate'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(escutcheon|cover plate)\b').hasMatch(receiptText)) {
    final wantsSupply = RegExp(
      r'\b(stop valve|supply line|supply|split)\b',
    ).hasMatch(receiptText);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsSupply &&
          (name.contains('escutcheon') || name.contains('cover plate'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(receiptText) &&
      RegExp(
        r'\b(spigot bushing|reducing bushing|bushing)\b',
      ).hasMatch(receiptText)) {
    final hasMatrix = _receiptSizeMatrix(receiptText) != null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc schedule 40 reducer bushing') &&
          (_nameMatchesReceiptMatrix(name, receiptText) ||
              _receiptMatchesVariant(receiptText, item.variant))) {
        return item;
      }
    }
    if (hasMatrix) return null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 reducer bushing')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(vac brkr|vac breaker|vacuum breaker|backflow preventer)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('vacuum breaker')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(hose bibb|hose bib|spigot|outside faucet)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('hose bibb')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(cleanout|clean out|co)\b').hasMatch(text) &&
      RegExp(r'\b(cover|plate|access cover)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cleanout') &&
          name.contains('cover')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe strap|strap|two hole|2 hole|one hole|1 hole)\b',
  ).hasMatch(text)) {
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/2|2)\b',
    ).firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe strap') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(tub spout|spout)\b').hasMatch(text) &&
      RegExp(r'\b(tub|diverter)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('tub spout')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(disposal|garbage disposal)\b').hasMatch(text) &&
      RegExp(r'\b(splash guard|splash|guard)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('splash guard')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(ice maker|icemaker|refrigerator water line|fridge water line)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('ice maker supply line')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(toilet conn|toilet connector|toilet supply|closet line)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('toilet') &&
          name.contains('supply line')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(washing machine hose|washer hose|washer supply hose|laundry hose)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('washing machine hose')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bdishwasher\b').hasMatch(text) &&
      RegExp(r'\b(line|supply line|connector)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('appliance supply line')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(gas flex|gas connector|gas appliance connector|appliance connector)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('gas appliance connector')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(condensate removal pump|condensate pump)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('condensate pump')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(sump pump|submersible sump)\b').hasMatch(text) &&
      !RegExp(
        r'\b(check|discharge hose|hose kit|float switch)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('sump pump')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pump check|sump pump check|sump check)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pump check valve')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(discharge hose|sump pump hose)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('discharge hose')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(sump pump|submersible sump)\b').hasMatch(text) &&
      RegExp(r'\b(barb|barbed)\b').hasMatch(text) &&
      RegExp(r'\b(adapter|adpt)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('sump pump discharge part') &&
          item.variant.toLowerCase().contains('barbed adapter') &&
          _receiptContainsVariantTokens(text, item.variant)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(float switch|sump float|pump switch)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('float switch')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(tee|t)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pex tee') && _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex tee') &&
          (size == null || name.contains(size))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    if (RegExp(r'\b(transition|trans)\b').hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            name.contains('pex transition coupling') &&
            _nameMatchesReceiptSize(name, size)) {
          return item;
        }
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(
        r'\b(drop ear|drop-ear|shower elbow|stub out elbow)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex drop-ear elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bbrass\b').hasMatch(text) &&
      !RegExp(r'\b(comp|compression)\b').hasMatch(text) &&
      RegExp(r'\b(union|unions|mip\s+x\s+fip|mip\s+fip)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass union') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bbrass\b').hasMatch(text) &&
      RegExp(
        r'\b(compression adpt|compression adpts|compression adapter|compression adapters)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass compression adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(brass|brs)\b').hasMatch(text) &&
      RegExp(r'\b(compression union|compression unions)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass compression union') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bbrass\b').hasMatch(text) &&
      RegExp(
        r'\b(bushing|bushings|reducing bushing|reducer)\b',
      ).hasMatch(text)) {
    final hasMatrix = _receiptSizeMatrix(text) != null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('brass bushing') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
    if (hasMatrix) return null;
  }
  if (RegExp(r'\b(brass|brs)\b').hasMatch(text) &&
      RegExp(
        r'\b(comp\s+un|comp\s+union|compression\s+union)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass compression union') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bbrass\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts|adpt|adpts)\b',
      ).hasMatch(text) &&
      !RegExp(
        r'\b(compression|fip|female|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bbrass\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(r'\b(tee|tees|t)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit tee') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('push-fit tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(
        r'\b(slip repair|repair cplg|repair cplgs|repair coupling|repair couplings|slip coupling|slip cplg|slip cplgs)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit slip coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing cplg|reducing cplgs|reducing coupling|reducing couplings|reducer)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('push-fit reducing coupling') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit coupling') &&
          !name.contains('slip') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(r'\b(ball valve|shutoff valve|shut off valve)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('push-fit ball valve') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(straight stop|straight valve)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('straight stop')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(push|push fit|push-fit|sharkbite)\b').hasMatch(text) &&
      RegExp(r'\b(angle stop|supply stop|shutoff)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('push-fit supply stop')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b(drop ear|drop-ear)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper drop-ear') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(
        r'\b(dielectric union|dielectric unions|water heater union|wtr htr union)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper dielectric union') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b45\b').hasMatch(text) &&
      !RegExp(r'\b(street)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper 45 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b(90|90d|ell|elb|elbs|elbow)\b').hasMatch(text) &&
      !RegExp(r'\b(drop ear|drop-ear|street|45)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper 90 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b(tee|tees| t )\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('copper tee') &&
          _receiptMatchesVariant(text, item.variant)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(
        r'\b(no stop|repair coupling|repair cplg|repair cplgs|slip coupling|slip cplg)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper repair coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing cplg|reducing cplgs|reducing coupling|reducing couplings|reducer coupling)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper reducing coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(wtr htr union|water heater union)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('dielectric union') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b(reducer|reducing reducer)\b').hasMatch(text) &&
      !RegExp(r'\b(cplg|coupling)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper reducer') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcopper\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('copper coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(brass|brs)\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('brass coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(r'\b(transition|trans)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc transition adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(r'\b(tee|t)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('cpvc tee') && _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc tee') &&
          (size == null || name.contains(size))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(r'\b(transition|copper adapter)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('cpvc transition adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bcpvc\b').hasMatch(text) &&
      RegExp(r'\b(bushing|reducing bushing)\b').hasMatch(text)) {
    final hasMatrix = _receiptSizeMatrix(text) != null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('cpvc reducer bushing') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
    if (hasMatrix) return null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('cpvc reducer bushing')) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      !RegExp(r'\b(cpvc|primer|trap\s+primer|paint)\b').hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc cement') &&
          (amount == null || _itemMatchesPackageAmount(item, amount, 'oz'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black)\b').hasMatch(text) &&
      !RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      RegExp(r'\bstreet\b').hasMatch(text) &&
      RegExp(r'\b90\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 street 90 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black)\b').hasMatch(text) &&
      !RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      RegExp(r'\b45\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 45 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black|street|45)\b').hasMatch(text) &&
      !RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      RegExp(r'\b(90|90d|ell|elb|elbow)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 90 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black)\b').hasMatch(text) &&
      RegExp(
        r'\b(mip|male adapter|male adapters|m adapter|m adapters|m adpt|m adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 male adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black)\b').hasMatch(text) &&
      RegExp(
        r'\b(fip|female adapter|female adapters|f adapter|f adapters|f adpt|f adpts)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 female adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(
        r'\b(dwv|drain|abs|black|cleanout|clean out|test tee|test\s+t|cement|solvent\s+cement|glue)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(tee|tees|t)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc schedule 40 tee') &&
          _receiptMatchesVariant(text, item.variant)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|drain|abs|black)\b').hasMatch(text) &&
      !RegExp(r'\b(bushing|bushings|bush)\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing cplg|reducing cplgs|reducing coupling|reducing couplings|reducer coupling|reducer cplg|reducer)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc schedule 40 reducing coupling') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(
        r'\b(dwv|drain|abs|black|reducing|reducer|cond|condensate|conduit|elec|electrical)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(cplg|cplgs|coupling|coupler)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(sch40|schedule 40)\b').hasMatch(text) &&
      RegExp(r'\b(tee|t)\b').hasMatch(text)) {
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2)\b',
    ).firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 tee') &&
          (size == null || name.contains(size))) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(
        r'\b(slip x fip|sxf|fip adapter|female adapter)\b',
      ).hasMatch(text)) {
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2)\b',
    ).firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 female adapter') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv)\b').hasMatch(text) &&
      RegExp(r'\b(cplg|coupling|coupler)\b').hasMatch(text) &&
      RegExp(r'\b(dwv|drain)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv coupling') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(reducing bushing|bushing)\b').hasMatch(text)) {
    final hasMatrix = _receiptSizeMatrix(text) != null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc schedule 40 reducer bushing') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
    if (hasMatrix) return null;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 reducer bushing')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv)\b').hasMatch(text) &&
      RegExp(
        r'\b(test\s+tee|test\s+t|cleanout\s+tee|clean\s*out\s+tee)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv test tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pvc dwv test tee')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv)\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing san tee|reducing sanitary|reducing sanitary tee)\b',
      ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('pvc dwv reducing sanitary tee') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv|drain)\b').hasMatch(text) &&
      RegExp(
        r'\b(san tee|sanitary tee|sanitary tees|sanitary t)\b',
      ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv sanitary tee') &&
          _nameMatchesReceiptMatrix(name, text)) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv sanitary tee') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(abs|black)\b').hasMatch(text) &&
      RegExp(r'\b(wye|y fitting|why fitting)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1-1/2|2|3|4)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('abs dwv wye') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pvc|dwv)\b').hasMatch(text) &&
      !RegExp(r'\b(abs|black)\b').hasMatch(text) &&
      RegExp(r'\b(wye|y fitting|why fitting)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc dwv wye') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(j hook|j-hook|pex j hook|pipe hook|pipe hanger)\b',
  ).hasMatch(receiptText)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(receiptText)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe j-hook') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(pipe strap|strap|two hole|2 hole|one hole|1 hole)\b',
  ).hasMatch(receiptText)) {
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/2|2)\b',
    ).firstMatch(receiptText)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe strap') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(cpvc|pvc|pex)\b').hasMatch(text) &&
      RegExp(r'\b(pipe|stick|10 ft|20 ft|10ft|20ft)\b').hasMatch(text) &&
      !RegExp(r'\b(hook|j hook|j-hook|hanger|strap)\b').hasMatch(text) &&
      !RegExp(
        r'\b(cutter|cutters|cutting|crimp tool|deburr|deburring|tool)\b',
      ).hasMatch(text) &&
      !RegExp(r'\b(corr|corrugated|flex drain|yard drain)\b').hasMatch(text)) {
    final material = text.contains('cpvc')
        ? 'cpvc pipe'
        : text.contains('pex')
        ? 'pex tubing'
        : text.contains('dwv')
        ? 'pvc dwv pipe'
        : 'pvc schedule 40 pipe';
    final size = RegExp(
      r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2|3|4)\b',
    ).firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains(material) &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(corr|corrugated|flex drain|yard drain)\b').hasMatch(text) &&
      RegExp(r'\b(drain|pipe)\b').hasMatch(text)) {
    final dimension = RegExp(
      r'\b(\d)\s*in\s*x\s*(\d+)\s*ft\b',
    ).firstMatch(text);
    final exact = dimension == null
        ? ''
        : '${dimension.group(1)} in x ${dimension.group(2)} ft';
    final size = RegExp(r'\b(?:3|4|6)\s*in\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('corrugated drain pipe') &&
          (exact.isEmpty || name.contains(exact)) &&
          (size == null || name.contains(size))) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(fernco|rubber coupling|flexible coupling|flex drain coupling)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(cplg|coupling|red|reducer|reducing)\b').hasMatch(text)) {
    final sizeMatrix = _receiptSizeMatrix(text);
    final size = sizeMatrix ?? _nominalReceiptSize(text);
    final wantsReducing =
        sizeMatrix != null ||
        RegExp(r'\b(red|reducer|reducing)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (!name.contains('flexible drain repair coupling')) continue;
      if (wantsReducing && !name.contains('reducing')) continue;
      if (!wantsReducing && name.contains('reducing')) continue;
      if (size == null || name.contains(size)) return item;
    }
  }
  if (RegExp(r'\b(bi|black iron|blk iron)\b').hasMatch(text) &&
      RegExp(r'\b(nip|nipple)\b').hasMatch(text)) {
    final diameter = RegExp(
      r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2)\b',
    ).firstMatch(text)?.group(0);
    final length =
        RegExp(r'\bx\s*(\d+)(?:\s*in)?\b').firstMatch(text)?.group(1) ??
        RegExp(r'\b(\d+)\s*in\b').firstMatch(text)?.group(1);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('black iron nipple') &&
          (diameter == null || name.startsWith('$diameter x')) &&
          (length == null || name.contains('x $length in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(no hub|no-hub|nh)\b').hasMatch(text) &&
      RegExp(r'\b(cplg|coupling|shielded)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1-1/2|2|3|4|6)\b').firstMatch(text)?.group(0);
    final wantsReducing = RegExp(r'\b(reducer|reducing)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsReducing &&
          name.contains('reducing no-hub coupling') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
      if (!wantsReducing &&
          name.contains('no-hub') &&
          name.contains('coupling') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(tailpc|tailpiece|ext tube|extension tube)\b',
  ).hasMatch(text)) {
    final hasTailpieceLength = RegExp(r'\bx\s*\d+\b').hasMatch(receiptText);
    final wantsExtension =
        RegExp(
          r'\b(ext tube|extension tube|tailpiece extension)\b',
        ).hasMatch(receiptText) &&
        !hasTailpieceLength;
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsExtension && name.contains('extension tube')) {
        return item;
      }
      if (!wantsExtension && name.contains('tailpiece')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(disposal drain elbow|disposal elbow)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('disposal drain elbow')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(condensate tubing|vinyl tubing)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('condensate pump tubing')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(wall tube|wall bend)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('wall tube')) {
        return item;
      }
    }
  }
  if (receiptText.contains('p trap') ||
      receiptText.contains('p-trap') ||
      receiptText.contains('trampa lavamanos') ||
      receiptText.contains('trampa lavabo') ||
      receiptText.contains('trampa p')) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      final variant = item.variant.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('p-trap') ||
              name.contains('p trap') ||
              variant.contains('p-trap') ||
              variant.contains('p trap'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(j bend|j-bend)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('j-bend')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(continuous waste|cont waste)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      final searchable = item.searchableText.toLowerCase();
      if (item.trade == 'Plumbing' &&
          (name.contains('continuous waste') ||
              item.variant.toLowerCase().contains('continuous waste') ||
              searchable.contains('continuous waste'))) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(disposal install kit|disposal kit|garbage disposal connector)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('disposal install kit')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(lav pop up|lav pop-up|pop up drain|pop-up drain)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pop-up')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(lav drain|lavatory drain)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('lavatory drain')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(trap primer|primer adapter)\b').hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('trap primer')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(trap adapter|marvel adapter|desanco adapter|compression trap adapter)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    final wantsAbs = RegExp(r'\b(abs|black)\b').hasMatch(text);
    final wantsPvc = RegExp(r'\b(pvc|dwv)\b').hasMatch(text) && !wantsAbs;
    final wantsTubular = RegExp(
      r'\b(tubular|marvel|desanco|compression trap)\b',
    ).hasMatch(text);
    final preferredStyle = text.contains('marvel')
        ? 'marvel adapter'
        : text.contains('desanco')
        ? 'desanco adapter'
        : text.contains('compression trap')
        ? 'compression trap adapter'
        : text.contains('wall bend')
        ? 'wall bend'
        : text.contains('trap arm')
        ? 'trap arm'
        : null;
    if (wantsTubular) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade != 'Plumbing') continue;
        if (preferredStyle != null &&
            name.contains(preferredStyle) &&
            name.contains('tubular drain adapter') &&
            _nameMatchesReceiptSize(name, size)) {
          return item;
        }
        if (preferredStyle == null &&
            name.contains('tubular drain adapter') &&
            _nameMatchesReceiptSize(name, size)) {
          return item;
        }
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsTubular &&
          preferredStyle != null &&
          name.contains(preferredStyle) &&
          name.contains('tubular drain adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
      if (wantsTubular &&
          preferredStyle == null &&
          name.contains('tubular drain adapter') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
      if (wantsAbs &&
          name.contains('abs dwv') &&
          name.contains('trap adapter')) {
        return item;
      }
      if (wantsPvc &&
          name.contains('pvc dwv') &&
          name.contains('trap adapter')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(toilet seat bolt|seat bolt|seat bolts)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('toilet seat bolt')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(flange repair|repair ring|closet flange repair|toilet flange repair)\b',
  ).hasMatch(text)) {
    if (RegExp(r'\bcloset\b').hasMatch(text)) {
      for (final item in _activeWorkSupplyCatalogItems) {
        final name = item.name.toLowerCase();
        if (item.trade == 'Plumbing' &&
            name.contains('closet flange repair part') &&
            _receiptContainsVariantTokens(text, item.variant)) {
          return item;
        }
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('flange repair')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(closet flange|toilet flange|clst flange|flg)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('closet flange')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(closet bolt cap|closet bolt caps|toilet bolt cap|toilet bolt caps)\b',
  ).hasMatch(receiptText)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('closet bolt caps')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(closet bolt|closet bolts|toilet bolt|toilet bolts)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('closet bolt')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(j hook|j-hook|pipe hanger|pex j hook)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:1/2|3/4|1)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pipe j-hook') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pex crimp tool|crimp tool)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex crimp tool') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(tubing cutter|mini tubing cutter)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('mini tubing cutter')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(pipe cutter|pvc cutter|ratchet cutter)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('pvc pipe cutter')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(deburring tool|deburr tool|pvc deburring)\b',
  ).hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('deburring tool')) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(strut nut|spring nut|unistrut nut|cone nut)\b',
  ).hasMatch(text)) {
    final size = RegExp(r'\b(?:1/4|3/8|1/2)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('strut nut') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(beam clamp|rod beam clamp)\b').hasMatch(text)) {
    final size = RegExp(r'\b(?:3/8|1/2)\b').firstMatch(text)?.group(0);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('beam clamp') &&
          (size == null || name.startsWith('$size in'))) {
        return item;
      }
    }
  }
  return null;
}

WorkSupplyItem? _directFastReceiptMatch(String text, {String? tradeScope}) {
  if (tradeScope != null &&
      tradeScope.trim().isNotEmpty &&
      tradeScope.trim().toLowerCase() != 'plumbing') {
    return null;
  }
  if (_hasStrongDirectPlumbingEvidence(text)) {
    final plumbingDirect = _directPlumbingFastMatch(text);
    if (plumbingDirect != null) return plumbingDirect;
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text) &&
      !RegExp(r'\b(cpvc|primer|trap\s+primer|paint)\b').hasMatch(text)) {
    final amount = _receiptPackageAmount(text, 'oz');
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc cement') &&
          (amount == null || _itemMatchesPackageAmount(item, amount, 'oz'))) {
        return item;
      }
    }
  }
  if (RegExp(
        r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2|3|4)(?:\s+in)?\s+pvc\b',
      ).hasMatch(text) &&
      RegExp(r'\b(90|ell|el|elb|elbow)\b').hasMatch(text) &&
      !RegExp(r'\b(dwv|abs|cpvc)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 elbow') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  final legacyAdapter = _directPlumbingLegacyAdapterFastMatch(text);
  if (legacyAdapter != null) return legacyAdapter;
  final wantsTubularPTrap = RegExp(
    r'\b(p trap|p-trap|lav p trap|trampa lavamanos|trampa lavabo)\b',
  ).hasMatch(text);
  if (wantsTubularPTrap) {
    final size = _nominalReceiptSize(text) ?? _explicitTubularTrapSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('tubular p-trap') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  final wantsTubularTailpiece = RegExp(
    r'\b(tailpiece|tail piece|flanged tailpiece|flange tail piece)\b',
  ).hasMatch(text);
  if (wantsTubularTailpiece) {
    final size = _nominalReceiptSize(text);
    final wantsFlanged = RegExp(r'\b(flanged|flange)\b').hasMatch(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (wantsFlanged &&
          name.contains('flanged tailpiece') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
      if (!wantsFlanged &&
          name.contains('tailpiece') &&
          !name.contains('flanged') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(extension tube|ext tube)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('extension tube') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(
    r'\b(slip joint nut|sj nut|nut washer|nut and washer)\b',
  ).hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('slip joint nut and washer') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(beveled washer|slip washer)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('beveled washers') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(basket strainer|sink strainer)\b').hasMatch(text)) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' && name.contains('basket strainer')) {
        return item;
      }
    }
  }
  if (RegExp(r'\b(j bend|j-bend)\b').hasMatch(text)) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('j-bend') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  final pexServiceFitting = _directPlumbingPexServiceFittingMatch(text);
  if (pexServiceFitting != null) return pexServiceFitting;
  final wantsPvcSch40ReducingCoupling =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(sch40|sch 40|schedule 40)\b').hasMatch(text) &&
      RegExp(
        r'\b(reducing cplg|reducing coupling|reducer coupling)\b',
      ).hasMatch(text);
  if (wantsPvcSch40ReducingCoupling) {
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 reducing coupling') &&
          (_nameMatchesReceiptMatrix(name, text) ||
              _receiptMatchesVariant(text, item.variant))) {
        return item;
      }
    }
  }
  final wantsPvcSch40Coupling =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(sch40|sch 40|schedule 40)\b').hasMatch(text) &&
      RegExp(r'\b(coupling|cplg|coup)\b').hasMatch(text) &&
      !RegExp(
        r'\b(cond|condensate|conduit|elec|electrical)\b',
      ).hasMatch(text) &&
      !RegExp(r'\b(reducing|reducer)\b').hasMatch(text);
  if (wantsPvcSch40Coupling) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pvc schedule 40 coupling') &&
          !name.contains('reducing') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsPexElbow =
      RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(90|elbow|ell|elb|codo)\b').hasMatch(text);
  if (wantsPexElbow) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('pex') &&
          name.contains('elbow') &&
          !name.contains('drop-ear') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }

  final wantsAngleStop =
      RegExp(r'\b(angle stop|supply stop|angle valve)\b').hasMatch(text) &&
      RegExp(r'\b(brass|1/2|3/8)\b').hasMatch(text);
  if (wantsAngleStop) {
    final size = _receiptSizeMatrix(text) ?? _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (!name.contains('push-fit') &&
          (name.contains('quarter turn angle stop') ||
              name.contains('angle stop valve')) &&
          (size == null ||
              name.contains(size) ||
              _nameMatchesReceiptMatrix(name, text) ||
              _matchesHalfByThreeEighthStop(text, item.variant))) {
        return item;
      }
    }
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade != 'Plumbing') continue;
      if (name.contains('supply stop') &&
          (size == null ||
              name.contains(size) ||
              _nameMatchesReceiptMatrix(name, text))) {
        return item;
      }
    }
  }

  final wantsThreadedRod =
      RegExp(
        r'\b(all thread|all-thread|threaded rod|thread rod)\b',
      ).hasMatch(text) &&
      RegExp(r'\b(1/4|3/8|1/2)\b').hasMatch(text);
  if (wantsThreadedRod) {
    final size = _nominalReceiptSize(text);
    for (final item in _activeWorkSupplyCatalogItems) {
      final name = item.name.toLowerCase();
      if (item.trade == 'Plumbing' &&
          name.contains('threaded rod') &&
          _nameMatchesReceiptSize(name, size)) {
        return item;
      }
    }
  }
  return null;
}

WorkSupplyItem? _directUnscopedElectricalEvidenceMatch(String text) {
  final wantsConduitStylePvcPart =
      RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cond|conduit|elec|electrical)\b').hasMatch(text) &&
      RegExp(
        r'\b(male|mip|terminal adapter|male adapter|female|fip|female adapter|body|lb)\b',
      ).hasMatch(text);
  if (!wantsConduitStylePvcPart) return null;
  final size = _nominalReceiptSize(text);
  final wantedName = switch (text) {
    final value when RegExp(r'\b(lb)\b').hasMatch(value) => 'lb conduit body',
    final value when RegExp(r'\b(body)\b').hasMatch(value) => 'conduit body',
    final value
        when RegExp(
          r'\b(male|mip|terminal adapter|male adapter)\b',
        ).hasMatch(value) =>
      'pvc electrical male adapter',
    final value
        when RegExp(r'\b(female|fip|female adapter)\b').hasMatch(value) =>
      'pvc electrical female adapter',
    _ => null,
  };
  if (wantedName == null) return null;
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Electrical' &&
        name.contains(wantedName) &&
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

bool _hasStrongDirectPlumbingEvidence(String text) {
  return RegExp(
    r'\b(dwv|pex|cpvc|sharkbite|angle stop|supply stop|straight stop|'
    r'quarter turn stop|p trap|p-trap|trap adapter|marvel adapter|'
    r'san tee|sanitary tee|sanitary t|cleanout|closet flange|wax ring|'
    r'hose bibb|sillcock|water heater|softener|well pump|well pressure)\b',
  ).hasMatch(text);
}

WorkSupplyItem? _directPvcDwvSanitaryTeeReceiptMatch(String text) {
  if (!RegExp(r'\b(pvc|dwv|drain)\b').hasMatch(text)) return null;
  if (RegExp(r'\b(abs|black\s+dwv|black\s+drain)\b').hasMatch(text)) {
    return null;
  }
  if (!RegExp(
    r'\b(san tee|sanitary tee|sanitary tees|sanitary t)\b',
  ).hasMatch(text)) {
    return null;
  }
  final size = _nominalReceiptSize(text);
  final wantsReducing = RegExp(r'\b(reducing|reducer|red)\b').hasMatch(text);
  for (final item in _plumbingPvcDwvSanitaryTeeItems) {
    final name = item.name.toLowerCase();
    if (wantsReducing != name.contains('reducing')) continue;
    if (_nameMatchesReceiptMatrix(name, text) ||
        _receiptMatchesVariant(text, item.variant) ||
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

WorkSupplyItem? _directPlumbingLegacyAdapterFastMatch(String text) {
  final preferredStyle = text.contains('desanco')
      ? 'desanco adapter'
      : text.contains('marvel')
      ? 'marvel adapter'
      : text.contains('wall bend')
      ? 'wall bend'
      : text.contains('trap arm')
      ? 'trap arm'
      : RegExp(r'\b(compression trap|comp trap)\b').hasMatch(text)
      ? 'compression trap adapter'
      : null;
  if (preferredStyle == null) return null;
  final size = _nominalReceiptSize(text);
  for (final item in _activeWorkSupplyCatalogItems) {
    final name = item.name.toLowerCase();
    if (item.trade == 'Plumbing' &&
        name.contains(preferredStyle) &&
        name.contains('tubular drain adapter') &&
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

bool _matchesHalfByThreeEighthStop(String receiptText, String variant) {
  final text = receiptText.toLowerCase();
  final normalizedVariant = variant.toLowerCase();
  return RegExp(r'\b1/2\b').hasMatch(text) &&
      RegExp(r'\b3/8\b').hasMatch(text) &&
      normalizedVariant.contains('1/2') &&
      normalizedVariant.contains('3/8');
}

bool _isUnscopedDangerousShortLine(String text, String? tradeScope) {
  if (tradeScope != null && tradeScope.trim().isNotEmpty) return false;
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      !RegExp(
        r'\b(dwv|drain|sewer|pressure|potable|plumb|conduit|electrical|cond|condensate|hvac)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\b(filter|filtro)\b').hasMatch(text) &&
      RegExp(r'\b\d{1,2}\s*x\s*\d{1,2}\s*x\s*\d{1,2}\b').hasMatch(text) &&
      !RegExp(
        r'\b(air|aire|merv|furnace|horno|hvac|return|retorno|pleated|media|water|agua|oil|aceite)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bcoupling\b').hasMatch(text) &&
      RegExp(r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2|3|4)\b').hasMatch(text) &&
      !RegExp(
        r'\b(pvc|cpvc|pex|copper|emt|cond|conduit|dwv|abs)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bj\s*box\b').hasMatch(text)) return true;
  if (RegExp(r'\bfoil\s+tape\b').hasMatch(text) &&
      !RegExp(r'\b(hvac|duct|mastic|ul181|fsk)\b').hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bwire\s+connector\b').hasMatch(text) &&
      !RegExp(
        r'\b(lever|push[\s-]?in|butt|closed\s+end|inline|splice|'
        r'waterproof|grounding|twister|electrical|electric|elec|'
        r'landscape\s+lighting)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bbushing\b').hasMatch(text) &&
      !RegExp(
        r'\b(anti[\s-]?short|insulated|conduit|emt|rigid|mc|electrical|'
        r'electric|elec)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bcondensate\s+drain\b').hasMatch(text) &&
      !RegExp(
        r'\b(gun|cartridge|tablet|tab|pan|pump|trap|tee|cleanout|tubing|'
        r'hvac|furnace|air\s*handler|ac|a/c)\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bsalt\s+pellets?\b').hasMatch(text) &&
      !RegExp(
        r'\b(water\s+)?softener|brine|ablandador|suavizador\b',
      ).hasMatch(text)) {
    return true;
  }
  if (RegExp(r'\bconnector\s+kit\b').hasMatch(text) &&
      !RegExp(
        r'\b(dishwasher|toilet|faucet|gas|dryer|washer|appliance|romex|'
        r'nm|electrical|electric|elec)\b',
      ).hasMatch(text)) {
    return true;
  }
  return switch (text) {
    'adapter' ||
    'black' ||
    'box' ||
    'bushing' ||
    'cap' ||
    'cement' ||
    'condensate' ||
    'conduit' ||
    'connector' ||
    'copper' ||
    'coupling' ||
    'drain' ||
    'elbow' ||
    'filter' ||
    'fitting' ||
    'kit' ||
    'pipe' ||
    'plug' ||
    'primer' ||
    'pvc' ||
    'pvc cement' ||
    'supply' ||
    'tape' ||
    'tee' ||
    'valve' ||
    'white' ||
    'wire' => true,
    _ => false,
  };
}

bool _isScopedPlumbingDangerousElbowReviewLine(
  String text,
  String? tradeScope,
) {
  if (tradeScope == null || tradeScope.trim().toLowerCase() != 'plumbing') {
    return false;
  }
  if (!RegExp(r'\bpvc\b').hasMatch(text)) return false;
  if (!_hasReceiptElbowShapeToken(text)) return false;
  if (RegExp(
    r'\b(?:1/2|3/4|1|1-1/4|1-1/2|2|3|4)(?:\s+in)?\s+pvc\b',
  ).hasMatch(text)) {
    return false;
  }
  if (RegExp(
    r'\b(dwv|sch\s*40|schedule\s*40|sch\s*80|schedule\s*80|pressure|cpvc|abs)\b',
  ).hasMatch(text)) {
    return false;
  }
  return true;
}

WorkSupplyItem? _directScopedPlumbingSumpBarbedAdapterMatch(String text) {
  if (!RegExp(r'\b(sump pump|submersible sump)\b').hasMatch(text)) return null;
  if (!RegExp(r'\b(barb|barbed)\b').hasMatch(text)) return null;
  if (!RegExp(r'\b(adapter|adpt)\b').hasMatch(text)) return null;
  final size = _nominalReceiptSize(text);
  for (final item in _activeWorkSupplyCatalogItems) {
    final searchable = _indexedReceiptTextFor(item);
    final name = item.name.toLowerCase();
    final variant = item.variant.toLowerCase();
    if (item.trade == 'Plumbing' &&
        searchable.contains('barbed adapter') &&
        searchable.contains('sump pump') &&
        (name.contains('sump pump discharge adapter') ||
            name.contains('sump pump discharge part')) &&
        variant.contains('barbed adapter') &&
        _nameMatchesReceiptSize(name, size)) {
      return item;
    }
  }
  return null;
}

List<String> _receiptTokenAlternates(String token) {
  return switch (token) {
    'half' => const ['half', '1/2'],
    'quarter' => const ['quarter', '1/4'],
    'three-quarter' => const ['three-quarter', '3/4'],
    'inch' => const ['inch', 'in'],
    'in' => const ['inch', 'in'],
    'ninety' => const ['ninety', '90'],
    'forty-five' => const ['forty-five', '45'],
    _ => [token],
  };
}

List<String> _matchedTerms(String text, WorkSupplyItem item) {
  final haystack = _indexedReceiptTextFor(item);
  return _termsContainedIn(text, haystack);
}

List<String> _directMatchedTerms(String text, WorkSupplyItem item) {
  final haystack = _normalize(
    '${item.name} ${item.variant} ${item.itemType} ${item.system} '
    '${item.aliases.join(' ')}',
  );
  return _termsContainedIn(text, haystack);
}

List<String> _termsContainedIn(String text, String haystack) {
  final terms = <String>{};
  for (final token in text.split(RegExp(r'\s+'))) {
    if (token.isNotEmpty &&
        !_isParserNoiseToken(token) &&
        token != 'x' &&
        _containsTerm(haystack, token)) {
      terms.add(token);
    }
  }
  return terms.toList();
}

String _indexedReceiptTextFor(WorkSupplyItem item) {
  return _receiptTextCacheByItemId.putIfAbsent(
    item.id,
    () => _normalize('${item.searchableText} ${item.aliases.join(' ')}'),
  );
}

({WorkSupplyItem item, List<String> terms, int score}) _scoredReceiptCandidate(
  String text,
  WorkSupplyItem item,
) {
  final terms = _matchedTerms(text, item);
  return (
    item: item,
    terms: terms,
    score: _receiptItemScore(text, item, terms),
  );
}

int _receiptItemScore(String text, WorkSupplyItem item, List<String> terms) {
  var score = terms.length;
  if (_containsExactPhrase(text, item.variant)) score += 20;
  if (_containsBareSingleInchSize(text, item.variant)) score += 18;
  if (_containsExactPhrase(text, item.name)) score += 8;
  if (_containsExactPhrase(text, item.itemType)) score += 4;
  if (_containsExactPhrase(text, item.system)) score += 4;
  score += _tradeContextScore(text, item);
  final entry = _receiptCatalogEntryById[item.id];
  if (entry != null) score += _receiptFallbackSpecificityScore(text, entry);
  return score;
}

bool _containsBareSingleInchSize(String text, String variant) {
  if (text.contains(' x ')) return false;
  final normalizedVariant = _normalize(variant);
  final match = RegExp(
    r'^(\d+(?:-\d/\d|\.\d+)?) in$',
  ).firstMatch(normalizedVariant);
  if (match == null) return false;
  final size = match.group(1)!;
  return RegExp('(^| )${RegExp.escape(size)}( |\$)').hasMatch(text);
}

String? _nominalReceiptSize(String text) {
  final normalized = _stripReceiptPosNoiseForSize(_normalize(text));
  for (final size in const ['1-1/2', '1-1/4', '2-1/2']) {
    if (RegExp('(^| )${RegExp.escape(size)}( |\$)').hasMatch(normalized)) {
      return size;
    }
  }
  for (final size in const ['1/4', '3/8', '1/2', '5/8', '3/4']) {
    if (RegExp('(^| )${RegExp.escape(size)}( |\$)').hasMatch(normalized)) {
      return size;
    }
  }
  final match = RegExp(
    r'(^| )(1/4|3/8|1/2|5/8|3/4|1-1/4|1-1/2|2-1/2|10|12|1|2|3|4|6|8)( |$)',
  ).firstMatch(normalized);
  return match?.group(2);
}

String _stripReceiptPosNoiseForSize(String normalized) {
  return normalized
      .replaceAll(RegExp(r'\b\d+\s+@\s+\d+(?:\.\d+)?\b'), ' ')
      .replaceAll(RegExp(r'\b\d+\s+\d+\s+\d+\s+(?=1/4|3/8|1/2|5/8|3/4)\b'), ' ')
      .replaceAll(
        RegExp(
          r'\b\d+(?:\.\d+)?\s+(?:oz|ounce|ounces|lb|lbs|pound|pounds|'
          r'gal|gallon|gallons|qt|quart|quarts|pt|pint|pints|ml|l|pk|pack)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\bqty\s*\d+\b'), ' ')
      .replaceAll(RegExp(r'\b\d+\s*ea\b'), ' ')
      .replaceAll(RegExp(r'\bdisc\s+-?\d+(?:\.\d+)?\b'), ' ')
      .replaceAll(RegExp(r'\bsku\s+\d+\b'), ' ')
      .replaceAll(RegExp(r'\b\d{4,}\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _receiptPackageAmount(String text, String unit) {
  final normalized = _normalize(text);
  final match = RegExp(
    '(^| )(\\d+(?:\\.\\d+)?) ${RegExp.escape(unit)}( |\$)',
  ).firstMatch(normalized);
  return match?.group(2);
}

bool _itemMatchesPackageAmount(
  WorkSupplyItem item,
  String? amount,
  String unit,
) {
  if (amount == null) return false;
  final variant = _normalize(item.variant);
  final name = _normalize(item.name);
  return variant.startsWith('$amount $unit ') ||
      variant == '$amount $unit' ||
      name.startsWith('$amount $unit ');
}

bool _nameMatchesReceiptSize(String name, String? size) {
  if (size == null) return true;
  return name.startsWith('$size in ') || name.startsWith('$size x ');
}

bool _receiptMatchesVariant(String text, String variant) {
  final normalizedVariant = _normalize(
    variant,
  ).replaceAll(' in ', ' ').replaceAll(' in', '');
  if (normalizedVariant.isEmpty) return false;
  final normalizedText = text.replaceAll(' in ', ' ').replaceAll(' in', '');
  return RegExp(
    '(^| )${RegExp.escape(normalizedVariant)}( |\$)',
  ).hasMatch(normalizedText);
}

bool _receiptContainsVariantTokens(String text, String variant) {
  final normalizedText = _normalizeVariantTokenText(text);
  final tokens = _normalizeVariantTokenText(_normalize(variant))
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1 || RegExp(r'\d').hasMatch(token))
      .toSet();
  if (tokens.isEmpty) return false;
  return tokens.every(
    (token) =>
        RegExp('(^| )${RegExp.escape(token)}( |\$)').hasMatch(normalizedText),
  );
}

bool _receiptStartsWithVariant(String text, String variant) {
  final normalizedText = _normalizeVariantTokenText(text);
  final normalizedVariant = _normalizeVariantTokenText(_normalize(variant));
  if (normalizedVariant.isEmpty) return false;
  final withoutMerchant = normalizedText.replaceFirst(
    RegExp(r'^(ace|hd|lowes|supply) '),
    '',
  );
  return normalizedText == normalizedVariant ||
      normalizedText.startsWith('$normalizedVariant ') ||
      withoutMerchant == normalizedVariant ||
      withoutMerchant.startsWith('$normalizedVariant ');
}

String _normalizeVariantTokenText(String value) {
  return (' $value ')
      .replaceAll(' elb ', ' elbow ')
      .replaceAll(' adpts ', ' adapters ')
      .replaceAll(' adpt ', ' adapter ')
      .replaceAll(' cplg ', ' coupling ')
      .replaceAll(' conn ', ' connector ')
      .replaceAll(' conns ', ' connectors ')
      .replaceAll(' dw ', ' dishwasher ')
      .replaceAll(' o-ring ', ' oring ')
      .replaceAll(' o ring ', ' oring ')
      .replaceAll(' wax-free ', ' wax free ')
      .replaceAll(' snap in ', ' snap-in ')
      .replaceAll(' screw down ', ' screw-down ')
      .replaceAll(' m ', ' male ')
      .replaceAll(' f ', ' female ')
      .replaceAll(' in ', ' ')
      .replaceAll(' in ', ' ')
      .trim();
}

bool _nameMatchesReceiptMatrix(String name, String text) {
  final matrix = _receiptSizeMatrix(text);
  if (matrix == null) return false;
  return RegExp('^${RegExp.escape(matrix)}(?! x )').hasMatch(name);
}

String? _receiptSizeMatrix(String text) {
  final matrix = RegExp(
    r'\b\d+(?:-\d/\d|/\d)?(?: x \d+(?:-\d/\d|/\d)?){1,2}\b',
  ).firstMatch(text);
  return matrix?.group(0);
}

String? _explicitTubularTrapSize(String text) {
  if (RegExp(r'(^| )1-1/2( |$)').hasMatch(text)) return '1-1/2';
  if (RegExp(r'(^| )1-1/4( |$)').hasMatch(text)) return '1-1/4';
  return null;
}

bool _containsExactPhrase(String text, String phrase) {
  final normalizedPhrase = _normalize(phrase);
  if (normalizedPhrase.isEmpty) return false;
  return RegExp('(^| )${RegExp.escape(normalizedPhrase)}( |\$)').hasMatch(text);
}
