import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';

class FakeNativeMediaGateway implements NativeMediaPickerGateway {
  @override
  bool supportsRecovery = true;
  int picks = 0;
  int recoveries = 0;
  Future<List<MediaPickerReturnedFile>> Function()? onPick;
  List<MediaPickerReturnedFile> lost = [];
  @override
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  ) async {
    picks++;
    return onPick == null ? [] : await onPick!();
  }

  @override
  Future<List<MediaPickerReturnedFile>> recover() async {
    recoveries++;
    final files = lost;
    lost = [];
    return files;
  }
}

class FakeJournaledNativeMediaGateway extends FakeNativeMediaGateway
    implements JournaledNativeMediaPickerGateway {
  late Future<void> Function(LocalMediaPickerRequest) onAcknowledge;
  String? requestId;
  int acknowledgements = 0;
  Future<void> Function()? onAbandon;
  @override
  Future<void> abandonRequest(LocalMediaPickerRequest request) async {
    await onAbandon?.call();
  }

  @override
  Future<List<MediaPickerReturnedFile>> pickForRequest(
    LocalMediaPickerRequest request,
  ) async {
    requestId = request.requestId;
    return lost;
  }

  @override
  Future<List<MediaPickerReturnedFile>> recoverForRequest(
    LocalMediaPickerRequest request,
  ) async {
    expect(request.requestId, requestId);
    return lost;
  }

  @override
  Future<void> acknowledgeRetained(LocalMediaPickerRequest request) async {
    acknowledgements++;
    expect(request.requestId, requestId);
    await onAcknowledge(request);
  }
}
