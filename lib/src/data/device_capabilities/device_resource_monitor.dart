import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'device_workload_service.dart';

/// App lifetime observer. No periodic idle polling and no sensor activation.
class DeviceResourceMonitor with WidgetsBindingObserver {
  DeviceResourceMonitor(this.service, {this.events});
  final DeviceWorkloadService service;
  final Stream<Object?>? events;
  static const _channel = EventChannel('app.device_capability_events');
  StreamSubscription<Object?>? _subscription;
  bool _started = false;
  Timer? _debounce;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscription = (events ?? _channel.receiveBroadcastStream()).listen(
      (event) {
        if (!_started) return;
        if (event == 'memory') service.signalMemoryPressure();
        // Leading refresh: continuous events must not postpone protection.
        if (_debounce != null) return;
        unawaited(service.refresh());
        _debounce = Timer(const Duration(milliseconds: 250), () {
          _debounce = null;
          if (_started) unawaited(service.refresh());
        });
      },
      onError: (Object _) {
        // Unsupported event bridge does not disable preflight/active polling.
        if (_started) unawaited(service.refresh());
      },
    );
    unawaited(service.refresh());
  }

  @override
  void didHaveMemoryPressure() {
    if (_started) service.signalMemoryPressure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_started && state == AppLifecycleState.resumed) {
      unawaited(service.refresh());
    }
  }

  Future<void> dispose() async {
    if (!_started) return;
    _started = false;
    _debounce?.cancel();
    _debounce = null;
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
  }
}
