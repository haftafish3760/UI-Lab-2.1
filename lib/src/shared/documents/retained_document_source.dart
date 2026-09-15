import 'document_source.dart';
import '../../data/storage/local_attachment_store.dart';

/// Features supply their authorized company/owner selection and relationship.
/// The shared adapter reuses verified files and returns the exact original bytes.
DocumentSource retainedDocumentSource({
  required LocalAttachmentStore attachments,
  required String organizationId,
  required Set<String> ownerIds,
  required String attachmentId,
  required String fileName,
  required Future<void> Function() authorize,
  DocumentOrigin origin = DocumentOrigin.uploadedOriginal,
}) => DocumentSource(
  origin: origin,
  fileName: fileName,
  authorize: authorize,
  readBytes: () async {
    final files = await attachments.verifiedFiles(
      organizationId: organizationId,
      ownerIds: ownerIds,
      attachmentIds: {attachmentId},
    );
    return files.single.readAsBytes();
  },
);
