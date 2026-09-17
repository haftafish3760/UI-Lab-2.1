import '../storage/local_record_store.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_identity.dart';
import '../../shared/documents/customer_portal_gateway.dart';
import '../../shared/documents/customer_document.dart';
import 'work_persistence_session.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';

/// Retains the private link and response before updating the estimate. If the
/// estimate save fails, the retained response supports a safe retry.
class WorkCustomerReviewSession {
  WorkCustomerReviewSession({required this.work, required this.record,
    required this.document, required this.gateway});
  final WorkPersistenceSession work;
  final WorkRecord record;
  final CustomerDocument document;
  final CustomerPortalGateway gateway;
  LocalRecordStore get _store => LocalRecordStore(work.repository.database);
  String get _id => '${record.id}:revision:${record.revision}';
  String get _organization => work.permissions.organizationId;

  WorkRecord _authorize() {
    work.requireActiveDraftOwner();
    final current = work.records.where((r) => r.id == record.id).firstOrNull;
    if (current == null || current.revision != record.revision ||
        !work.permissions.canShareDocuments || !work.permissions.canEdit(current)) {
      throw StateError('This document changed or sharing permission is unavailable.');
    }
    return current;
  }

  Future<Map<String, Object?>?> _read() async {
    _authorize();
    final rows = await _store.read(organizationId: _organization,
      domain: 'work/customer-review', ownerIds: {record.createdByEmployeeId}, recordIds: {_id});
    _authorize();
    return rows.isEmpty ? null : _store.decode(rows.single);
  }

  Future<CustomerReviewLink?> restore() async {
    final data = await _read();
    if (data == null || data['revoked'] == true) return null;
    final url = Uri.parse(data['url']! as String);
    if (url.origin != gateway.origin.origin ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(url.fragment)) {
      throw StateError('The saved customer link belongs to another portal.');
    }
    return CustomerReviewLink(url: url,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(data['expiresAt']! as int),
      digest: data['digest']! as String);
  }

  Future<void> retain(CustomerReviewLink link) async {
    _authorize();
    await _write({'url': link.url.toString(), 'expiresAt': link.expiresAt.millisecondsSinceEpoch,
      'digest': link.digest, 'snapshot': document.toPortalJson(), 'revoked': false});
  }

  Future<void> markRevoked() async {
    final data = await _read();
    if (data != null) await _write({...data, 'revoked': true});
  }

  Future<void> _write(Map<String, Object?> payload) => work.repository.database.transaction(() async {
    _authorize();
    final rows = await _store.read(organizationId: _organization,
      domain: 'work/customer-review', ownerIds: {record.createdByEmployeeId}, recordIds: {_id});
    _authorize();
    await _store.commit(organizationId: _organization,
      commandId: newLocalRecordIdentity('customer-review'), occurredAt: DateTime.now().toUtc(),
      writes: [LocalRecordWrite(domain: 'work/customer-review', recordId: _id,
        ownerId: record.createdByEmployeeId, expectedRevision: rows.firstOrNull?.revision ?? 0,
        payload: {...payload, 'mutationActor': work.permissions.actorEmployeeId})]);
  });

  Future<String> check(CustomerReviewLink link) async {
    final before = _authorize();
    final expectedStorageRevision = work.storageRevisionFor(record.id);
    final result = await gateway.refresh(link);
    final current = _authorize();
    final stored = await _read();
    if (stored == null || result['digest'] != link.digest ||
        canonicalJson(stored['snapshot']) != canonicalJson(document.toPortalJson()) ||
        current.revision != before.revision) {
      throw StateError('The customer copy changed. Review the saved document before applying a response.');
    }
    final decision = result['decision'];
    if (decision == null) return result['revokedAt'] == null ? 'No customer response yet.' : 'This link was turned off.';
    if (decision is! Map || decision['digest'] != link.digest ||
        decision['revision'] != record.revision ||
        !['approved', 'declined'].contains(decision['action']) ||
        decision['name'] is! String || (decision['name'] as String).trim().isEmpty || decision['at'] is! int) {
      throw StateError('The portal response could not be verified.');
    }
    await _write({...stored, 'decision': Map<String, Object?>.from(decision)});
    if (record.kind != WorkRecordKind.estimate) return 'Customer response saved.';
    final approved = decision['action'] == 'approved';
    final stage = approved ? EstimateStage.approved : EstimateStage.declined;
    final decidedAt = DateTime.fromMillisecondsSinceEpoch(decision['at'] as int, isUtc: true);
    final evidence = 'Customer ${approved ? 'approved' : 'declined'} revision ${record.revision} through the private customer link. Named response: ${decision['name']}. Document fingerprint: ${link.digest}. Identity verified by possession of the link.';
    if (current.resolvedEstimateStage == EstimateStage.converted) return 'Customer response is already linked to the job.';
    if (current.resolvedEstimateStage == stage && stored['decision'] != null) return 'Customer response already saved.';
    if (current.resolvedEstimateStage == EstimateStage.draft ||
        current.resolvedEstimateStage == EstimateStage.archived || !current.companyReviewAllowsCustomerApproval) {
      throw StateError('The current estimate is not available for customer approval.');
    }
    final updated = approved
      ? current.recordEstimateSignature(decision['name'] as String, decidedAt, onlineEvidence: evidence)
      : current.withEstimateStage(stage, decidedAt);
    final saved = await work.save(records: [updated],
      expectedStorageRevisions: {record.id: expectedStorageRevision});
    if (!saved) throw StateError(work.failureMessage ?? 'The response is retained. Retry to update the estimate.');
    return approved ? 'Customer approved. The estimate is ready to turn into a job and assign employees.' : 'Customer declined. No job was created.';
  }
}
