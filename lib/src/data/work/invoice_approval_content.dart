import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../storage/local_record_command.dart';
import 'models/work_models.dart';
import 'work_record_codec.dart';

/// Bind approval to content, including prices, client, terms and due date.
/// Collection status and the approval history themselves are not bill content.
String invoiceApprovalFingerprint(WorkRecord record) {
  final content = encodeWorkRecord(record)
    ..remove('status')
    ..remove('invoiceApprovalHistory')
    ..remove('requiresInvoiceApproval');
  return sha256.convert(utf8.encode(canonicalJson(content))).toString();
}

bool invoiceHasCurrentApproval(WorkRecord record) {
  final latest = record.invoiceApprovalHistory.lastOrNull;
  return latest != null &&
      latest.decision == InvoiceApprovalDecision.approved &&
      latest.contentFingerprint == invoiceApprovalFingerprint(record);
}
