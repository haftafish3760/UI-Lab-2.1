import 'package:flutter/material.dart';

/// Returns a module to its landing route without bypassing editor decisions.
class ModuleLandingNavigation extends NavigatorObserver {
  final key = GlobalKey<NavigatorState>();
  final _routes = <Route<dynamic>>[];
  final _exits = <Route<dynamic>, Future<void> Function()>{};

  void registerExit(Route<dynamic> route, Future<void> Function() exit) =>
      _exits[route] = exit;
  void unregisterExit(Route<dynamic> route) => _exits.remove(route);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _exits.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      didPop(route, previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      _exits.remove(oldRoute);
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
  }

  Future<bool> returnToLanding() async {
    while (_routes.length > 1) {
      final route = _routes.last;
      final exit = _exits[route];
      if (exit != null) {
        await exit();
      } else {
        await key.currentState?.maybePop();
      }
      // A cancelled choice, failed save, or another PopScope keeps its route.
      // Never force-pop it or continue on to another module.
      if (_routes.isNotEmpty && identical(_routes.last, route)) return false;
    }
    return true;
  }
}

class ModuleLandingScope extends InheritedWidget {
  const ModuleLandingScope({
    required this.navigation,
    required super.child,
    super.key,
  });
  final ModuleLandingNavigation navigation;
  static ModuleLandingNavigation? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ModuleLandingScope>()
      ?.navigation;
  @override
  bool updateShouldNotify(ModuleLandingScope oldWidget) =>
      !identical(navigation, oldWidget.navigation);
}
