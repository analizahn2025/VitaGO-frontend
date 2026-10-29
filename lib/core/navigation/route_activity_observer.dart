import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routeActivityObserverProvider = Provider<RouteActivityObserver>(
  (ref) => RouteActivityObserver(),
);

/// Defers automatic arrival UI while a form, camera flow or dialog is open.
class RouteActivityObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];
  final changes = ValueNotifier<int>(0);
  String? get currentRouteName => _routes.lastOrNull?.settings.name;

  bool get canPresentArrival =>
      _routes.isNotEmpty &&
      _routes.last is PageRoute &&
      const {
        '/',
        'home',
        'request-detail',
        'driver-route-map',
      }.contains(_routes.last.settings.name);

  void _changed() => scheduleMicrotask(() => changes.value++);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
    _changed();
  }
}
