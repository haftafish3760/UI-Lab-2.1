import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_delivery_coordinator.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/screens/expenses/device_reminder_status.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  test('loading native reminders never requests permission', () async {
    final harness = _ControllerHarness();
    addTearDown(harness.dispose);

    await harness.controller.load();

    expect(harness.gateway.initializeCount, 1);
    expect(harness.gateway.permissionCheckCount, 1);
    expect(harness.gateway.permissionRequestCount, 0);
    expect(
      harness.controller.permission,
      NativeNotificationPermissionState.notGranted,
    );
    expect(harness.controller.permissionWasRequested, isFalse);
  });

  testWidgets(
    'initialization failure is visible and retry does not request permission',
    (tester) async {
      final harness = _ControllerHarness();
      addTearDown(harness.dispose);
      harness.gateway.failInitialize = true;
      await harness.controller.load();
      await tester.pumpWidget(
        NativeNotificationUiScope(
          controller: harness.controller,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: DeviceReminderStatus(requestSound: true),
            ),
          ),
        ),
      );
      expect(find.text('Device reminders unavailable'), findsOneWidget);
      expect(find.text('Retry device reminders'), findsOneWidget);
      harness.gateway.failInitialize = false;
      await tester.tap(find.text('Retry device reminders'));
      await tester.pumpAndSettle();
      expect(harness.controller.phase, NativeNotificationUiPhase.ready);
      expect(harness.gateway.permissionRequestCount, 0);
      expect(find.text('Enable device reminders'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'launch payload waits for initialization and is returned once',
    () async {
      final harness = _ControllerHarness();
      addTearDown(harness.dispose);
      harness.gateway.initializeGate = Completer<void>();
      harness.gateway.launchPayload = 'notification-123';
      final opening = harness.controller.load();
      final launch = harness.controller.takeLaunchPayload();
      await Future<void>.delayed(Duration.zero);
      expect(harness.gateway.launchReads, 0);
      harness.gateway.initializeGate!.complete();
      await opening;
      expect(await launch, 'notification-123');
      expect(await harness.controller.takeLaunchPayload(), isNull);
      expect(harness.gateway.permissionRequestCount, 0);
    },
  );

  testWidgets('the labeled Enable action is the only permission trigger', (
    tester,
  ) async {
    final harness = _ControllerHarness();
    addTearDown(harness.dispose);
    await harness.controller.load();

    await tester.pumpWidget(
      NativeNotificationUiScope(
        controller: harness.controller,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DeviceReminderStatus(requestSound: true)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('device-reminder-status')),
      findsOneWidget,
    );
    expect(harness.gateway.permissionRequestCount, 0);

    await tester.tap(find.byKey(const ValueKey('enable-device-reminders')));
    await tester.pumpAndSettle();

    expect(harness.gateway.permissionRequestCount, 1);
    expect(harness.gateway.lastRequestedSound, isTrue);
    expect(harness.controller.isGranted, isTrue);
    expect(find.byKey(const ValueKey('device-reminder-status')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ControllerHarness {
  _ControllerHarness()
    : gateway = _FakeNativeNotificationGateway(),
      service = AuthorizedNotificationService(
        FileNotificationRepository.transient(),
      ) {
    coordinator = NativeNotificationDeliveryCoordinator(
      service,
      demoNotificationPublisherPermissions(),
      gateway,
    );
    controller = NativeNotificationUiController(
      gateway,
      coordinator,
      () => const Locale('en', 'US'),
      Future<void>.value(),
    );
  }

  final _FakeNativeNotificationGateway gateway;
  final AuthorizedNotificationService service;
  late final NativeNotificationDeliveryCoordinator coordinator;
  late final NativeNotificationUiController controller;

  void dispose() {
    controller.dispose();
    gateway.dispose();
  }
}

class _FakeNativeNotificationGateway implements NativeNotificationGateway {
  NativeNotificationPermissionState permission =
      NativeNotificationPermissionState.notGranted;
  bool failInitialize = false;
  Completer<void>? initializeGate;
  String? launchPayload;
  int launchReads = 0;
  int initializeCount = 0;
  int permissionCheckCount = 0;
  int permissionRequestCount = 0;
  bool? lastRequestedSound;
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get tappedPayloads => _taps.stream;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
    if (failInitialize) throw StateError('injected initialization failure');
    await initializeGate?.future;
  }

  @override
  Future<NativeNotificationPermissionState> permissionState() async {
    permissionCheckCount += 1;
    return permission;
  }

  @override
  Future<NativeNotificationPermissionState> requestPermission({
    required bool sound,
  }) async {
    permissionRequestCount += 1;
    lastRequestedSound = sound;
    permission = NativeNotificationPermissionState.granted;
    return permission;
  }

  @override
  Future<Set<int>> pendingNotificationIds() async => const {};

  @override
  Future<NativeNotificationPostResult> post(
    NativeNotificationRequest request,
  ) async => NativeNotificationPostResult.scheduled;

  @override
  Future<void> cancel(int platformId) async {}

  @override
  Future<String?> takeLaunchPayload() async {
    launchReads++;
    final value = launchPayload;
    launchPayload = null;
    return value;
  }

  void dispose() => _taps.close();
}
