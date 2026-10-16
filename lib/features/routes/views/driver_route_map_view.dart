import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/routes/maps/route_map_geometry.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

class DriverRouteMapView extends ConsumerStatefulWidget {
  const DriverRouteMapView({
    required this.route,
    required this.roadRoute,
    @visibleForTesting this.mapForTesting,
    super.key,
  });

  final DriverRoute route;
  final RoadRoute roadRoute;
  final Widget? mapForTesting;

  @override
  ConsumerState<DriverRouteMapView> createState() => _DriverRouteMapViewState();
}

class _DriverRouteMapViewState extends ConsumerState<DriverRouteMapView> {
  GoogleMapController? _controller;
  DeviceLocation? _initialDeviceLocation;
  bool _cameraWasFitted = false;
  String? _locationError;

  List<({DriverRouteStop stop, LatLng position})> get _mappedStops {
    return widget.route.stops
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
    unawaited(_loadInitialDeviceLocation());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackedLocation = ref.watch(
      driverTrackingStatusProvider.select((status) => status.lastLocation),
    );
    final deviceLocation = trackedLocation ?? _initialDeviceLocation;
    final stops = _mappedStops;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de mi ruta')),
      body: stops.isEmpty
          ? _MapUnavailableBody(error: _locationError)
          : LayoutBuilder(
              builder: (context, constraints) {
                final initialTarget = _initialTarget(stops, deviceLocation);
                return Stack(
                  children: [
                    Positioned.fill(
                      child:
                          widget.mapForTesting ??
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: initialTarget,
                              zoom: 14.5,
                            ),
                            markers: _markers(stops, deviceLocation),
                            polylines: _polylines(),
                            mapToolbarEnabled: false,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            trafficEnabled: false,
                            indoorViewEnabled: false,
                            rotateGesturesEnabled: false,
                            padding: EdgeInsets.only(
                              bottom: constraints.maxHeight * 0.18,
                            ),
                            onMapCreated: (controller) {
                              _controller = controller;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _fitCamera(stops, deviceLocation);
                                }
                              });
                            },
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
                            onPressed: deviceLocation == null
                                ? _loadInitialDeviceLocation
                                : () => _centerOnDevice(deviceLocation),
                            tooltip: 'Centrar en mi ubicación',
                            icon: const Icon(Icons.my_location),
                          ),
                        ),
                      ),
                    ),
                    _RouteMapSheet(
                      route: widget.route,
                      roadRoute: widget.roadRoute,
                      locationError: _locationError,
                    ),
                  ],
                );
              },
            ),
    );
  }

  LatLng _initialTarget(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) {
    final next = widget.route.nextStop;
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
    return LatLng(deviceLocation!.latitude, deviceLocation.longitude);
  }

  Set<Marker> _markers(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) {
    final next = widget.route.nextStop;
    final markers = <Marker>{
      for (final entry in stops)
        Marker(
          markerId: MarkerId(
            'stop-${entry.stop.order}-${entry.stop.requestId}-${entry.stop.type}',
          ),
          position: entry.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isNextStop(entry.stop, next)
                ? BitmapDescriptor.hueRed
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
      markers.add(
        Marker(
          markerId: const MarkerId('driver-current-position'),
          position: LatLng(deviceLocation.latitude, deviceLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Tu posición'),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    final points = routePolylinePoints(widget.route);
    if (points.isEmpty) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('initial-road-route'),
        points: points,
        color: Theme.of(context).colorScheme.primary,
        width: 6,
      ),
    };
  }

  bool _isNextStop(DriverRouteStop stop, DriverRouteStop? next) {
    return next != null &&
        stop.requestId == next.requestId &&
        stop.type == next.type &&
        stop.order == next.order;
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
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _locationError = failure.message);
    }
  }

  Future<void> _centerOnDevice(DeviceLocation location) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
  }

  Future<void> _fitCamera(
    List<({DriverRouteStop stop, LatLng position})> stops,
    DeviceLocation? deviceLocation,
  ) async {
    if (_cameraWasFitted || _controller == null) return;
    final points = [
      ...stops.map((entry) => entry.position),
      if (deviceLocation != null)
        LatLng(deviceLocation.latitude, deviceLocation.longitude),
    ];
    if (points.length == 1) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(points.single, 15.5),
      );
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
    await _controller!.animateCamera(
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
    required this.locationError,
  });

  final DriverRoute route;
  final RoadRoute roadRoute;
  final String? locationError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final next = route.nextStop;
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.68,
      snap: true,
      snapSizes: const [0.3, 0.68],
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
                    next == null ? 'Ruta actual' : 'Próxima parada',
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
                      '${next.actionLabel} · ${next.requestNumber}',
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
                  const SizedBox(height: AppSpacing.md),
                  _MapInfoRow(
                    icon: route.map.showRoute
                        ? Icons.route_outlined
                        : Icons.location_on_outlined,
                    text: route.map.showRoute
                        ? 'Trazado vial inicial disponible.'
                        : 'Se muestran ubicaciones, sin unirlas como ruta vial.',
                  ),
                  if (locationError case final error?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(icon: Icons.location_off_outlined, text: error),
                  ],
                  if (roadRoute.motorcycleWarning case final warning?
                      when warning.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _MapInfoRow(
                      icon: Icons.two_wheeler_outlined,
                      text: warning,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'El mapa no cambia el estado de tus solicitudes.',
                    style: Theme.of(context).textTheme.bodySmall,
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
