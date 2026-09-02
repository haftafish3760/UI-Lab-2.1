import 'package:flutter/foundation.dart';

enum NativeNotificationPermissionState { unsupported, notGranted, granted }

enum NativeNotificationPostResult { scheduled, shownNow }

@immutable
class NativeNotificationRequest {
  NativeNotificationRequest({
    required this.platformId,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.payload,
    required DateTime scheduledAtUtc,
    required this.playSound,
  }) : scheduledAtUtc = scheduledAtUtc.toUtc();

  final int platformId;
  final String notificationId;
  final String title;
  final String body;
  final String payload;
  final DateTime scheduledAtUtc;
  final bool playSound;
}

abstract interface class NativeNotificationGateway {
  Stream<String> get tappedPayloads;

  Future<void> initialize();

  Future<NativeNotificationPermissionState> permissionState();

  Future<NativeNotificationPermissionState> requestPermission({
    required bool sound,
  });

  Future<Set<int>> pendingNotificationIds();

  Future<NativeNotificationPostResult> post(NativeNotificationRequest request);

  Future<void> cancel(int platformId);

  Future<String?> takeLaunchPayload();
}

class UnsupportedNativeNotificationGateway
    implements NativeNotificationGateway {
  const UnsupportedNativeNotificationGateway();

  @override
  Stream<String> get tappedPayloads => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<NativeNotificationPermissionState> permissionState() async =>
      NativeNotificationPermissionState.unsupported;

  @override
  Future<NativeNotificationPermissionState> requestPermission({
    required bool sound,
  }) async => NativeNotificationPermissionState.unsupported;

  @override
  Future<Set<int>> pendingNotificationIds() async => const {};

  @override
  Future<NativeNotificationPostResult> post(
    NativeNotificationRequest request,
  ) => throw UnsupportedError('Native notifications are not supported.');

  @override
  Future<void> cancel(int platformId) async {}

  @override
  Future<String?> takeLaunchPayload() async => null;
}
