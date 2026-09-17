part of 'work_supply_catalog.dart';

typedef _CatalogSearchEntry = ({WorkSupplyItem item, String normalizedText});

final List<_CatalogSearchEntry> _catalogSearchEntries = [
  for (final catalogItem in workSupplyCatalogItems)
    (
      item: catalogItem,
      normalizedText: _normalizedSearchText(catalogItem.searchableText),
    ),
];

final Map<String, List<_CatalogSearchEntry>> _catalogSearchIndex =
    _buildCatalogSearchIndex(_catalogSearchEntries);

List<WorkSupplyItem> searchWorkSupplies(String query) {
  final tokens = query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty && !_ignoredSearchToken(token))
      .toList();
  if (tokens.isEmpty) return workSupplyCatalogItems.take(25).toList();
  final candidatesById = <String, _CatalogSearchEntry>{};
  final candidateScores = <String, int>{};
  Set<String>? requiredCandidateIds;
  for (final token in tokens) {
    final tokenCandidateIds = <String>{};
    for (final alternate in _tokenAlternates(token)) {
      final entries = _catalogSearchIndex[alternate];
      if (entries == null) continue;
      for (final entry in entries) {
        final id = entry.item.id;
        candidatesById[id] = entry;
        tokenCandidateIds.add(id);
      }
    }
    if (tokenCandidateIds.isEmpty) return const [];
    requiredCandidateIds = requiredCandidateIds == null
        ? tokenCandidateIds
        : (requiredCandidateIds..retainAll(tokenCandidateIds));
    if (requiredCandidateIds.isEmpty) return const [];
    for (final id in tokenCandidateIds) {
      candidateScores.update(id, (score) => score + 1, ifAbsent: () => 1);
    }
  }
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final id in requiredCandidateIds ?? const <String>{}) {
    final entry = candidatesById[id];
    if (entry == null) continue;
    final item = entry.item;
    var score = candidateScores[id] ?? 0;
    if (_wantsHalfInch(tokens) && item.variant == '1/2 in') score += 10;
    if (_wantsThreeQuarter(tokens) && item.variant == '3/4 in') score += 10;
    if (_wantsQuarter(tokens) && item.variant == '1/4 in') score += 10;
    scored.add((item: item, score: score));
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final aExpanded = _isExpandedCatalogItem(a.item);
    final bExpanded = _isExpandedCatalogItem(b.item);
    if (aExpanded != bExpanded) return aExpanded ? 1 : -1;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(100).toList();
}

Map<String, List<_CatalogSearchEntry>> _buildCatalogSearchIndex(
  List<_CatalogSearchEntry> entries,
) {
  final index = <String, List<_CatalogSearchEntry>>{};
  for (final entry in entries) {
    final tokens = entry.normalizedText
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && !_ignoredSearchToken(token));
    for (final token in tokens) {
      for (final indexedToken in _indexableSearchTokens(token)) {
        index.putIfAbsent(indexedToken, () => []).add(entry);
      }
    }
  }
  return index;
}

Iterable<String> _indexableSearchTokens(String token) sync* {
  yield token;
  if (token.length < 3 || token.contains('/') || token.contains('-')) return;
  for (var length = 3; length < token.length; length++) {
    yield token.substring(0, length);
  }
}

bool _isExpandedCatalogItem(WorkSupplyItem item) {
  return item.itemType.contains('Expanded');
}

bool _wantsHalfInch(List<String> tokens) {
  return tokens.contains('half') || tokens.contains('1/2');
}

bool _wantsThreeQuarter(List<String> tokens) {
  return tokens.contains('3/4') ||
      (tokens.contains('three') && tokens.contains('quarter'));
}

bool _wantsQuarter(List<String> tokens) {
  return tokens.contains('quarter') || tokens.contains('1/4');
}

bool _ignoredSearchToken(String token) {
  return switch (token) {
    'a' || 'an' || 'the' || 'by' || 'x' => true,
    _ => false,
  };
}

String _normalizedSearchText(String text) {
  return text
      .replaceAll(' in ', ' inch ')
      .replaceAll(' in', ' inch')
      .replaceAll(' x ', ' ')
      .replaceAll('1/2', '1/2 half')
      .replaceAll('1/4', '1/4 quarter')
      .replaceAll('3/4', '3/4 three-quarter three quarter')
      .replaceAll('1-1/4', '1-1/4 inch and a quarter')
      .replaceAll('1-1/2', '1-1/2 inch and a half')
      .replaceAll('90', '90 ninety')
      .replaceAll('45', '45 forty-five forty five');
}

List<String> _tokenAlternates(String token) {
  return switch (token) {
    'half' => const ['half', '1/2'],
    'quarter' => const ['quarter', '1/4'],
    'three-quarter' => const ['three-quarter', '3/4'],
    'three' => const ['three'],
    'inch' => const ['inch', 'in'],
    'in' => const ['inch', 'in'],
    'ninety' => const ['ninety', '90'],
    'forty-five' => const ['forty-five', '45'],
    _ => [token],
  };
}
