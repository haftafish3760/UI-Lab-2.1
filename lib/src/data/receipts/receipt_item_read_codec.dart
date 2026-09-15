import '../expenses/expense_decimal_value.dart';
import 'receipt_item_read.dart';
import 'receipt_item_proposal.dart';
import 'receipt_photo_text.dart';
import 'receipt_reading_rows.dart';

Map<String, Object?> encodeReceiptItemRead(ReceiptItemRead read) => {
  'version': 1,
  'evidenceId': read.evidenceId,
  'sha256': read.sha256,
  'parserVersion': read.parserVersion,
  'readAtUtc': read.readAtUtc.toIso8601String(),
  'recognizedText': read.recognizedText,
  'warnings': read.warnings,
  'sourceLines': read.sourceLines.map(_encodeLine).toList(),
  'items': [
    for (final item in read.result.items)
      {
        'id': item.id,
        'description': item.description,
        'quantity': item.quantity?.toJson(),
        'unitPrice': item.unitPrice?.toJson(),
        'purchaseUnit': item.purchaseUnit,
        'lineTotalMinor': item.lineTotalMinor,
        'calculatedTotalMinor': item.calculatedTotalMinor,
        'warnings': item.warnings,
        'sourceRows': item.sourceRows.map(_encodeRow).toList(),
      },
  ],
  'unresolvedRows': read.result.unresolvedRows.map(_encodeRow).toList(),
};

ReceiptItemRead decodeReceiptItemRead(Map<String, Object?> json) {
  if (json['version'] != 1) {
    throw const FormatException('Unsupported receipt item read.');
  }
  final readAt = DateTime.tryParse(_text(json, 'readAtUtc'));
  if (readAt == null ||
      !readAt.isUtc ||
      readAt.toIso8601String() != json['readAtUtc']) {
    throw const FormatException('Invalid receipt read time.');
  }
  return ReceiptItemRead(
    evidenceId: _text(json, 'evidenceId'),
    sha256: _text(json, 'sha256'),
    parserVersion: _text(json, 'parserVersion'),
    readAtUtc: readAt,
    recognizedText: json['recognizedText'] as String,
    warnings: (json['warnings'] as List).cast<String>(),
    sourceLines: [
      for (final raw in json['sourceLines'] as List) _decodeLine(raw),
    ],
    result: ReceiptItemParseResult(
      items: [for (final raw in json['items'] as List) _decodeItem(_map(raw))],
      unresolvedRows: [
        for (final raw in json['unresolvedRows'] as List) _decodeRow(_map(raw)),
      ],
    ),
  );
}

ReceiptItemProposal _decodeItem(Map<String, Object?> json) {
  final rows = [
    for (final raw in json['sourceRows'] as List) _decodeRow(_map(raw)),
  ];
  if (rows.isEmpty) {
    throw const FormatException('Receipt item source is missing.');
  }
  for (final key in [
    'quantity',
    'unitPrice',
    'purchaseUnit',
    'lineTotalMinor',
    'calculatedTotalMinor',
  ]) {
    if (!json.containsKey(key)) throw FormatException('Missing $key.');
  }
  return ReceiptItemProposal(
    id: _text(json, 'id'),
    description: _text(json, 'description'),
    sourceRows: rows,
    quantity: _decimal(json['quantity']),
    unitPrice: _decimal(json['unitPrice']),
    purchaseUnit: json['purchaseUnit'] as String?,
    lineTotalMinor: _minor(json['lineTotalMinor']),
    calculatedTotalMinor: _minor(json['calculatedTotalMinor']),
    warnings: (json['warnings'] as List).cast<String>(),
  );
}

Map<String, Object?> _encodeRow(ReceiptReadingRow row) => {
  'index': row.index,
  'text': row.text,
  'sourceLines': row.sourceLines.map(_encodeLine).toList(),
};

List<Object> _encodeLine(ReceiptTextLine line) => [
  line.text,
  line.left,
  line.top,
  line.right,
  line.bottom,
];

ReceiptReadingRow _decodeRow(Map<String, Object?> json) {
  final index = json['index'];
  if (index is! int || index < 0) {
    throw const FormatException('Invalid receipt row index.');
  }
  return ReceiptReadingRow(index, _text(json, 'text'), [
    for (final raw in json['sourceLines'] as List) _decodeLine(raw),
  ]);
}

ReceiptTextLine _decodeLine(Object? raw) {
  if (raw is! List || raw.length != 5 || raw[0] is! String) {
    throw const FormatException('Invalid receipt source line.');
  }
  final coordinates = raw.skip(1).map((value) {
    if (value is! num || !value.isFinite) {
      throw const FormatException('Invalid source bounds.');
    }
    return value.toDouble();
  }).toList();
  if (coordinates[2] <= coordinates[0] || coordinates[3] <= coordinates[1]) {
    throw const FormatException('Invalid source rectangle.');
  }
  return ReceiptTextLine(
    raw[0] as String,
    coordinates[0],
    coordinates[1],
    coordinates[2],
    coordinates[3],
  );
}

String _text(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('Invalid receipt item data.');
  return value.cast<String, Object?>();
}

ExpenseDecimalValue? _decimal(Object? value) =>
    value == null ? null : ExpenseDecimalValue.fromJson(_map(value));
int? _minor(Object? value) {
  if (value == null) return null;
  if (value is! int || value < 0 || value > 99999999999) {
    throw const FormatException('Invalid receipt item amount.');
  }
  return value;
}
