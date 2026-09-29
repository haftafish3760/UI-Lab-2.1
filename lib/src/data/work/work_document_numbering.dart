import 'package:drift/drift.dart';

import '../storage/local_record_command.dart';
import '../storage/local_record_store.dart';
import 'models/work_models.dart';
import 'sqlite_work_repository.dart';

/// Company-scoped, immutable number claims. Keeping claims after a draft is
/// deleted prevents an old number from silently being used for another client.
class WorkDocumentNumbering {
  const WorkDocumentNumbering(this.repository);

  final SqliteWorkRepository repository;
  static const domain = 'work/document-numbers';

  Future<String> previewNext({
    required String organizationId,
    required WorkRecordKind kind,
  }) async {
    _supported(kind);
    final used = await _usedNumbers(organizationId, kind);
    final claimed = await LocalRecordStore(repository.database).read(
      organizationId: organizationId,
      domain: domain,
      ownerIds: {organizationId},
    );
    var next = 1;
    for (final row in claimed) {
      final payload = LocalRecordStore(repository.database).decode(row);
      if (payload['kind'] != kind.name) continue;
      final value = _numericSuffix(payload['number'] as String? ?? '');
      if (value != null && value >= next) next = value + 1;
    }
    while (used.contains('$next')) {
      next++;
    }
    return '${_label(kind)} $next';
  }

  /// Call inside the same SQLite transaction that saves [mutations].
  Future<List<LocalRecordWrite>> claimsFor({
    required String organizationId,
    required List<WorkRecordMutation> mutations,
  }) async {
    final store = LocalRecordStore(repository.database);
    final newClaims = <String, LocalRecordWrite>{};
    for (final mutation in mutations) {
      final record = mutation.record;
      if (record.kind == WorkRecordKind.job) continue;
      final number = record.number.trim();
      if (number.isEmpty) {
        throw StateError(
          'Enter a ${_label(record.kind).toLowerCase()} number.',
        );
      }
      final previous = mutation.expectedStorageRevision == 0
          ? null
          : await repository.find(
              organizationId: organizationId,
              recordId: record.id,
              visibleCreatorIds: {record.createdByEmployeeId},
            );
      if (previous != null &&
          _normalized(previous.record.number, record.kind) ==
              _normalized(number, record.kind)) {
        continue;
      }
      final normalized = _normalized(number, record.kind);
      final claimId = '${record.kind.name}:$normalized';
      if (newClaims.containsKey(claimId)) {
        throw StateError(
          'That ${_label(record.kind).toLowerCase()} number is already used.',
        );
      }
      final oldClaim = await store.read(
        organizationId: organizationId,
        domain: domain,
        ownerIds: {organizationId},
        recordIds: {claimId},
      );
      if ((oldClaim.isNotEmpty &&
              store.decode(oldClaim.single)['workRecordId'] != record.id) ||
          await _numberUsedByAnotherRecord(
            organizationId: organizationId,
            kind: record.kind,
            normalized: normalized,
            excludingId: record.id,
          )) {
        throw StateError(
          'That ${_label(record.kind).toLowerCase()} number is already used.',
        );
      }
      newClaims[claimId] = LocalRecordWrite(
        domain: domain,
        recordId: claimId,
        ownerId: organizationId,
        expectedRevision: 0,
        payload: {
          'kind': record.kind.name,
          'number': number,
          'workRecordId': record.id,
        },
      );
    }
    return newClaims.values.toList();
  }

  Future<Set<String>> _usedNumbers(
    String organizationId,
    WorkRecordKind kind,
  ) async {
    final rows = await repository.database
        .customSelect(
          'SELECT json_extract(payload, \'\$.number\') AS number '
          'FROM local_records WHERE organization_id = ? AND domain = ? '
          'AND json_extract(payload, \'\$.kind\') = ?',
          variables: [
            Variable<String>(organizationId),
            const Variable<String>('work/records'),
            Variable<String>(kind.name),
          ],
        )
        .get();
    return rows
        .map((row) => _normalized(row.read<String>('number'), kind))
        .toSet();
  }

  Future<bool> _numberUsedByAnotherRecord({
    required String organizationId,
    required WorkRecordKind kind,
    required String normalized,
    required String excludingId,
  }) async {
    final rows = await repository.database
        .customSelect(
          'SELECT record_id, json_extract(payload, \'\$.number\') AS number '
          'FROM local_records WHERE organization_id = ? AND domain = ? '
          'AND json_extract(payload, \'\$.kind\') = ? AND record_id != ?',
          variables: [
            Variable<String>(organizationId),
            const Variable<String>('work/records'),
            Variable<String>(kind.name),
            Variable<String>(excludingId),
          ],
        )
        .get();
    return rows.any(
      (row) => _normalized(row.read<String>('number'), kind) == normalized,
    );
  }

  String _normalized(String value, WorkRecordKind kind) {
    final trimmed = value.trim().toLowerCase();
    final label = _label(kind).toLowerCase();
    final number = trimmed.startsWith('$label ')
        ? trimmed.substring(label.length).trim()
        : trimmed;
    return int.tryParse(number)?.toString() ?? number;
  }

  int? _numericSuffix(String value) =>
      int.tryParse(RegExp(r'(\d+)$').firstMatch(value.trim())?.group(1) ?? '');

  String _label(WorkRecordKind kind) => switch (kind) {
    WorkRecordKind.estimate => 'Estimate',
    WorkRecordKind.quote => 'Quote',
    WorkRecordKind.invoice => 'Invoice',
    WorkRecordKind.job => throw ArgumentError('Jobs use their own numbering.'),
  };

  void _supported(WorkRecordKind kind) {
    if (kind == WorkRecordKind.job) {
      throw ArgumentError('Jobs use their own numbering.');
    }
  }
}
