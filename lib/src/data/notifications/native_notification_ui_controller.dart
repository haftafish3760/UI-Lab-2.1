import 'dart:async';

import 'package:flutter/widgets.dart';

import 'native_notification_delivery_coordinator.dart';
import 'native_notification_gateway.dart';

enum NativeNotificationUiPhase { loading, ready, requesting, failed }

class NativeNotificationUiController extends ChangeNotifier {
  NativeNotificationUiController(
    this._gateway,
    this._coordinator,
    this._locale,
    this._sourceReady,
  );

  final NativeNotificationGateway _gateway;
  final NativeNotificationDeliveryCoordinator _coordinator;
  final Locale Function() _locale;
  Future<void> _sourceReady;
  Future<void> _serial = Future<void>.value();
  NativeNotificationUiPhase _phase = NativeNotificationUiPhase.loading;
  NativeNotificationPermissionState _permission =
      NativeNotificationPermissionState.unsupported;
  String? _failureMessage;
  bool _permissionWasRequested = false;
  bool _disposed = false;

  NativeNotificationUiPhase get phase => _phase;
  NativeNotificationPermissionState get permission => _permission;
  String? get failureMessage => _failureMessage;
  bool get permissionWasRequested => _permissionWasRequested;
  bool get isSupported =>
      _permission != NativeNotificationPermissionState.unsupported;
  bool get isGranted =>
      _permission == NativeNotificationPermissionState.granted;

  Future<void> load() => _enqueue(() async {
    _phase = NativeNotificationUiPhase.loading;
    _failureMessage = null;
    _notify();
    try {
      await _sourceReady;
      await _gateway.initialize();
      _permission = await _gateway.permissionState();
      if (_permission == NativeNotificationPermissionState.granted) {
        await _coordinator.synchronize(
          asOfUtc: DateTime.now().toUtc(),
          locale: _locale(),
        );
      }
      _phase = NativeNotificationUiPhase.ready;
    } on Object {
      _phase = NativeNotificationUiPhase.failed;
      _failureMessage = 'Device reminders could not be updated.';
    }
    _notify();
  });

  Future<bool> enable({required bool sound}) async {
    var enabled = false;
    await _enqueue(() async {
      _phase = NativeNotificationUiPhase.requesting;
      _failureMessage = null;
      _notify();
      try {
        _permissionWasRequested = true;
        _permission = await _gateway.requestPermission(sound: sound);
        if (_permission == NativeNotificationPermissionState.granted) {
          await _sourceReady;
          await _coordinator.synchronize(
            asOfUtc: DateTime.now().toUtc(),
            locale: _locale(),
          );
          enabled = true;
        }
        _phase = NativeNotificationUiPhase.ready;
      } on Object {
        _phase = NativeNotificationUiPhase.failed;
        _failureMessage = 'Device reminders could not be updated.';
      }
      _notify();
    });
    return enabled;
  }

  void sourceChanged(Future<void> sourceReady) {
    _sourceReady = sourceReady;
    if (_permission != NativeNotificationPermissionState.granted) return;
    unawaited(
      _enqueue(() async {
        try {
          await _sourceReady;
          await _coordinator.synchronize(
            asOfUtc: DateTime.now().toUtc(),
            locale: _locale(),
          );
          _phase = NativeNotificationUiPhase.ready;
          _failureMessage = null;
        } on Object {
          _phase = NativeNotificationUiPhase.failed;
          _failureMessage = 'Device reminders could not be updated.';
        }
        _notify();
      }),
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _serial.then((_) => action());
    _serial = next.catchError((Object _) {});
    return next;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class NativeNotificationUiScope
    extends InheritedNotifier<NativeNotificationUiController> {
  const NativeNotificationUiScope({
    required NativeNotificationUiController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static NativeNotificationUiController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NativeNotificationUiScope>()
          ?.notifier;
}
