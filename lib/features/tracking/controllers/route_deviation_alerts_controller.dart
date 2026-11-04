import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/tracking/models/route_deviation_alert.dart';

final routeDeviationAlertProvider =
    NotifierProvider<RouteDeviationAlertsController, RouteDeviationAlert?>(
      RouteDeviationAlertsController.new,
    );

class RouteDeviationAlertsController extends Notifier<RouteDeviationAlert?> {
  final _closedIds = <String>{};

  @override
  RouteDeviationAlert? build() => null;

  bool receivedFromGps(List<RouteDeviationAlert> alerts) {
    if (alerts.isEmpty) return false;
    final previous = state;
    final closed = alerts.where((alert) => !alert.isActive).map((a) => a.id);
    _closedIds.addAll(closed);
    if (_closedIds.length > 128) {
      _closedIds.removeAll(_closedIds.take(_closedIds.length - 128).toList());
    }
    if (state != null && _closedIds.contains(state!.id)) state = null;
    for (final alert in alerts) {
      if (!alert.isActive || _closedIds.contains(alert.id)) continue;
      if (state?.id != alert.id || state?.message != alert.message) {
        state = alert;
      }
    }
    return !identical(state, previous);
  }

  void synchronizeFromRoute(RouteDeviationAlert? alert) {
    if (alert == null || !alert.isActive) {
      state = null;
      return;
    }
    if (_closedIds.contains(alert.id)) return;
    if (state?.id != alert.id || state?.message != alert.message) {
      state = alert;
    }
  }
}
