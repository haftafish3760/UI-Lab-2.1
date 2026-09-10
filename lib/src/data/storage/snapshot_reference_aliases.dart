import 'local_snapshot_attachment.dart';

/// Installation prefixes may change; the SQL-derived attachment identity must
/// not. Alias metadata can only preserve the same complete registered suffix.
Map<String, String> validateSnapshotReferenceAliases(
  Object? value,
  List<LocalSnapshotAttachment> attachments,
) {
  if (value == null) return const {};
  if (value is! Map) throw StateError('Invalid checkpoint file aliases.');
  final retained = attachments.map((entry) => entry.relativePath).toSet();
  final result = <String, String>{};
  for (final entry in value.entries) {
    final reference = entry.key;
    final relative = entry.value;
    if (reference is! String ||
        relative is! String ||
        !retained.contains(relative) ||
        !reference.endsWith('/$relative') ||
        reference.split('/').contains('..')) {
      throw StateError(
        'Checkpoint alias does not match its retained file identity.',
      );
    }
    result[reference] = relative;
  }
  return Map.unmodifiable(result);
}
