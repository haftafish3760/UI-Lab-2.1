import 'dart:io';

import 'local_attachment_store.dart';
import 'local_media_picker_request.dart';
import 'local_record_command.dart';
import 'serialized_async_actions.dart';

/// One coordinator instance per application. Native callbacks first checkpoint
/// their returned files; this service retries slow retention from that checkpoint.
/// It does not invoke the picker or attach results to a business record.
class MediaPickerResultRetention {
  MediaPickerResultRetention({
    required this.requests,
    required this.attachments,
  }) {
    if (!identical(requests.database, attachments.database)) {
      throw ArgumentError('Media retention must use one database.');
    }
  }
  final LocalMediaPickerRequestStore requests;
  final LocalAttachmentStore attachments;
  final _actions = SerializedAsyncActions();

  Future<LocalMediaPickerRequest> retain({
    required String requestId,
    required String organizationId,
    required String ownerId,
  }) => _actions.run(() async {
    final request = await requests.findFor(
      organizationId: organizationId,
      ownerId: ownerId,
    );
    if (request == null || request.requestId != requestId) {
      throw const LocalRecordConflict('Media request is unavailable.');
    }
    if (request.retainedAttachmentIds != null) return request;
    final sources = request.returnedFiles;
    if (sources == null) {
      throw const LocalRecordConflict('No native result was checkpointed.');
    }
    final ids = <String>[];
    for (final source in sources) {
      final file = await attachments.retain(
        source: File(source.path),
        organizationId: organizationId,
        ownerId: ownerId,
      );
      ids.add(file.uri.pathSegments.last.split('.').first);
    }
    return requests.retainResults(
      request: request,
      organizationId: organizationId,
      ownerId: ownerId,
      attachmentIds: ids,
    );
  });
}
