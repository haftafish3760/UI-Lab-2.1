import 'package:flutter/foundation.dart';

enum PrototypeFinancialKind { invoiceIssued, paymentReceived, paymentApplied }

/// Invoice links apply to a balance. Job and estimate links give payment
/// context but require a separate allocation before affecting a later invoice.
enum PaymentLinkKind { invoice, job, estimate, quote, none }

@immutable
class PrototypeFinancialEntry {
  const PrototypeFinancialEntry({
    required this.id,
    required this.kind,
    required this.occurredOn,
    required this.amountCents,
    required this.sourceId,
    this.paymentLinkKind = PaymentLinkKind.invoice,
    this.payerName = '',
    this.description = '',
    this.sourcePaymentId = '',
    this.paymentMethod = '',
    this.note = '',
  });

  final String id;
  final PrototypeFinancialKind kind;
  final DateTime occurredOn;
  final int amountCents;
  final String sourceId;
  final PaymentLinkKind paymentLinkKind;
  final String payerName;
  final String description;

  /// Only an application event uses this; it does not represent new money.
  final String sourcePaymentId;
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
