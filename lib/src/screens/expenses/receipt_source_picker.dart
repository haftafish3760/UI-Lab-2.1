import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum ReceiptEvidenceKind { photo, pdf }

class ReceiptEvidenceSelection {
  const ReceiptEvidenceSelection({
    required this.path,
    required this.name,
    required this.kind,
    this.evidenceId,
  });

  final String path;
  final String name;
  final ReceiptEvidenceKind kind;
  final String? evidenceId;

  /// Durable identity after Document Intake has retained this source.
  ///
  /// A newly selected file has no durable ID until its draft save succeeds, so
  /// the local path is used only as the temporary in-session identity.
  String get identity => evidenceId ?? path;
}

class ReceiptSourcePicker {
  ReceiptSourcePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<List<ReceiptEvidenceSelection>> capturePhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    return file == null ? const [] : [_fromImage(file)];
  }

  Future<List<ReceiptEvidenceSelection>> choosePhotos() async {
    final files = await _imagePicker.pickMultiImage(requestFullMetadata: false);
    return files.map(_fromImage).toList(growable: false);
  }

  Future<List<ReceiptEvidenceSelection>> chooseFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
      dialogTitle: 'Choose receipt evidence',
    );
    return [
      for (final file in result)
        if (file.path?.trim().isNotEmpty ?? false)
          ReceiptEvidenceSelection(
            path: file.path!.trim(),
            name: file.name,
            kind: file.extension?.toLowerCase() == 'pdf'
                ? ReceiptEvidenceKind.pdf
                : ReceiptEvidenceKind.photo,
          ),
    ];
  }

  ReceiptEvidenceSelection _fromImage(XFile file) => ReceiptEvidenceSelection(
    path: file.path,
    name: file.name,
    kind: ReceiptEvidenceKind.photo,
  );

  static String friendlyError(Object error) {
    if (error is PlatformException &&
        error.message?.trim().isNotEmpty == true) {
      return error.message!.trim();
    }
    return 'The device could not open that receipt source. Please try again.';
  }
}
