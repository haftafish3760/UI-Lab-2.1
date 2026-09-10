import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'local_database.dart';
import 'local_record_command.dart';
import 'local_record_identity.dart';
import 'local_record_store.dart';

/// File bytes precede the SQL manifest. Failed imports never publish a manifest
/// for an incomplete file. Unreferenced files are retained until a separately
/// verified garbage-collection policy can account for drafts and history.
/// Callers must authorize the operation and supply their session scope.
class LocalAttachmentStore {
  LocalAttachmentStore(this.database, {Directory? directory})
    : directory = directory ?? _directoryFor(database);
  final LocalDatabase database;
  final Directory directory;
  static const domain = 'attachments/files';

  static Directory _directoryFor(LocalDatabase database) {
    final file = database.storageFile;
    if (file == null) throw StateError('Attachment directory is unavailable.');
    return Directory('${file.parent.path}/attachments');
  }

  Future<File> retain({
    required File source,
    required String organizationId,
    required String ownerId,
  }) async {
    if (organizationId.trim().isEmpty || ownerId.trim().isEmpty) {
      throw ArgumentError('Attachment scope is required.');
    }
    final id = newLocalRecordIdentity('attachment');
    final scope = sha256.convert(utf8.encode(organizationId)).toString();
    final folder = Directory('${directory.path}/$scope');
    await folder.create(recursive: true);
    final target = File('${folder.path}/$id.image');
    final temporary = File('${target.path}.partial');
    final sourceSize = await source.length();
    if (sourceSize == 0) throw StateError('An empty image cannot be retained.');
    final sourceHash = await sha256.bind(source.openRead()).first;
    try {
      final input = await source.open();
      try {
        final output = await temporary.open(mode: FileMode.write);
        try {
          while (true) {
            final bytes = await input.read(256 * 1024);
            if (bytes.isEmpty) break;
            await output.writeFrom(bytes);
          }
          await output.flush();
        } finally {
          await output.close();
        }
      } finally {
        await input.close();
      }
      final copiedHash = await sha256.bind(temporary.openRead()).first;
      if (await temporary.length() != sourceSize || copiedHash != sourceHash) {
        throw StateError('The source image changed during retention.');
      }
      await temporary.rename(target.path);
      await LocalRecordStore(database).commit(
        organizationId: organizationId,
        commandId: 'retain-$id',
        occurredAt: DateTime.now(),
        writes: [
          LocalRecordWrite(
            domain: domain,
            recordId: id,
            ownerId: ownerId,
            expectedRevision: 0,
            payload: {
              'relativePath': '$scope/$id.image',
              'sha256': copiedHash.toString(),
              'byteLength': sourceSize,
            },
          ),
        ],
      );
      return target;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  /// Verify scoped manifests before supplying retained bytes to consumers.
  Future<List<File>> verifiedFiles({
    required String organizationId,
    required Set<String> ownerIds,
    Set<String>? attachmentIds,
  }) async {
    final rows = await LocalRecordStore(database).read(
      organizationId: organizationId,
      domain: domain,
      ownerIds: ownerIds,
      recordIds: attachmentIds,
    );
    if (attachmentIds != null && rows.length != attachmentIds.length) {
      throw StateError('A requested attachment is unavailable.');
    }
    final result = <File>[];
    final scope = sha256.convert(utf8.encode(organizationId)).toString();
    for (final row in rows) {
      final payload = LocalRecordStore(database).decode(row);
      final relative = payload['relativePath'] as String;
      if (relative != '$scope/${row.recordId}.image' ||
          !RegExp(r'^attachment-[a-f0-9]+$').hasMatch(row.recordId)) {
        throw StateError('Invalid attachment identity.');
      }
      final file = File('${directory.path}/$relative');
      if (!await file.exists() ||
          await file.length() != payload['byteLength'] ||
          (await sha256.bind(file.openRead()).first).toString() !=
              payload['sha256']) {
        throw StateError('A retained image is missing or damaged.');
      }
      result.add(file);
    }
    return result;
  }
}
