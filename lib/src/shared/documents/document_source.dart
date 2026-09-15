import 'dart:typed_data';

enum DocumentOrigin { generated, uploadedOriginal, derivedPreview }

/// Existing feature/session authorization is deliberately required, not replaced
/// by document-specific roles. Uploaded bytes are never sent through a renderer.
class DocumentSource {
  const DocumentSource({
    required this.origin,
    required this.fileName,
    required this.authorize,
    required this.readBytes,
  });
  final DocumentOrigin origin;
  final String fileName;
  final Future<void> Function() authorize;
  final Future<Uint8List> Function() readBytes;
  Future<Uint8List> open() async {
    await authorize();
    final bytes = await readBytes();
    await authorize();
    if (bytes.isEmpty) throw const FormatException('The document is empty.');
    return bytes;
  }
}
