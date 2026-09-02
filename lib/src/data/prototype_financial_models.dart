import 'package:flutter/foundation.dart';

enum PrototypeFinancialKind { invoiceIssued, paymentReceived }

@immutable
class PrototypeFinancialEntry {
  const PrototypeFinancialEntry({
    required this.id,
    required this.kind,
    required this.occurredOn,
    required this.amountCents,
    required this.sourceId,
    this.paymentMethod = '',
    this.note = '',
  });

  final String id;
  final PrototypeFinancialKind kind;
  final DateTime occurredOn;
  final int amountCents;
  final String sourceId;
  final String paymentMethod;
  final String note;
}

@immutable
class PrototypeFinancialSummary {
  const PrototypeFinancialSummary({
    required this.invoicedRevenueCents,
    required this.moneyCollectedCents,
    required this.recordedExpenseCents,
  });

  final int invoicedRevenueCents;
  final int moneyCollectedCents;
  final int recordedExpenseCents;

  int get estimatedGrossProfitCents =>
      invoicedRevenueCents - recordedExpenseCents;

  double get estimatedGrossMargin => invoicedRevenueCents == 0
      ? 0
      : estimatedGrossProfitCents / invoicedRevenueCents;
}
