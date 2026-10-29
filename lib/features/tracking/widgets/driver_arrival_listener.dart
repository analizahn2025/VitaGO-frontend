import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/navigation/route_activity_observer.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/views/driver_request_stage_presenter.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_arrivals_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/storage/arrival_presentation_store.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/services/special_measurement_sync.dart';

/// Presents only server-confirmed arrivals, in foreground, over a safe screen.
/// The same modal used by manual service actions preserves the map underneath.
class DriverArrivalListener extends ConsumerStatefulWidget {
  const DriverArrivalListener({
    required this.profile,
    required this.child,
    @visibleForTesting this.mapViewBuilderForTesting,
    super.key,
  });

  final UserProfile profile;
  final Widget child;
  final Widget Function(DriverRoute route)? mapViewBuilderForTesting;

  @override
  ConsumerState<DriverArrivalListener> createState() =>
      _DriverArrivalListenerState();
}

class _DriverArrivalListenerState extends ConsumerState<DriverArrivalListener>
    with WidgetsBindingObserver {
  late final RouteActivityObserver _routes;
  final _shownThisSession = <String>{};
  bool _foreground = true;
  bool _pending = true;
  bool _needsFreshRoute = false;
  bool _working = false;
  bool _scheduled = false;
  String? _activeShiftId;
  int _recoveryRevision = 0;
  String? _notificationSignature;

  bool get _eligible =>
      widget.profile.isDriver &&
      widget.profile.can(AppPermissions.updateRequestStatus) &&
      widget.profile.can(AppPermissions.registerDriverLocation);

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _routes = ref.read(routeActivityObserverProvider);
    _routes.changes.addListener(_schedule);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _recover();
  }

  @override
  void dispose() {
    _routes.changes.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = _eligible
        ? ref.watch(activeShiftControllerProvider).value
        : null;
    if (_eligible && shift != null) {
      if (_activeShiftId != shift.id) {
        _activeShiftId = shift.id;
        _pending = true;
        _needsFreshRoute = true;
      }
      ref.listen(driverArrivalsProvider, (_, _) {
        ref.invalidate(driverDeliveryControllerProvider);
        ref.invalidate(driverNotificationsControllerProvider);
        ref.invalidate(unreadNotificationCountControllerProvider);
        _recover();
      });
      ref.listen(driverNotificationsControllerProvider, (_, next) {
        if (next.isLoading || next.hasError || next.value == null) return;
        final signature = next.value!.items.map((item) => item.id).join('|');
        final changed =
            _notificationSignature != null &&
            signature != _notificationSignature;
        _notificationSignature = signature;
        if (changed) _recover();
      });
      ref.listen(myRouteProvider, (_, next) {
        if (next.value?.flow != null && !next.isLoading && !next.hasError) {
          _pending = true;
          _schedule();
        }
      });
      ref.listen(
        driverTrackingStatusProvider.select((state) => state.lastSyncedAt),
        (previous, next) {
          final flow = ref.read(myRouteProvider).value?.flow;
          final driverId = ref.read(myRouteProvider).value?.driverId;
          if (next != previous && driverId != null) {
            unawaited(ref.read(specialMeasurementSyncProvider).flush(driverId));
          }
          if (next != previous &&
              const {'ASSIGNED', 'PICKED_UP'}.contains(flow?.status)) {
            _recover();
          }
        },
      );
      ref.listen(locationServiceEnabledProvider, (_, next) {
        if (next.value == true && !next.isLoading && !next.hasError) {
          _schedule();
        }
      });
      _schedule();
    } else {
      _activeShiftId = null;
    }
    return widget.child;
  }

  void _recover() {
    _recoveryRevision++;
    _pending = true;
    _needsFreshRoute = true;
    _schedule();
  }

  void _schedule() {
    if (!mounted ||
        _scheduled ||
        _working ||
        !_pending ||
        !_eligible ||
        !_foreground ||
        !_routes.canPresentArrival) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_presentPending());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _canPresent(String shiftId) {
    if (!mounted || !_eligible || !_foreground || !_routes.canPresentArrival) {
      return false;
    }
    final gps = ref.read(locationServiceEnabledProvider);
    return !gps.isLoading &&
        !gps.hasError &&
        gps.value == true &&
        ref.read(activeShiftControllerProvider).value?.id == shiftId &&
        ref.read(activeShiftControllerProvider).value?.isOperational == true;
  }

  Future<void> _presentPending() async {
    final shift = ref.read(activeShiftControllerProvider).value;
    if (_working || shift == null || !_canPresent(shift.id)) return;
    _working = true;
    _pending = false;
    try {
      final recoveryRevision = _recoveryRevision;
      final route = _needsFreshRoute
          ? await ref.refresh(myRouteProvider.future)
          : await ref.read(myRouteProvider.future);
      if (recoveryRevision == _recoveryRevision) _needsFreshRoute = false;
      if (!mounted) return;
      final arrival = route.currentArrival;
      unawaited(ref.read(specialMeasurementSyncProvider).flush(route.driverId));
      final next = route.nextStop;
      final flow = route.flow;
      if (flow?.isAutomatic != true || !_canPresent(shift.id)) return;
      if (flow!.hasNoServices) {
        if (_routes.currentRouteName == 'driver-route-map' &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }
      if (route.shiftId != shift.id ||
          next?.requestId != flow.requestId ||
          next?.type != flow.stopType ||
          next?.requestStatus != flow.status) {
        return;
      }
      if (flow.screen == 'MAPA') {
        final key = 'map:${shift.id}:${flow.requestId}:${flow.stopType}';
        if (_routes.currentRouteName != 'driver-route-map' &&
            !_shownThisSession.contains(key)) {
          _shownThisSession.add(key);
          unawaited(
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: 'driver-route-map'),
                builder: (_) =>
                    widget.mapViewBuilderForTesting?.call(route) ??
                    DriverRouteMapView(
                      route: route,
                      roadRoute: route.roadRoute,
                      profile: widget.profile,
                      canCalculate: widget.profile.can(
                        AppPermissions.calculateRoute,
                      ),
                    ),
              ),
            ),
          );
        }
        return;
      }
      final target =
          flow.photoTargetStatus ??
          (flow.canFinishSpecial ? 'AT_DESTINATION' : null);
      if (target == null) return;
      final eventId =
          arrival?.isSupported == true &&
              arrival?.requestId == flow.requestId &&
              arrival?.status == flow.status
          ? arrival!.eventId
          : 'flow:${shift.id}:${flow.requestId}:${flow.status}';
      final scope =
          '${ref.read(appConfigProvider).apiBaseUri}|${widget.profile.user.id}';
      final memoryKey = '$scope|$eventId';
      if (_shownThisSession.contains(memoryKey)) return;
      final history = ref.read(arrivalPresentationStoreProvider);
      if (await history.wasShown(scope, eventId)) return;
      if (!mounted) return;
      final request = await ref.refresh(
        requestControllerProvider(flow.requestId!).future,
      );
      if (!mounted) return;
      if (request.id != flow.requestId ||
          request.status != flow.status ||
          request.assignedDriverId != route.driverId) {
        return;
      }
      final needsPhoto = flow.photoTargetStatus != null;
      if (needsPhoto && !widget.profile.can(AppPermissions.createEvidence)) {
        return;
      }
      if (!_canPresent(shift.id)) {
        _pending = true;
        return;
      }
      _shownThisSession.add(memoryKey);
      final presentation = presentDriverRequestStage(
        context,
        request: request,
        targetStatus: target,
        needsPhoto: needsPhoto,
      );
      try {
        await history.markShown(scope, eventId);
      } on Object {
        // Keep the in-memory guard; a storage problem must not cancel service UI.
        debugPrint('[VitaGo] arrival: unable to persist shown event');
      }
      final updated = await presentation;
      if (!mounted || updated == null) return;
      ref.invalidate(requestControllerProvider(updated.id));
      ref.invalidate(
        requestEvidenceControllerProvider((ownerId: updated.id, page: 1)),
      );
      ref.invalidate(driverDeliveryControllerProvider);
      ref.invalidate(driverNotificationsControllerProvider);
      ref.invalidate(unreadNotificationCountControllerProvider);
      ref.invalidate(requesterSummaryControllerProvider);
      ref.invalidate(myRouteProvider);
      await ref.read(myRouteProvider.future);
    } on Object catch (error) {
      _pending = false;
      if (mounted && _foreground) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              error is AppFailure ? error.message : 'No fue posible recuperar la llegada. Puedes actualizar la ruta e intentarlo nuevamente.',
            ),
            action: SnackBarAction(label: 'Reintentar', onPressed: _recover),
          ),
        );
      }
    } finally {
      _working = false;
      if (mounted) _schedule();
    }
  }
}
