import 'dart:convert';
import '../../data/storage/local_record_command.dart';

/// Opt-in immutable issuance envelope. Domain persistence owns retaining it and
/// its exact artifact through existing record/attachment infrastructure.
/// Draft previews do not automatically create issuance records.
class GeneratedDocumentSnapshot {
  GeneratedDocumentSnapshot({
    required this.definitionVersion,
    required this.templateVersion,
    required this.sourceRecordId,
    required this.sourceRevision,
    required Map<String, Object?> definition,
    required Map<String, Object?> branding,
    required this.createdAt,
    this.artifactReference,
    this.artifactSha256,
  }) : _definitionJson = canonicalJson(definition),
       _brandingJson = canonicalJson(branding) {
    if (definitionVersion.isEmpty ||
        templateVersion.isEmpty ||
        sourceRecordId.isEmpty ||
        sourceRevision < 1 ||
        (artifactReference == null) != (artifactSha256 == null)) {
      throw const FormatException(
        'The document snapshot identity is incomplete.',
      );
    }
  }
  final String definitionVersion, templateVersion, sourceRecordId;
  final int sourceRevision;
  final DateTime createdAt;
  final String? artifactReference, artifactSha256;
  final String _definitionJson, _brandingJson;
  Map<String, Object?> get definition =>
      Map<String, Object?>.from(jsonDecode(_definitionJson) as Map);
  Map<String, Object?> get branding =>
      Map<String, Object?>.from(jsonDecode(_brandingJson) as Map);
  Map<String, Object?> toJson() => {
    'definitionVersion': definitionVersion,
    'templateVersion': templateVersion,
    'sourceRecordId': sourceRecordId,
    'sourceRevision': sourceRevision,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'definition': definition,
    'branding': branding,
    'artifactReference': artifactReference,
    'artifactSha256': artifactSha256,
  };
}
