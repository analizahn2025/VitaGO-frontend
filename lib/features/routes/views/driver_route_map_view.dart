import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/widgets/driver_request_actions.dart';
import 'package:vitago_app/features/routes/maps/driver_marker_icons.dart';
import 'package:vitago_app/features/routes/maps/route_map_geometry.dart';
import 'package:vitago_app/features/routes/maps/route_polyline_progress.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

class DriverRouteMapView extends ConsumerStatefulWidget {
  const DriverRouteMapView({
    required this.route,
    required this.roadRoute,
    this.canCalculate = false,
    this.profile,
    @visibleForTesting this.mapForTesting,
    @visibleForTesting this.mapBuilderForTesting,
    super.key,
  });

  final DriverRoute route;
  final RoadRoute roadRoute;
  final bool canCalculate;
  final UserProfile? profile;
  final Widget? mapForTesting;
  final Widget Function(GoogleMap map)? mapBuilderForTesting;

  @override
  ConsumerState<DriverRouteMapView> createState() => _DriverRouteMapViewState();
}

class _DriverRouteMapViewState extends ConsumerState<DriverRouteMapView> {
  GoogleMapController? _controller;
  DeviceLocation? _initialDeviceLocation;
  late DriverRoute _route;
  late RoadRoute _roadRoute;
  bool _cameraWasFitted = false;
  bool _showFreshCalculation = false;
  bool _calculating = false;
  String? _locationError;
  String? _calculationError;
  String? _routeError;
  bool _refreshingRoute = false;
  DriverRouteStop? _selectedStop;
  LatLng? _lastMapTarget;
  DriverMarkerIcons? _markerIcons;
  Future<DriverMarkerIcons>? _markerIconsRequest;
  final _polylineProgress = RoutePolylineProgress();
  bool _followingDevice = true;
  bool _followScheduled = false;
  LatLng? _lastFollowTarget;
  final _mapPointers = <int, Offset>{};
  double _sheetExtent = 0.36;

  DeviceLocation? get _deviceLocation =>
      ref.read(driverTrackingStatusProvider).lastLocation ??
      _initialDeviceLocation;

  List<({DriverRouteStop stop, LatLng position})> get _mappedStops {
    return _route.stops
        .map((stop) {
          final position = routeLocationPosition(stop.location);
          return position == null ? null : (stop: stop, position: position);
        })
        .whereType<({DriverRouteStop stop, LatLng position})>()
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _roadRoute = widget.roadRoute;
    _selectedStop = _currentStop(_route, _roadRoute);
    _lastMapTarget =
        routeLocationPosition(_selectedStop?.location) ??
        _mappedStops.firstOrNull?.position;
    unawaited(_loadInitialDeviceLocation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = DriverMarkerIcons.load(
      color: Theme.of(context).colorScheme.primary,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    if (identical(request, _markerIconsRequest)) return;
    _markerIconsRequest = request;
    unawaited(_loadMarkerIcons(request));
  }

  Future<void> _loadMarkerIcons(Future<DriverMarkerIcons> request) async {
    try {
      final icons = await request;
      if (!mounted || !identical(request, _markerIconsRequest)) return;
      setState(() => _markerIcons = icons);
    } catch (error) {
      debugPrint(
        '[VitaGo] map: no se pudo cargar el marcador (${error.runtimeType}).',
      );
    }
  }

  DriverRouteStop? _currentStop(DriverRoute route, RoadRoute road) =>
      route.stops
          .where(
            (stop) =>
                stop.requestId == route.flow?.requestId &&
                stop.type == route.flow?.stopType,
          )
          .firstOrNull ??
      route.nextStop ??
      route.stops.firstOrNull;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftCanOperate =
        ref.watch(activeShiftControllerProvider).value?.canOperate != false;
    final trackedLocation = ref.watch(
      driverTrackingStatusProvider.select((status) => status.lastLocation),
    );
    final deviceLocation = trackedLocation ?? _initialDeviceLocation;
    ref.listen(
      driverTrackingStatusProvider.select((status) => status.lastLocation),
      (_, next) {
        if (next != null) _scheduleFollow();
      },
    );
    final stops = _mappedStops;
    final profile = widget.profile;
    if (profile != null) {
      ref.listen(myRouteProvider, (_, next) {
        final refreshed = next.value;
        if (refreshed == null ||
            next.isLoading ||
            next.hasError ||
            _refreshingRoute ||
            identical(refreshed, _route)) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final current = mounted ? ref.read(myRouteProvider) : null;
          if (mounted &&
              !_refreshingRoute &&
              current != null &&
              !current.isLoading &&
              !current.hasError &&
              identical(current.value, refreshed)) {
            _applyRoute(refreshed);
          }
        });
      });
    }
    final selected = _selectedStop;
    final service = profile != null && selected != null
        ? ref.watch(requestControllerProvider(selected.requestId))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de mi ruta'),
        actions: [
          IconButton(
            onPressed: _refreshingRoute || _calculating ? null : _refreshRoute,
            tooltip: 'Actualizar ruta y servicio',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final initialTarget = _initialTarget(stops, deviceLocation);
          return Stack(
            children: [
              Positioned.fill(
                child:
                    (_route.map.showMap || _route.stops.isEmpty) &&
                        initialTarget != null
                    ? widget.mapForTesting ??
                          _mapSurface(
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: initialTarget,
                                zoom: deviceLocation == null ? 14.5 : 16.5,
                              ),
                              markers: _markers(stops, deviceLocation),
                              polylines: _polylines(deviceLocation),
                              mapToolbarEnabled: false,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              trafficEnabled: false,
                              indoorViewEnabled: false,
                              rotateGesturesEnabled: false,
                              padding: EdgeInsets.only(
                                bottom: constraints.maxHeight * _sheetExtent,
                              ),
                              onMapCreated: (controller) {
                                _controller = controller;
                                _lastFollowTarget = null;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    _fitCamera(_mappedStops, _deviceLocation);
                                  }
                                });
                                WidgetsBinding.instance.scheduleFrame();
                              },
                            ),
                          )
                    : _MapUnavailableBody(
                        error: selected?.routePresentation == 'SOLO_KILOMETROS'
                            ? 'Este envío se controla por kilometraje.'
                            : _locationError,
                      ),
              ),
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: SafeArea(
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: _resumeFollowing,
                      isSelected: _followingDevice,
                      tooltip: _followingDevice
                          ? 'Siguiendo tu ubicación'
                          : 'Volver a seguir mi ubicación',
                      color: Theme.of(context).colorScheme.primary,
                      icon: const Icon(Icons.location_searching),
                      selectedIcon: const Icon(Icons.my_location),
                    ),
                  ),
                ),
              ),
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  final extent = notification.extent;
                  if ((extent - _sheetExtent).abs() > 0.01) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && (extent - _sheetExtent).abs() > 0.01) {
                        setState(() => _sheetExtent = extent);
                      }
                    });
                  }
                  return false;
                },
                child: _RouteMapSheet(
                  route: _route,
                  roadRoute: _roadRoute,
                  canCalculate: widget.canCalculate && shiftCanOperate,
                  calculating: _calculating,
                  busy: _refreshingRoute,
                  selectedStop: selected,
                  servicePanel:
                      profile != null && selected != null && service != null
                      ? _servicePanel(profile, selected, service)
                      : null,
                  routeError: _routeError,
                  onRefresh: _refreshRoute,
                  calculationError: _calculationError,
                  locationError: _locationError,
                  onCalculate: _calculateRoute,
                  segmentMessage: _segmentMessage(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapSurface(GoogleMap map) => Listener(
    key: const Key('driver-map-gestures'),
    onPointerDown: (event) {
      _mapPointers[event.pointer] = event.position;
      if (_mapPointers.length > 1) _pauseFollowing();
    },
    onPointerMove: (event) {
      final start = _mapPointers[event.pointer];
      if (start != null && (event.position - start).distance > 8) {
        _pauseFollowing();
      }
    },
    onPointerUp: (event) => _mapPointers.remove(event.pointer),
    onPointerCancel: (event) => _mapPointers.remove(event.pointer),
    onPointerSignal: (_) => _pauseFollowing(),
    child: widget.mapBuilderForTesting?.call(map) ?? map,
  );

  void _pauseFollowing() {
    if (_followingDevice) setState(() => _followingDevice = false);
  }

  Future<void> _resumeFollowing() async {
    setState(() {
      _followingDevice = true;
      _lastFollowTarget = null;
    });
    if (_deviceLocation == null) {
      await _loadInitialDeviceLocation();
    } else {
      _scheduleFollow();
    }
  }

  void _scheduleFollow() {
    if (!_followingDevice || _controller == null || _followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScheduled = false;
      if (!mounted || !_followingDevice) return;
      final current = _deviceLocation;
      if (current != null) unawaited(_centerOnDevice(current));
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  LatLng? _initialTarget(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) {
    if (_followingDevice && deviceLocation != null) {
      return LatLng(deviceLocation.latitude, deviceLocation.longitude);
    }
    final next = _selectedStop ?? _route.nextStop;
    if (next != null) {
      final match = stops.where(
        (entry) =>
            entry.stop.requestId == next.requestId &&
            entry.stop.type == next.type &&
            entry.stop.order == next.order,
      );
      if (match.isNotEmpty) return match.first.position;
    }
    if (stops.isNotEmpty) return stops.first.position;
    if (deviceLocation != null) {
      return LatLng(deviceLocation.latitude, deviceLocation.longitude);
    }
    return _lastMapTarget;
  }

  Set<Marker> _markers(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) {
    final next = _route.nextStop;
    final markers = <Marker>{
      for (final entry in stops)
        Marker(
          markerId: MarkerId(
            'stop-${entry.stop.order}-${entry.stop.requestId}-${entry.stop.type}',
          ),
          position: entry.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _sameStop(entry.stop, _selectedStop)
                ? BitmapDescriptor.hueRed
                : _isNextStop(entry.stop, next)
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: _isNextStop(entry.stop, next)
                ? 'Próxima · ${entry.stop.title}'
                : '${entry.stop.order}. ${entry.stop.title}',
            snippet: '${entry.stop.actionLabel} · ${entry.stop.requestNumber}',
          ),
        ),
    };
    if (deviceLocation != null) {
      final position = LatLng(
        deviceLocation.latitude,
        deviceLocation.longitude,
      );
      final icons = _markerIcons;
      final heading = driverMarkerHeading(deviceLocation);
      if (icons != null && heading != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('driver-current-heading'),
            position: position,
            icon: icons.heading,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: heading,
            zIndexInt: 9,
          ),
        );
      }
      markers.add(
        Marker(
          markerId: const MarkerId('driver-current-position'),
          position: position,
          icon:
              icons?.mascot ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: icons == null ? const Offset(0.5, 1) : const Offset(0.5, 0.5),
          zIndexInt: 10,
          infoWindow: const InfoWindow(title: 'Tu posición'),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _polylines(DeviceLocation? deviceLocation) {
    if (_selectedStop == null) return const {};
    final segmentId = '${_selectedStop!.requestId}:${_selectedStop!.type}';
    final points = _polylineProgress.remaining(
      segmentId: segmentId,
      points: routePolylinePoints(
        _route,
        roadRoute: _roadRoute,
        showRoute: _route.map.showRoute || _showFreshCalculation,
      ),
      location: deviceLocation,
    );
    if (points.length < 2) return const {};
    return {
      Polyline(
        polylineId: PolylineId(segmentId),
        points: points,
        color: Theme.of(context).colorScheme.primary,
        width: 6,
      ),
    };
  }

  String? _segmentMessage() {
    final stop = _selectedStop;
    if (stop == null) return null;
    if (stop.routePresentation == 'SOLO_KILOMETROS') {
      return 'Envío especial: consulta su información y kilometraje.';
    }
    if (_roadRoute.canUpdateBreakdown) {
      return 'Este cálculo anterior no tiene tramos separados. Puedes actualizarlo manualmente.';
    }
    if (!_roadRoute.breakdownAvailable) return null;
    final segment = _roadRoute.segmentForStop(stop);
    if (segment == null) return 'Tramo no incluido en el cálculo actual';
    if (segment.withoutMovement) {
      return 'Estas dos paradas están en el mismo punto. No requiere desplazamiento.';
    }
    if (routePolylinePoints(
              _route,
              roadRoute: _roadRoute,
              showRoute: _route.map.showRoute || _showFreshCalculation,
            ).length <
            2 &&
        (_route.map.showRoute || _showFreshCalculation)) {
      return 'No hay un trazado disponible para este tramo.';
    }
    return null;
  }

  bool _isNextStop(DriverRouteStop stop, DriverRouteStop? next) {
    return next != null &&
        stop.requestId == next.requestId &&
        stop.type == next.type &&
        stop.order == next.order;
  }

  bool _sameStop(DriverRouteStop stop, DriverRouteStop? other) =>
      other != null &&
      stop.requestId == other.requestId &&
      stop.type == other.type;

  Widget _servicePanel(
    UserProfile profile,
    DriverRouteStop selected,
    AsyncValue<ServiceRequestDetail> service,
  ) {
    return service.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('No fue posible actualizar este servicio.'),
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(requestControllerProvider(selected.requestId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar servicio'),
          ),
        ],
      ),
      data: (request) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                request.number,
                key: const Key('map-selected-service'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              StatusBadge(
                status: request.status,
                label: request.summary.displayStatusLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!_sameStop(selected, _route.nextStop)) ...[
            const Text('Solo consulta. Atiende primero la próxima parada.'),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (request.id == selected.requestId &&
              request.assignedDriverId == _route.driverId)
            DriverRequestActions(
              key: ValueKey('${request.id}-${selected.type}'),
              request: request,
              profile: profile,
              stopType: selected.type,
              flow: _route.flow,
              useModal: true,
              disabled:
                  _refreshingRoute ||
                  _calculating ||
                  service.isLoading ||
                  _routeError != null ||
                  !_sameStop(selected, _route.nextStop),
              onCompleted: _onServiceCompleted,
            )
          else
            const Text('Este servicio ya no está asignado a tu ruta.'),
        ],
      ),
    );
  }

  Future<void> _onServiceCompleted(ServiceRequestDetail updated) async {
    ref.invalidate(driverDeliveryControllerProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
    ref.invalidate(requesterSummaryControllerProvider);
    await _refreshRoute(completedRequest: updated);
  }

  Future<void> _refreshRoute({
    ServiceRequestDetail? completedRequest,
    bool focusSelectedStop = true,
  }) async {
    if (_refreshingRoute) return;
    setState(() {
      _refreshingRoute = true;
      _routeError = null;
    });
    try {
      final refreshed = await ref.refresh(myRouteProvider.future);
      if (!mounted) return;
      _applyRoute(
        refreshed,
        completedRequest: completedRequest,
        focusSelectedStop: focusSelectedStop,
      );
    } on Object {
      if (mounted) {
        setState(() {
          _routeError = completedRequest == null
              ? 'No fue posible actualizar la ruta. Inténtalo nuevamente.'
              : 'El servicio se actualizó. Falta actualizar la ruta.';
        });
      }
    } finally {
      if (mounted) setState(() => _refreshingRoute = false);
    }
  }

  void _applyRoute(
    DriverRoute refreshed, {
    ServiceRequestDetail? completedRequest,
    bool focusSelectedStop = true,
  }) {
    final current = _currentStop(refreshed, refreshed.roadRoute);
    final selected = current;
    setState(() {
      _route = refreshed;
      _routeError = null;
      _roadRoute = refreshed.roadRoute;
      _selectedStop = selected;
      _showFreshCalculation = false;
      _cameraWasFitted = false;
      _lastMapTarget =
          routeLocationPosition(selected?.location) ?? _lastMapTarget;
    });
    if (selected != null) {
      ref.invalidate(requestControllerProvider(selected.requestId));
    }
    if (focusSelectedStop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_followingDevice) return;
        final currentLocation = _deviceLocation;
        if (currentLocation != null) {
          unawaited(_centerOnDevice(currentLocation));
          return;
        }
        final position = routeLocationPosition(_selectedStop?.location);
        if (position != null) {
          unawaited(_moveCamera(CameraUpdate.newLatLngZoom(position, 16)));
        }
      });
    }
  }

  Future<void> _moveCamera(CameraUpdate update) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        await controller.moveCamera(update);
      } else {
        await controller.animateCamera(update);
      }
    } on Object catch (error) {
      // El cierre o recreación nativa del mapa no revierte un servicio confirmado.
      debugPrint('[VitaGo] map: cámara no disponible (${error.runtimeType}).');
    }
  }

  Future<void> _loadInitialDeviceLocation() async {
    try {
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _initialDeviceLocation = location;
        _locationError = null;
      });
      _scheduleFollow();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _locationError = failure.message);
    }
  }

  Future<void> _centerOnDevice(DeviceLocation location) async {
    final target = LatLng(location.latitude, location.longitude);
    if (!_followingDevice || target == _lastFollowTarget) return;
    _lastFollowTarget = target;
    await _moveCamera(CameraUpdate.newLatLngZoom(target, 16.5));
  }

  Future<void> _calculateRoute() async {
    final currentVersion = _route.currentVersion;
    if (_calculating || _refreshingRoute || currentVersion == null) return;
    final updateBreakdown = _roadRoute.canUpdateBreakdown;
    if (updateBreakdown) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Actualizar los tramos?'),
          content: const Text(
            'Esta actualización consume un intento de cálculo y puede consultar Google. No cambia el orden de tus envíos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Actualizar tramos'),
            ),
          ],
        ),
      );
      if (!mounted ||
          confirmed != true ||
          _calculating ||
          _refreshingRoute ||
          _route.currentVersion != currentVersion) {
        return;
      }
    }

    setState(() {
      _calculating = true;
      _calculationError = null;
    });

    try {
      final calculated = await ref
          .read(calculateRouteProvider)
          .calculate(
            CalculateRouteInput(
              currentVersion: currentVersion,
              retry: updateBreakdown || _roadRoute.canRetry,
            ),
          );
      if (!mounted) return;

      final hasFreshPolyline =
          calculated.status == 'CALCULADA' && calculated.breakdownAvailable;
      setState(() {
        _roadRoute = calculated;
        _showFreshCalculation = hasFreshPolyline;
        _cameraWasFitted = false;
      });

      // Es un GET: reconcilia la parada seleccionada sin recalcular otra vez.
      // Si falla, conserva el trazado válido que devolvió el cálculo explícito.
      await _refreshRoute(focusSelectedStop: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitCamera(_mappedStops, _deviceLocation);
      });
    } on AppFailure catch (failure) {
      if (failure.serverCode == 'VERSION_DESACTUALIZADA' ||
          failure.serverCode == 'ITINERARIO_CAMBIO' ||
          failure.serverCode == 'CALCULO_EN_CURSO' ||
          failure.serverCode == 'INTENTO_REEMPLAZADO') {
        await _refreshRoute();
      }
      if (mounted) setState(() => _calculationError = failure.message);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _fitCamera(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) async {
    if (!_followingDevice || _controller == null) return;
    if (deviceLocation != null) {
      await _centerOnDevice(deviceLocation);
      return;
    }
    if (_cameraWasFitted) return;
    final selectedPosition = routeLocationPosition(_selectedStop?.location);
    final linePoints = routePolylinePoints(
      _route,
      roadRoute: _roadRoute,
      showRoute: _route.map.showRoute || _showFreshCalculation,
    );
    final points = [
      ...linePoints,
      ?selectedPosition,
      if (linePoints.isEmpty && selectedPosition == null)
        ...stops.map((entry) => entry.position),
      if (deviceLocation != null &&
          (_route.nextStop == null ||
              (_selectedStop != null &&
                  _sameStop(_selectedStop!, _route.nextStop))))
        LatLng(deviceLocation.latitude, deviceLocation.longitude),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await _moveCamera(CameraUpdate.newLatLngZoom(points.single, 15.5));
      _cameraWasFitted = true;
      return;
    }
    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;
    for (final point in points.skip(1)) {
      minLatitude = minLatitude < point.latitude ? minLatitude : point.latitude;
      maxLatitude = maxLatitude > point.latitude ? maxLatitude : point.latitude;
      minLongitude = minLongitude < point.longitude
          ? minLongitude
          : point.longitude;
      maxLongitude = maxLongitude > point.longitude
          ? maxLongitude
          : point.longitude;
    }
    await _moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLatitude, minLongitude),
          northeast: LatLng(maxLatitude, maxLongitude),
        ),
        72,
      ),
    );
    _cameraWasFitted = true;
  }
}

class _RouteMapSheet extends StatelessWidget {
  const _RouteMapSheet({
    required this.route,
    required this.roadRoute,
    required this.canCalculate,
    required this.calculating,
    required this.busy,
    required this.selectedStop,
    required this.servicePanel,
    required this.routeError,
    required this.onRefresh,
    required this.calculationError,
    required this.locationError,
    required this.onCalculate,
    required this.segmentMessage,
  });

  final DriverRoute route;
  final RoadRoute roadRoute;
  final bool canCalculate;
  final bool calculating;
  final bool busy;
  final DriverRouteStop? selectedStop;
  final Widget? servicePanel;
  final String? routeError;
  final VoidCallback onRefresh;
  final String? calculationError;
  final String? locationError;
  final VoidCallback onCalculate;
  final String? segmentMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final next = selectedStop ?? route.nextStop;
    return DraggableScrollableSheet(
      initialChildSize: 0.36,
      minChildSize: 0.2,
      maxChildSize: 0.82,
      snap: true,
      snapSizes: const [0.36, 0.82],
      builder: (context, scrollController) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: colors.surface,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.surface),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadii.round),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    next == null
                        ? 'Recorrido finalizado'
                        : next.requestId == route.nextStop?.requestId &&
                              next.type == route.nextStop?.type
                        ? 'Próxima parada'
                        : 'Parada seleccionada',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: colors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    next?.title ?? 'No hay paradas pendientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (next != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      servicePanel == null
                          ? '${next.actionLabel} · ${next.requestNumber}'
                          : next.actionLabel,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    if (next.location?.address case final address?
                        when address.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        address,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                  if (servicePanel != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    servicePanel!,
                  ],
                  if (busy) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const LinearProgressIndicator(),
                  ],
                  if (routeError case final error?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(icon: Icons.sync_problem_outlined, text: error),
                    TextButton.icon(
                      onPressed: busy ? null : onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar ruta'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        'Ruta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _RouteStatusChip(status: roadRoute.status),
                    ],
                  ),
                  if (canCalculate &&
                      route.currentVersion != null &&
                      route.map.showMap &&
                      (roadRoute.canCalculate ||
                          roadRoute.canRetry ||
                          roadRoute.canUpdateBreakdown)) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: calculating || busy ? null : onCalculate,
                      icon: calculating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.route_outlined),
                      label: Text(
                        calculating
                            ? 'Calculando recorrido…'
                            : roadRoute.canUpdateBreakdown
                            ? 'Actualizar tramos'
                            : roadRoute.canRetry
                            ? 'Reintentar cálculo'
                            : 'Calcular ruta',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (next != null)
                    Text(
                      '${next.requestNumber} · ${next.actionLabel}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (segmentMessage case final message?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(icon: Icons.info_outline, text: message),
                  ],
                  if (roadRoute.metricsInResponse &&
                      roadRoute.estimatedDistanceMeters != null &&
                      roadRoute.estimatedDurationSeconds != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Estimación del cálculo completo'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _RouteMetricChip(
                          icon: Icons.route_outlined,
                          label:
                              '${(roadRoute.estimatedDistanceMeters! / 1000).toStringAsFixed(1)} km',
                        ),
                        _RouteMetricChip(
                          icon: Icons.schedule_outlined,
                          label:
                              '${(roadRoute.estimatedDurationSeconds! / 60).round()} min estimados',
                        ),
                      ],
                    ),
                  ],
                  if (calculationError case final error?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(icon: Icons.error_outline, text: error),
                  ],
                  if (locationError case final error?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(icon: Icons.location_off_outlined, text: error),
                  ],
                  if (roadRoute.motorcycleWarning case final warning?
                      when warning.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Información del mapa'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(warning),
                        ),
                      ],
                    ),
                  if (roadRoute.attribution case final attribution?
                      when attribution.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      attribution,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RouteStatusChip extends StatelessWidget {
  const _RouteStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'CALCULADA' => ('Ruta calculada', colors.primary),
      'CALCULANDO' => ('Calculando', colors.tertiary),
      'FALLIDA' => ('No disponible', colors.error),
      'ITINERARIO_CAMBIO' => ('Por actualizar', colors.tertiary),
      _ => ('Sin trazado', colors.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RouteMetricChip extends StatelessWidget {
  const _RouteMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MapInfoRow extends StatelessWidget {
  const _MapInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _MapUnavailableBody extends StatelessWidget {
  const _MapUnavailableBody({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 56,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mapa no disponible',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                error ??
                    'La ruta no contiene ubicaciones válidas para mostrar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
