import 'work_supply_models.dart';

class WorkSupplyItemIdentityDraft {
  const WorkSupplyItemIdentityDraft({
    required this.trade,
    required this.category,
    required this.template,
    required this.composition,
    required this.size,
    this.unit = 'each',
    this.aliases = const [],
  });

  final String trade;
  final String category;
  final String template;
  final String composition;
  final String size;
  final String unit;
  final List<String> aliases;
}

class ResolvedWorkSupplyItemIdentity {
  const ResolvedWorkSupplyItemIdentity({
    required this.item,
    required this.canonicalKey,
    required this.created,
  });

  final WorkSupplyItem item;
  final String canonicalKey;
  final bool created;
}

ResolvedWorkSupplyItemIdentity resolveWorkSupplyItemIdentity({
  required WorkSupplyItemIdentityDraft draft,
  Iterable<WorkSupplyItem> catalogItems = const [],
  Iterable<WorkSupplyItem> customItems = const [],
  Iterable<WorkSupplyInventoryRecord> inventoryRecords = const [],
}) {
  final created = workSupplyItemFromIdentityDraft(draft);
  final canonicalKey = canonicalWorkSupplyItemKey(created);
  final candidates = [
    for (final record in inventoryRecords) record.item,
    ...customItems,
    ...catalogItems,
  ];
  for (final candidate in candidates) {
    if (canonicalWorkSupplyItemKey(candidate) == canonicalKey) {
      return ResolvedWorkSupplyItemIdentity(
        item: candidate,
        canonicalKey: canonicalKey,
        created: false,
      );
    }
  }
  return ResolvedWorkSupplyItemIdentity(
    item: created,
    canonicalKey: canonicalKey,
    created: true,
  );
}

WorkSupplyItem workSupplyItemFromIdentityDraft(
  WorkSupplyItemIdentityDraft draft,
) {
  final trade = draft.trade.trim();
  final category = draft.category.trim();
  final template = _cleanTemplate(draft.template);
  final composition = draft.composition.trim();
  final size = normalizeWorkSupplyItemSize(draft.size);
  final unit = draft.unit.trim().isEmpty ? 'each' : draft.unit.trim();
  final name = [
    if (size.isNotEmpty) size,
    if (composition.isNotEmpty) composition,
    template,
  ].join(' ');
  final item = WorkSupplyItem(
    id: '',
    name: name,
    trade: trade,
    category: category,
    system: composition,
    itemType: template,
    variant: size,
    unit: unit,
    aliases: [
      ...draft.aliases,
      template,
      composition,
      size,
    ].where((value) => value.trim().isNotEmpty).toSet().toList(),
  );
  return WorkSupplyItem(
    id: 'USER-${canonicalWorkSupplyItemKey(item)}',
    name: item.name,
    trade: item.trade,
    category: item.category,
    system: item.system,
    itemType: item.itemType,
    variant: item.variant,
    unit: item.unit,
    aliases: item.aliases,
  );
}

String canonicalWorkSupplyItemKey(WorkSupplyItem item) {
  final template = _cleanTemplate(item.itemType);
  return [
    _keyPart(template),
    _keyPart(item.system),
    _keyPart(normalizeWorkSupplyItemSize(item.variant)),
    _keyPart(item.unit.trim().isEmpty ? 'each' : item.unit),
  ].join(':');
}

String tradeScopedWorkSupplyItemKey(WorkSupplyItem item) {
  return [
    _keyPart(item.trade),
    _keyPart(item.category),
    canonicalWorkSupplyItemKey(item),
  ].join(':');
}

String normalizeWorkSupplyItemSize(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'(?<=[a-z])-(?=[a-z])'), ' ')
      .replaceAll(RegExp(r'\bone and one quarter\b'), '1 1/4')
      .replaceAll(RegExp(r'\bone and one half\b'), '1 1/2')
      .replaceAll(RegExp(r'\bthree quarters?\b'), '3/4')
      .replaceAll(RegExp(r'\bone half\b'), '1/2')
      .replaceAll(RegExp(r'\bhalf\b'), '1/2')
      .replaceAll(RegExp(r'\bone quarter\b'), '1/4')
      .replaceAll(RegExp(r'\bquarter\b'), '1/4')
      .replaceAll('inch', 'in')
      .replaceAll('"', ' in')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized
      .split(RegExp(r'\s*x\s*'))
      .map(_normalizeSingleSizePart)
      .where((part) => part.isNotEmpty)
      .join(' x ');
}

String _normalizeSingleSizePart(String value) {
  final part = value
      .replaceAll(RegExp(r'\bin\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (part.isEmpty) return '';
  if (!RegExp(r'\d').hasMatch(part)) return part;
  return '${part.replaceAll(' ', '-')} in';
}

String _cleanTemplate(String value) {
  final cleaned = value
      .replaceAll(RegExp('expanded', caseSensitive: false), '')
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final lower = cleaned.toLowerCase();
  const replacements = {
    '90 elbows': '90 Elbow',
    '90 elbow': '90 Elbow',
    '45 elbows': '45 Elbow',
    '45 elbow': '45 Elbow',
    '22.5 elbows': '22.5 Elbow',
    '22.5 elbow': '22.5 Elbow',
    'street 90 elbows': 'Street 90 Elbow',
    'street 90 elbow': 'Street 90 Elbow',
    'street 45 elbows': 'Street 45 Elbow',
    'street 45 elbow': 'Street 45 Elbow',
    'tees': 'Tee',
    'tee': 'Tee',
    't': 'Tee',
    'crosses': 'Cross',
    'cross': 'Cross',
    'couplings': 'Coupling',
    'coupling': 'Coupling',
    'repair couplings': 'Repair Coupling',
    'repair coupling': 'Repair Coupling',
    'reducing couplings': 'Reducing Coupling',
    'reducing coupling': 'Reducing Coupling',
    'reducers': 'Reducer',
    'reducer': 'Reducer',
    'reducer bushings': 'Reducer Bushing',
    'reducer bushing': 'Reducer Bushing',
    'male adapters': 'Male Adapter',
    'male adapter': 'Male Adapter',
    'female adapters': 'Female Adapter',
    'female adapter': 'Female Adapter',
    'caps': 'Cap',
    'cap': 'Cap',
    'plugs': 'Plug',
    'plug': 'Plug',
    'unions': 'Union',
    'union': 'Union',
    'nipples': 'Nipple',
    'nipple': 'Nipple',
    'floor flanges': 'Floor Flange',
    'floor flange': 'Floor Flange',
  };
  final replacement = replacements[lower];
  if (replacement != null) return replacement;
  if (lower.endsWith('ies') && cleaned.length > 3) {
    return '${cleaned.substring(0, cleaned.length - 3)}y';
  }
  if (lower.endsWith('s') && !lower.endsWith('ss') && cleaned.length > 3) {
    return cleaned.substring(0, cleaned.length - 1);
  }
  return cleaned;
}

String _keyPart(String value) {
  return value
      .toLowerCase()
      .replaceAll('inch', 'in')
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), '_')
      .replaceAll('/', '_')
      .replaceAll('-', '_')
      .replaceAll('.', '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
