import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Private checkpoint metadata. Original device paths are needed for a future
/// restore mapping and must never be reused as cloud-safe transport metadata.
class LocalSnapshotAttachment {
  const LocalSnapshotAttachment({
    required this.relativePath,
    required this.sourcePath,
    required this.byteLength,
    required this.digest,
  });
  final String relativePath;
  final String sourcePath;
  final int byteLength;
  final String digest;

  Map<String, Object?> toJson() => {
    'relativePath': relativePath,
    'sourcePath': sourcePath,
    'byteLength': byteLength,
    'sha256': digest,
  };
}

/// Read the immutable SQL checkpoint, never a newer live repository cache.
/// Historical manifests are included even if evidence is no longer active.
List<LocalSnapshotAttachment> readSnapshotAttachments(
  String snapshotPath,
  String storageRoot,
) {
  final database = sqlite.sqlite3.open(
    snapshotPath,
    mode: sqlite.OpenMode.readOnly,
  );
  try {
    database.execute('PRAGMA trusted_schema = OFF');
    database.execute('PRAGMA query_only = ON');
    final files = <String, LocalSnapshotAttachment>{};
    for (final table in ['local_records', 'local_record_revisions']) {
      final rows = database.select('''SELECT organization_id, domain, record_id,
        payload_version, payload FROM $table WHERE domain IN
        ('attachments/files', 'receipt-drafts/records')''');
      for (final row in rows) {
        if (row['payload_version'] != 1) {
          throw StateError('Unsupported attachment manifest version.');
        }
        final body = (jsonDecode(row['payload'] as String) as Map)
            .cast<String, Object?>();
        if (row['domain'] == 'attachments/files') {
          final id = row['record_id'] as String;
          final scope = sha256.convert(
            utf8.encode(row['organization_id'] as String),
          );
          final relative = '$scope/$id.image';
          if (!RegExp(r'^attachment-[a-f0-9]+$').hasMatch(id) ||
              body['relativePath'] != relative) {
            throw StateError('Invalid retained attachment path.');
          }
          _add(
            files,
            LocalSnapshotAttachment(
              relativePath: 'attachments/$relative',
              sourcePath: '$storageRoot/attachments/$relative',
              byteLength: body['byteLength'] as int,
              digest: body['sha256'] as String,
            ),
          );
        } else {
          final id = row['record_id'] as String;
          if (body['draftId'] != id ||
              body['organizationId'] != row['organization_id']) {
            throw StateError('Invalid receipt evidence scope.');
          }
          final folder = sha256
              .convert(utf8.encode(id))
              .toString()
              .substring(0, 24);
          for (final value in body['evidence'] as List) {
            final evidence = (value as Map).cast<String, Object?>();
            final evidenceId = evidence['evidenceId'] as String;
            final kind = evidence['kind'];
            if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(evidenceId) ||
                (kind != 'pdf' && kind != 'photo')) {
              throw StateError('Invalid receipt evidence identity.');
            }
            final extension = kind == 'pdf' ? 'pdf' : 'image';
            _add(
              files,
              LocalSnapshotAttachment(
                relativePath:
                    'receipt_evidence/evidence/$folder/$evidenceId.$extension',
                sourcePath: evidence['localPath'] as String,
                byteLength: evidence['byteLength'] as int,
                digest: evidence['sha256'] as String,
              ),
            );
          }
        }
      }
    }
    return files.values.toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  } finally {
    database.close();
  }
}

void _add(
  Map<String, LocalSnapshotAttachment> files,
  LocalSnapshotAttachment item,
) {
  if (item.byteLength < 1 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(item.digest)) {
    throw StateError('Invalid retained file contents manifest.');
  }
  final previous = files[item.relativePath];
  if (previous != null &&
      (previous.digest != item.digest ||
          previous.byteLength != item.byteLength ||
          previous.sourcePath != item.sourcePath)) {
    throw StateError('Conflicting retained file manifests.');
  }
  files[item.relativePath] = item;
}
