import 'work_approval_evidence.dart';
export 'work_approval_evidence.dart';

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
    this.evidence = const [],
  });

  final CustomerApprovalMethod method;
  final String customerName;
  final String recordedByEmployeeId;
  final DateTime recordedOn;
  final int revision;
  final String note;
  final List<WorkApprovalEvidence> evidence;

  Map<String, Object?> toJson() => {
    'method': method.name,
    'customerName': customerName,
    'recordedByEmployeeId': recordedByEmployeeId,
    'recordedOn': recordedOn.toIso8601String(),
    'revision': revision,
    'note': note,
    if (evidence.isNotEmpty)
      'evidence': evidence.map((item) => item.toJson()).toList(),
  };

  factory WorkCustomerApproval.fromJson(Map<String, Object?> json) =>
      WorkCustomerApproval(
        method: CustomerApprovalMethod.values.byName(json['method'] as String),
        customerName: json['customerName'] as String,
        recordedByEmployeeId: json['recordedByEmployeeId'] as String,
        recordedOn: DateTime.parse(json['recordedOn'] as String),
        revision: json['revision'] as int,
        note: json['note'] as String? ?? '',
        evidence: List.unmodifiable(
          ((json['evidence'] as List?) ?? const []).map(
            (item) => WorkApprovalEvidence.fromJson(
              (item as Map).cast<String, Object?>(),
            ),
          ),
        ),
      );
}
