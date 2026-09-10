import 'dart:convert';
import 'package:drift/drift.dart';

import 'local_database.dart';
import 'local_attachment_store.dart';
import 'local_record_command.dart';
import 'local_record_identity.dart';

enum MediaPickerDestination { receipt, estimate }

enum MediaPickerSource { camera, library, files }

/// Native-returned file metadata. This is a retry source, not retained proof.
class MediaPickerReturnedFile {
  MediaPickerReturnedFile({required this.path, required this.name}) {
    if (path.trim().isEmpty ||
        name.trim().isEmpty ||
        path.contains('\u0000') ||
        !(path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path))) {
      throw ArgumentError('A picker result needs an absolute path and name.');
    }
  }
  final String path;
  final String name;
  Map<String, Object?> toJson() => {'path': path, 'name': name};
}

/// A persisted routing identity, not permission to read or attach media.
class LocalMediaPickerRequest {
  const LocalMediaPickerRequest._({
    required this.requestId,
    required this.organizationId,
    required this.ownerId,
    required this.destination,
    required this.targetId,
    required this.targetRevision,
    required this.source,
    this.retainedAttachmentIds,
    this.returnedFiles,
  });

  final String requestId;
  final String organizationId;
  final String ownerId;
  final MediaPickerDestination destination;
  final String targetId;
  final int targetRevision;
  final MediaPickerSource source;
  final List<String>? retainedAttachmentIds;
  final List<MediaPickerReturnedFile>? returnedFiles;

  Map<String, Object?> toJson() => {
    'version': 1,
    'requestId': requestId,
    'organizationId': organizationId,
    'ownerId': ownerId,
    'destination': destination.name,
    'targetId': targetId,
    'targetRevision': targetRevision,
    'source': source.name,
    if (returnedFiles != null)
      'returnedFiles': returnedFiles!.map((file) => file.toJson()).toList(),
    if (retainedAttachmentIds != null)
      'retainedAttachmentIds': retainedAttachmentIds,
  };

  static LocalMediaPickerRequest _decode(String value) {
    final data = (jsonDecode(value) as Map).cast<String, Object?>();
    if (data['version'] != 1) {
      throw StateError('Unsupported media request version.');
    }
    final request = LocalMediaPickerRequest._(
      requestId: data['requestId'] as String,
      organizationId: data['organizationId'] as String,
      ownerId: data['ownerId'] as String,
      destination: MediaPickerDestination.values.byName(
        data['destination'] as String,
      ),
      targetId: data['targetId'] as String,
      targetRevision: data['targetRevision'] as int,
      source: MediaPickerSource.values.byName(data['source'] as String),
      returnedFiles: data.containsKey('returnedFiles')
          ? List<MediaPickerReturnedFile>.unmodifiable(
              (data['returnedFiles'] as List).map((entry) {
                final file = (entry as Map).cast<String, Object?>();
                return MediaPickerReturnedFile(
                  path: file['path'] as String,
                  name: file['name'] as String,
                );
              }),
            )
          : null,
      retainedAttachmentIds: data.containsKey('retainedAttachmentIds')
          ? List<String>.unmodifiable(
              (data['retainedAttachmentIds'] as List).cast<String>(),
            )
          : null,
    );
    _validate(
      request.organizationId,
      request.ownerId,
      request.targetId,
      request.targetRevision,
    );
    if (!RegExp(r'^media-request-[a-f0-9]{32}$').hasMatch(request.requestId)) {
      throw StateError('Invalid media request identity.');
    }
    if (request.returnedFiles != null) {
      _validateReturnedFiles(request.returnedFiles!);
    }
    if (request.retainedAttachmentIds != null) {
      _validateAttachments(request.retainedAttachmentIds!);
    }
    return request;
  }
}

/// One device-wide slot because the native image picker has one result cache.
/// Callers authorize the target before begin and again before adoption. This
/// store does not invoke plugins, retain files or publish repository/UI caches.
class LocalMediaPickerRequestStore {
  const LocalMediaPickerRequestStore(this.database);
  final LocalDatabase database;
  static const metadataKey = 'native.image-picker.request.v1';

  /// Installation lifecycle only: inspect the app-wide handoff without exposing
  /// another actor's request through an editor query or presenting its contents.
  Future<LocalMediaPickerRequest?> findForInstallationLifecycle() => _read();

  Future<LocalMediaPickerRequest?> findFor({
    required String organizationId,
    required String ownerId,
  }) async {
    final request = await _read();
    return request?.organizationId == organizationId &&
            request?.ownerId == ownerId
        ? request
        : null;
  }

  Future<LocalMediaPickerRequest> begin({
    required String organizationId,
    required String ownerId,
    required MediaPickerDestination destination,
    required String targetId,
    required int targetRevision,
    required MediaPickerSource source,
  }) async {
    _validate(organizationId, ownerId, targetId, targetRevision);
    final request = LocalMediaPickerRequest._(
      requestId: newLocalRecordIdentity('media-request'),
      organizationId: organizationId,
      ownerId: ownerId,
      destination: destination,
      targetId: targetId,
      targetRevision: targetRevision,
      source: source,
    );
    return database.transaction(() async {
      // Check occupancy without decoding: unknown/corrupt requests must not be
      // silently replaced just because this version cannot interpret them.
      final occupied = await database
          .customSelect(
            'SELECT 1 FROM local_metadata WHERE metadata_key = ?',
            variables: [Variable.withString(metadataKey)],
          )
          .get();
      if (occupied.isNotEmpty) {
        throw const LocalRecordConflict('A media request is already pending.');
      }
      await database.customStatement(
        'INSERT INTO local_metadata(metadata_key, value) VALUES (?, ?)',
        [metadataKey, canonicalJson(request.toJson())],
      );
      return request;
    });
  }

  /// Persist the native result before slow file retention. Temporary source
  /// files may still disappear; callers must not call this a retained photo.
  Future<LocalMediaPickerRequest> recordReturnedFiles({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
    required List<MediaPickerReturnedFile> files,
  }) async {
    final copy = List<MediaPickerReturnedFile>.unmodifiable(files);
    _validateReturnedFiles(copy);
    return database.transaction(() async {
      final current = await _matchingRequest(
        request,
        organizationId,
        ownerId,
        includeResults: false,
      );
      final payload = copy.map((file) => file.toJson()).toList();
      if (current.returnedFiles != null) {
        if (canonicalJson(current.toJson()['returnedFiles']) !=
            canonicalJson(payload)) {
          throw const LocalRecordConflict('Native media results changed.');
        }
        return current;
      }
      if (current.retainedAttachmentIds != null) {
        throw const LocalRecordConflict('Media was already retained.');
      }
      final updated = LocalMediaPickerRequest._decode(
        canonicalJson({...current.toJson(), 'returnedFiles': payload}),
      );
      final changed = await database.customUpdate(
        'UPDATE local_metadata SET value = ? WHERE metadata_key = ? AND value = ?',
        variables: [
          Variable.withString(canonicalJson(updated.toJson())),
          Variable.withString(metadataKey),
          Variable.withString(canonicalJson(current.toJson())),
        ],
      );
      if (changed != 1) {
        throw const LocalRecordConflict('Media request changed.');
      }
      return updated;
    });
  }

  /// Records references to already retained, scoped attachment manifests. This
  /// does not copy or verify file bytes; the retaining/adopting service does so.
  Future<LocalMediaPickerRequest> retainResults({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
    required List<String> attachmentIds,
  }) async {
    final ids = List<String>.unmodifiable(attachmentIds);
    _validateAttachments(ids);
    return database.transaction(() async {
      final current = await _matchingRequest(
        request,
        organizationId,
        ownerId,
        includeResults: false,
      );
      if (current.retainedAttachmentIds != null) {
        if (canonicalJson(current.retainedAttachmentIds) !=
            canonicalJson(ids)) {
          throw const LocalRecordConflict('Retained media results changed.');
        }
        return current;
      }
      if (current.returnedFiles != null &&
          current.returnedFiles!.length != ids.length) {
        throw const LocalRecordConflict('Not all returned media was retained.');
      }
      for (final id in ids) {
        final row =
            await (database.select(database.localRecords)..where(
                  (r) =>
                      r.organizationId.equals(organizationId) &
                      r.ownerId.equals(ownerId) &
                      r.domain.equals(LocalAttachmentStore.domain) &
                      r.recordId.equals(id),
                ))
                .getSingleOrNull();
        if (row == null || row.payloadVersion != 1) {
          throw const LocalRecordConflict('Retained media is unavailable.');
        }
      }
      final updated = LocalMediaPickerRequest._decode(
        canonicalJson({...current.toJson(), 'retainedAttachmentIds': ids}),
      );
      final changed = await database.customUpdate(
        'UPDATE local_metadata SET value = ? WHERE metadata_key = ? AND value = ?',
        variables: [
          Variable.withString(canonicalJson(updated.toJson())),
          Variable.withString(metadataKey),
          Variable.withString(canonicalJson(current.toJson())),
        ],
      );
      if (changed != 1) {
        throw const LocalRecordConflict('Media request changed.');
      }
      return updated;
    });
  }

  /// Explicit cancellation/discard only. Files are not deleted here.
  Future<void> cancel({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
    Future<void> Function()? beforeCancel,
  }) => _finish(
    request: request,
    organizationId: organizationId,
    ownerId: ownerId,
    commit: beforeCancel ?? () async {},
  );

  /// Run only SQL adoption work against this same database. Its mutations and
  /// request acknowledgment commit together. Retain files before calling; only
  /// publish caches after this future succeeds. Explicit cancellation uses cancel; route disposal must never acknowledge
  /// or cancel a request automatically.
  Future<T> consume<T>({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
    required Future<T> Function() commit,
  }) async {
    if (request.retainedAttachmentIds == null) {
      throw const LocalRecordConflict('Media results have not been retained.');
    }
    return _finish(
      request: request,
      organizationId: organizationId,
      ownerId: ownerId,
      commit: commit,
    );
  }

  Future<T> _finish<T>({
    required LocalMediaPickerRequest request,
    required String organizationId,
    required String ownerId,
    required Future<T> Function() commit,
  }) => database.transaction(() async {
    await _matchingRequest(request, organizationId, ownerId);
    final result = await commit();
    final removed = await database.customUpdate(
      'DELETE FROM local_metadata WHERE metadata_key = ? AND value = ?',
      variables: [
        Variable.withString(metadataKey),
        Variable.withString(canonicalJson(request.toJson())),
      ],
    );
    if (removed != 1) {
      throw const LocalRecordConflict('Media request changed during adoption.');
    }
    return result;
  });

  Future<LocalMediaPickerRequest> _matchingRequest(
    LocalMediaPickerRequest request,
    String organizationId,
    String ownerId, {
    bool includeResults = true,
  }) async {
    if (request.organizationId != organizationId ||
        request.ownerId != ownerId) {
      throw const LocalRecordConflict('Media request scope changed.');
    }
    final current = await _read();
    final expected = request.toJson();
    final actual = current?.toJson();
    if (!includeResults) {
      expected.remove('retainedAttachmentIds');
      expected.remove('returnedFiles');
      actual?.remove('retainedAttachmentIds');
      actual?.remove('returnedFiles');
    }
    if (current == null || canonicalJson(actual) != canonicalJson(expected)) {
      throw const LocalRecordConflict('Media request changed.');
    }
    return current;
  }

  Future<LocalMediaPickerRequest?> _read() async {
    final rows = await database
        .customSelect(
          'SELECT value FROM local_metadata WHERE metadata_key = ?',
          variables: [Variable.withString(metadataKey)],
        )
        .get();
    return rows.isEmpty
        ? null
        : LocalMediaPickerRequest._decode(rows.single.read<String>('value'));
  }
}

void _validate(String organization, String owner, String target, int revision) {
  if ([organization, owner, target].any((value) => value.trim().isEmpty) ||
      revision < 1) {
    throw ArgumentError('A media request requires a saved, scoped target.');
  }
}

void _validateAttachments(List<String> ids) {
  if (ids.isEmpty ||
      ids.toSet().length != ids.length ||
      ids.any((id) => !RegExp(r'^attachment-[a-f0-9]{32}$').hasMatch(id))) {
    throw ArgumentError(
      'Media results require unique retained attachment identities.',
    );
  }
}

void _validateReturnedFiles(List<MediaPickerReturnedFile> files) {
  if (files.isEmpty ||
      files.map((file) => file.path).toSet().length != files.length) {
    throw ArgumentError('A native result requires distinct source files.');
  }
}
