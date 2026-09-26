/// New receipt evidence owns an exclusively allocated directory. Historical
/// timestamp/hash identities retain their original flat paths.
String receiptEvidenceRelativePath({
  required String draftFolder,
  required String evidenceId,
  required String extension,
}) {
  if (!RegExp(r'^[a-f0-9]{24}$').hasMatch(draftFolder) ||
      !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(evidenceId) ||
      !{'pdf', 'image'}.contains(extension)) {
    throw const FormatException('Invalid receipt evidence location.');
  }
  final allocation = evidenceId.startsWith('receipt-evidence-')
      ? '$evidenceId/'
      : '';
  return '$draftFolder/$allocation$evidenceId.$extension';
}
