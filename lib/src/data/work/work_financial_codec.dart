import '../prototype_financial_models.dart';

Map<String, Object?> encodeFinancialEntry(PrototypeFinancialEntry value) => {
  'id': value.id,
  'kind': value.kind.name,
  'occurredOn': value.occurredOn.toIso8601String(),
  'amountCents': value.amountCents,
  'sourceId': value.sourceId,
  'paymentMethod': value.paymentMethod,
  'note': value.note,
};

PrototypeFinancialEntry decodeFinancialEntry(Map<String, Object?> json) =>
    PrototypeFinancialEntry(
      id: json['id'] as String,
      kind: PrototypeFinancialKind.values.byName(json['kind'] as String),
      occurredOn: DateTime.parse(json['occurredOn'] as String),
      amountCents: json['amountCents'] as int,
      sourceId: json['sourceId'] as String,
      paymentMethod: json['paymentMethod'] as String,
      note: json['note'] as String,
    );
