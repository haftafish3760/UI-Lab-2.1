import 'signature_ink.dart';

class WorkCustomerSignature {
  const WorkCustomerSignature({
    required this.signedBy,
    required this.signedOn,
    required this.signedRevision,
    this.ink,
    this.invalidatedOn,
    this.invalidationReason,
  });

  final SignatureInk? ink;
  final String signedBy;
  final DateTime signedOn;
  final int signedRevision;
  final DateTime? invalidatedOn;
  final String? invalidationReason;

  bool isCurrentFor(int revision) =>
      invalidatedOn == null && signedRevision == revision;

  WorkCustomerSignature invalidate(DateTime changedOn, String reason) =>
      WorkCustomerSignature(
        ink: ink,
        signedBy: signedBy,
        signedOn: signedOn,
        signedRevision: signedRevision,
        invalidatedOn: changedOn,
        invalidationReason: reason,
      );
}
