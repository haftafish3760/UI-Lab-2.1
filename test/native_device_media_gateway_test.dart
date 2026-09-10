import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/native_device_media_gateway.dart';

final class _PickedFile extends PlatformFile {
  _PickedFile(this.uri, this.name);
  @override
  final Uri uri;
  @override
  final String name;
  @override
  XFile get xFile => XFile(uri.toFilePath());
  @override
  Future<int> length() => xFile.length();
  @override
  Future<Uint8List> readAsBytes() => xFile.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      xFile.openRead().map(Uint8List.fromList);
}

class _Picker extends FilePickerPlatform {
  List<PlatformFile> result = [];
  FileType? requestedType;
  List<String>? extensions;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    requestedType = type;
    extensions = allowedExtensions;
    return result;
  }
}

void main() {
  late FilePickerPlatform previous;
  late _Picker picker;
  setUp(() {
    previous = FilePickerPlatform.instance;
    picker = _Picker();
    FilePickerPlatform.instance = picker;
  });
  tearDown(() => FilePickerPlatform.instance = previous);

  test(
    'receipt picker preserves exact readable paths, names and selection order',
    () async {
      final root = await Directory.systemTemp.createTemp('picker-path-');
      try {
        final first = File('${root.path}/receipt.pdf ');
        final second = File('${root.path}/other.png');
        await first.writeAsBytes([1, 2, 3]);
        await second.writeAsBytes([4, 5]);
        picker.result = [
          _PickedFile(first.uri, 'receipt.pdf '),
          _PickedFile(second.uri, 'other.png'),
        ];
        final result = await NativeDeviceMediaGateway().pick(
          MediaPickerSource.files,
          MediaPickerDestination.receipt,
        );
        expect(result.map((file) => file.path), [first.path, second.path]);
        expect(result.map((file) => file.name), ['receipt.pdf ', 'other.png']);
        expect(await File(result.first.path).readAsBytes(), [1, 2, 3]);
        expect(picker.requestedType, FileType.custom);
        expect(picker.extensions, containsAll(['pdf', 'png', 'jpg']));
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'unavailable file in a mixed result fails instead of partial success or cancellation',
    () async {
      picker.result = [
        _PickedFile(Uri.file('/tmp/selected.png'), 'selected.png'),
        _PickedFile(Uri.parse('content://provider/unavailable'), 'receipt.pdf'),
      ];
      await expectLater(
        NativeDeviceMediaGateway().pick(
          MediaPickerSource.files,
          MediaPickerDestination.receipt,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'explicit cancellation stays empty and estimate picker requests images',
    () async {
      final result = await NativeDeviceMediaGateway().pick(
        MediaPickerSource.files,
        MediaPickerDestination.estimate,
      );
      expect(result, isEmpty);
      expect(picker.requestedType, FileType.image);
      expect(picker.extensions, isNull);
    },
  );
}
