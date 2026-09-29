/// A reference to retained bytes, never an external path or proof by itself.
/// Access and integrity must be checked against the scoped attachment store.
class WorkApprovalEvidence {
  const WorkApprovalEvidence({required this.attachmentId, required this.name});
  final String attachmentId;
  final String name;

  Map<String, Object?> toJson() => {'attachmentId': attachmentId, 'name': name};

  factory WorkApprovalEvidence.fromJson(Map<String, Object?> json) {
    final id = json['attachmentId'] as String;
    final name = json['name'] as String;
    if (!RegExp(r'^attachment-[a-f0-9]+$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 255 ||
        name.contains('/') ||
        name.contains('\\') ||
        name.runes.any((c) => c < 32 || c == 127)) {
      throw const FormatException('Invalid approval attachment reference.');
    }
    return WorkApprovalEvidence(attachmentId: id, name: name);
  }
}
