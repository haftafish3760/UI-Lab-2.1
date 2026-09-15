import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'native_notification_gateway.dart';

class FlutterLocalNotificationGateway implements NativeNotificationGateway {
  FlutterLocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? nowUtc,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const _androidSoundChannelId = 'maintainiac_reminders';
  static const _androidSilentChannelId = 'maintainiac_reminders_silent';
  static const _windowsGuid = '8de1327f-1183-4b56-824a-f6f335c9ac6e';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _nowUtc;
  final _tapController = StreamController<String>.broadcast();
  bool _initialized = false;
  String? _launchPayload;

  @override
  Stream<String> get tappedPayloads => _tapController.stream;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  @override
  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    timezone_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_maintainiac'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentBadge: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentBadge: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'Tame Your Biz',
          appUserModelId: 'Maintainiac.Operations',
          guid: _windowsGuid,
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch?.notificationResponse?.payload;
    }
    _initialized = true;
  }

  @override
  Future<NativeNotificationPermissionState> permissionState() async {
    await initialize();
    if (!_supported) return NativeNotificationPermissionState.unsupported;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled ?? false
          ? NativeNotificationPermissionState.granted
          : NativeNotificationPermissionState.notGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options?.isEnabled ?? false
          ? NativeNotificationPermissionState.granted
          : NativeNotificationPermissionState.notGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options?.isEnabled ?? false
          ? NativeNotificationPermissionState.granted
          : NativeNotificationPermissionState.notGranted;
    }
    return NativeNotificationPermissionState.granted;
  }

  @override
  Future<NativeNotificationPermissionState> requestPermission({
    required bool sound,
  }) async {
    await initialize();
    if (!_supported) return NativeNotificationPermissionState.unsupported;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: sound);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: sound);
    }
    return permissionState();
  }

  @override
  Future<Set<int>> pendingNotificationIds() async {
    await initialize();
    if (!_supported) return const {};
    final requests = await _plugin.pendingNotificationRequests();
    return requests.map((request) => request.id).toSet();
  }

  @override
  Future<NativeNotificationPostResult> post(
    NativeNotificationRequest request,
  ) async {
    await initialize();
    if (!_supported) {
      throw UnsupportedError('Native notifications are not supported.');
    }
    final details = _details(request.playSound);
    if (!request.scheduledAtUtc.isAfter(_nowUtc())) {
      await _plugin.show(
        id: request.platformId,
        title: request.title,
        body: request.body,
        payload: request.payload,
        notificationDetails: details,
      );
      return NativeNotificationPostResult.shownNow;
    }
    await _plugin.zonedSchedule(
      id: request.platformId,
      title: request.title,
      body: request.body,
      payload: request.payload,
      scheduledDate: timezone.TZDateTime.from(
        request.scheduledAtUtc,
        timezone.UTC,
      ),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return NativeNotificationPostResult.scheduled;
  }

  NotificationDetails _details(bool playSound) => NotificationDetails(
    android: AndroidNotificationDetails(
      playSound ? _androidSoundChannelId : _androidSilentChannelId,
      playSound ? 'Expense reminders' : 'Silent expense reminders',
      channelDescription: 'Upcoming and recurring business expense reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
      enableVibration: playSound,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: playSound,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: playSound,
    ),
    windows: WindowsNotificationDetails(
      audio: playSound
          ? WindowsNotificationAudio.preset(
              sound: WindowsNotificationSound.reminder,
            )
          : WindowsNotificationAudio.silent(),
    ),
  );

  @override
  Future<void> cancel(int platformId) async {
    await initialize();
    if (_supported) await _plugin.cancel(id: platformId);
  }

  @override
  Future<String?> takeLaunchPayload() async {
    await initialize();
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      _tapController.add(payload);
    }
  }
}
