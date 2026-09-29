/// Internal permission to issue an invoice, separate from customer acceptance.
enum InvoiceApprovalDecision { submitted, approved, changesRequested }

class InvoiceApprovalEvent {
  const InvoiceApprovalEvent({
    required this.decision,
    required this.actorEmployeeId,
    required this.occurredOn,
    required this.contentFingerprint,
    this.note = '',
  });

  final InvoiceApprovalDecision decision;
  final String actorEmployeeId;
  final DateTime occurredOn;
  final String contentFingerprint;
  final String note;

  Map<String, Object?> toJson() => {
    'decision': decision.name,
    'actorEmployeeId': actorEmployeeId,
    'occurredOn': occurredOn.toIso8601String(),
    'contentFingerprint': contentFingerprint,
    'note': note,
  };

  factory InvoiceApprovalEvent.fromJson(Map<String, Object?> json) =>
      InvoiceApprovalEvent(
        decision: InvoiceApprovalDecision.values.byName(
          json['decision'] as String,
        ),
        actorEmployeeId: json['actorEmployeeId'] as String,
        occurredOn: DateTime.parse(json['occurredOn'] as String),
        contentFingerprint: json['contentFingerprint'] as String,
        note: json['note'] as String? ?? '',
      );
}
