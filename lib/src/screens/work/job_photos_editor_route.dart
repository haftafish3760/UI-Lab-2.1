import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/job_photos_draft_workflow.dart';
import '../../data/work/estimate_photo_media_workflow.dart';
import '../../data/work/models/work_models.dart';
import '../../shared/native_media_picker_scope.dart';
import 'estimate_site_photos_screen.dart';

Future<WorkRecord?> openJobPhotosEditor(
  BuildContext context, {
  required String recordId,
  JobPhotosDraftController? selected,
}) async {
  JobPhotosDraftController? controller = selected;
  try {
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    final coordinator = NativeMediaPickerScope.maybeOf(context);
    if (work == null || coordinator == null) {
      throw StateError(
        'Photo storage is unavailable. Reopen the app and try again.',
      );
    }
    controller ??= await work.openJobPhotosDraft(recordId);
    work.validateJobPhotosHandoff(controller, recordId);
    if (!context.mounted) return null;
    final form = controller;
    WorkRecord? result;
    await Navigator.of(context).push<List<WorkSitePhoto>>(
      MaterialPageRoute(
        builder: (_) => EstimateSitePhotosScreen(
          screenTitle: 'Job photos',
          initialDay: DateTime.now(),
          initialPhotos: form.input.photos.photos,
          recoveryInput: form.input.photos,
          draftSession: form.session,
          mediaWorkflow: work.jobPhotoMediaWorkflow(
            draft: form.session,
            coordinator: coordinator,
          ),
          onDraftChanged: form.updatePhotos,
          onConfirm: (_) async {
            result = await form.confirm();
            if (result == null) {
              throw StateError(
                work.failureMessage ?? 'Photos could not be saved. Try again.',
              );
            }
            return true;
          },
        ),
      ),
    );
    return result;
  } finally {
    await controller?.session.close();
  }
}
