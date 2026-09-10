import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A versioned domain payload. Form drafts are deliberately a separate type
/// of storage and never become confirmed records through autosave.
class LocalRecordWrite {
  LocalRecordWrite({
    required this.domain,
    required this.recordId,
    required this.ownerId,
    required this.expectedRevision,
    required Map<String, Object?> payload,
    this.payloadVersion = 1,
  }) : payloadJson = canonicalJson(payload) {
    if ([domain, recordId, ownerId].any((value) => value.trim().isEmpty) ||
        expectedRevision < 0 ||
        payloadVersion < 1) {
      throw ArgumentError('A record needs identity and valid versions.');
    }
  }

  final String domain;
  final String recordId;
  final String ownerId;
  final int expectedRevision;
  final int payloadVersion;
  final String payloadJson;
  int get nextRevision => expectedRevision + 1;

  Map<String, Object?> toJson() => {
    'domain': domain,
    'recordId': recordId,
    'ownerId': ownerId,
    'expectedRevision': expectedRevision,
    'payloadVersion': payloadVersion,
    'payload': jsonDecode(payloadJson),
  };
}

class LocalRecordConflict implements Exception {
  const LocalRecordConflict(this.message);
  final String message;
  @override
  String toString() => message;
}

String canonicalJson(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

String payloadDigest(String value) =>
    sha256.convert(utf8.encode(value)).toString();
