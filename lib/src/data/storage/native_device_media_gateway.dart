import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'local_media_picker_request.dart';
import 'native_media_picker_coordinator.dart';
import '../receipts/receipt_camera_gateway.dart';

class NativeDeviceMediaGateway implements JournaledNativeMediaPickerGateway {
  NativeDeviceMediaGateway({
    ImagePicker? picker,
    bool? useAndroidJournal,
    ReceiptCameraGateway? receiptCamera,
    this.receiptCameraGuides,
  }) : _picker = picker ?? ImagePicker(),
       _receiptCamera = receiptCamera ?? ReceiptCameraGateway(),
       _useAndroidJournal = useAndroidJournal ?? Platform.isAndroid;
  final bool _useAndroidJournal;
  static const _journal = MethodChannel('maintainiac/native_media_journal');
  final ImagePicker _picker;
  final ReceiptCameraGateway _receiptCamera;
  final Future<Map<String, Object?>> Function(LocalMediaPickerRequest)?
  receiptCameraGuides;

  bool _journals(LocalMediaPickerRequest request) =>
      _useAndroidJournal && request.source != MediaPickerSource.files;

  @override
  Future<List<MediaPickerReturnedFile>> pickForRequest(
    LocalMediaPickerRequest request,
  ) async {
    if (_journals(request)) {
      await _journal.invokeMethod<void>('begin', request.requestId);
      if (request.source == MediaPickerSource.camera &&
          request.destination == MediaPickerDestination.receipt) {
        return _receiptCamera.capture(
          request.requestId,
          resolveGuides: receiptCameraGuides == null
              ? null
              : () => receiptCameraGuides!(request),
        );
      }
    }
    return pick(request.source, request.destination);
  }

  @override
  Future<List<MediaPickerReturnedFile>> recoverForRequest(
    LocalMediaPickerRequest request,
  ) async {
    if (!_journals(request)) return recover();
    final result = await _journal.invokeMapMethod<String, Object?>(
      'recover',
      request.requestId,
    );
    if (result == null ||
        result['paths'] is! List ||
        result['needsLegacyRecovery'] is! bool) {
      throw StateError('Native media recovery response is invalid.');
    }
    final recovered = (result['paths'] as List).cast<String>();
    if (recovered.any((path) => path.trim().isEmpty)) {
      throw StateError('Native media recovery path is invalid.');
    }
    if (recovered.isNotEmpty) {
      return [
        for (final path in recovered)
          MediaPickerReturnedFile(path: path, name: paths.basename(path)),
      ];
    }
    // Native preparation binds legacy cache import to this saved request.
    // The adapted plugin retains those bytes before clearing the old cache.
    if (result['needsLegacyRecovery'] == true) return recover();
    return const [];
  }

  @override
  Future<void> abandonRequest(LocalMediaPickerRequest request) async {
    if (_journals(request)) {
      await _journal.invokeMethod<void>('abandon', request.requestId);
    }
  }

  @override
  Future<void> acknowledgeRetained(LocalMediaPickerRequest request) async {
    if (!_journals(request)) return;
    if (request.retainedAttachmentIds == null) {
      throw StateError('Media must be retained before native acknowledgement.');
    }
    await _journal.invokeMethod<void>('acknowledge', request.requestId);
  }

  @override
  bool get supportsRecovery => Platform.isAndroid;

  @override
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  ) async {
    if (source == MediaPickerSource.files) {
      final approval =
          destination == MediaPickerDestination.estimateApproval ||
          destination == MediaPickerDestination.quoteApproval;
      final result = await FilePicker.pickFiles(
        type: approval
            ? FileType.custom
            : destination == MediaPickerDestination.receipt
            ? FileType.custom
            : FileType.image,
        allowedExtensions: approval
            ? const ['eml', 'msg', 'pdf', 'txt', 'jpg', 'jpeg', 'png', 'heic']
            : destination == MediaPickerDestination.receipt
            ? const ['pdf', 'jpg', 'jpeg', 'png', 'heic']
            : null,
        dialogTitle: approval
            ? 'Choose customer approval evidence'
            : destination == MediaPickerDestination.receipt
            ? 'Choose receipt evidence'
            : 'Choose job-site photos',
      );
      if (result.any((file) => file.path?.trim().isEmpty ?? true)) {
        throw StateError(
          'The selected file is unavailable. Choose the file again.',
        );
      }
      return [
        for (final file in result)
          MediaPickerReturnedFile(path: file.path!, name: file.name),
      ];
    }
    if (source == MediaPickerSource.camera) {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        requestFullMetadata: false,
      );
      return image == null ? const [] : [_file(image)];
    }
    return (await _picker.pickMultiImage(
      requestFullMetadata: false,
    )).map(_file).toList();
  }

  @override
  Future<List<MediaPickerReturnedFile>> recover() async {
    if (!supportsRecovery) return const [];
    final result = await _picker.retrieveLostData();
    if (result.exception case final exception?) throw exception;
    return (result.files ?? const <XFile>[]).map(_file).toList();
  }

  MediaPickerReturnedFile _file(XFile file) =>
      MediaPickerReturnedFile(path: file.path, name: file.name);
}
