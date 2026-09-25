/// A business user's record of customer consent to one document revision.
/// This records evidence; it does not determine legal enforceability.
enum CustomerApprovalMethod {
  signedEstimate('Signed estimate'),
  electronic('Approved electronically'),
  verbal('Verbal approval'),
  message('Text or message'),
  email('Email'),
  other('Other documented approval');

  const CustomerApprovalMethod(this.label);
  final String label;
}

class WorkCustomerApproval {
  const WorkCustomerApproval({
    required this.method,
    required this.customerName,
    required this.recordedByEmployeeId,
    required this.recordedOn,
    required this.revision,
    this.note = '',
  });

  final CustomerApprovalMethod method;
  final String customerName;
  final String recordedByEmployeeId;
  final DateTime recordedOn;
  final int revision;
  final String note;

  Map<String, Object?> toJson() => {
    'method': method.name,
    'customerName': customerName,
    'recordedByEmployeeId': recordedByEmployeeId,
    'recordedOn': recordedOn.toIso8601String(),
    'revision': revision,
    'note': note,
  };

  factory WorkCustomerApproval.fromJson(Map<String, Object?> json) =>
      WorkCustomerApproval(
        method: CustomerApprovalMethod.values.byName(json['method'] as String),
        customerName: json['customerName'] as String,
        recordedByEmployeeId: json['recordedByEmployeeId'] as String,
        recordedOn: DateTime.parse(json['recordedOn'] as String),
        revision: json['revision'] as int,
        note: json['note'] as String? ?? '',
      );
}
