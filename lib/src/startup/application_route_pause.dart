import 'package:flutter/widgets.dart';

/// Blocks native route pops while application services are being drained.
/// Registration follows routes, never persisted IDs or a particular layout.
class ApplicationRoutePause extends NavigatorObserver
    implements PopEntry<Object?> {
  final _routes = <ModalRoute<dynamic>>{};
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(true);

  void setPaused(bool paused) => canPopNotifier.value = !paused;

  void _register(Route<dynamic>? route) {
    if (route is ModalRoute && _routes.add(route)) route.registerPopEntry(this);
  }

  void _unregister(Route<dynamic>? route) {
    if (route is ModalRoute && _routes.remove(route)) {
      route.unregisterPopEntry(this);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _register(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _unregister(oldRoute);
    _register(newRoute);
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {}
  @override
  void onPopInvoked(bool didPop) {}

  void dispose() {
    for (final route in _routes.toList()) {
      _unregister(route);
    }
    canPopNotifier.dispose();
  }
}
