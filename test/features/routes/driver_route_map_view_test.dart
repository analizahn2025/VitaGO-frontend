import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/routes/maps/driver_marker_icons.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/models/road_route_segment.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';

void main() {
  testWidgets(
    'el mapa interno conserva su panel en retrato, paisaje y texto grande',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const stop = DriverRouteStop(
        order: 1,
        requestId: 'request-id',
        requestNumber: 'SOL-1',
        priority: 'NORMAL',
        modality: 'ENTRE_SUCURSALES',
        requestStatus: 'ASSIGNED',
        type: 'RECOLECCION',
        routePresentation: 'MAPA',
        location: RouteLocation(
          id: 'location-id',
          name: 'Sucursal Centro',
          address: 'Dirección de prueba',
          latitude: '14.072300',
          longitude: '-87.192100',
        ),
      );
      const roadRoute = RoadRoute(
        status: 'NO_CONFIGURADA',
        provider: 'GOOGLE_MAPS',
        attribution: 'Google Maps',
        motorcycleWarning: 'Aviso beta para motocicletas.',
        includesCompletedSegments: false,
        metricsInResponse: false,
      );
      const route = DriverRoute(
        driverId: 'driver-id',
        orderType: 'ASIGNACION',
        routeCalculated: false,
        stops: [stop],
        nextStop: stop,
        map: RouteMapConfiguration(
          mode: 'INTEGRADO',
          provider: 'GOOGLE_MAPS',
          showMap: true,
          showRoute: false,
          allowsExternalNavigation: false,
        ),
        roadRoute: roadRoute,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceLocationServiceProvider.overrideWithValue(
              const _FakeDeviceLocationService(),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const DriverRouteMapView(
              route: route,
              roadRoute: roadRoute,
              mapForTesting: ColoredBox(
                key: Key('map-surface'),
                color: Colors.blueGrey,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map-surface')), findsOneWidget);
      expect(find.text('Mapa de mi ruta'), findsOneWidget);
      expect(find.text('Próxima parada'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('motocicletas'), findsNothing);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map-surface')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mueve el motorista y conserva el trazado sin recalcular ni cerrar',
    (tester) async {
      const stop = DriverRouteStop(
        order: 1,
        requestId: 'request-id',
        requestNumber: 'SOL-1',
        priority: 'NORMAL',
        modality: 'ENTRE_SUCURSALES',
        requestStatus: 'ASSIGNED',
        type: 'RECOLECCION',
        routePresentation: 'MAPA',
        location: RouteLocation(
          id: 'location-id',
          name: 'Sucursal Centro',
          address: 'Dirección de prueba',
          latitude: '14.072300',
          longitude: '-87.192100',
        ),
      );
      const pendingRoad = RoadRoute(
        status: 'PENDIENTE',
        provider: 'GOOGLE_MAPS',
        includesCompletedSegments: false,
        metricsInResponse: false,
      );
      const calculatedRoad = RoadRoute(
        status: 'CALCULADA',
        provider: 'GOOGLE_MAPS',
        attribution: 'Google Maps',
        encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        breakdownAvailable: true,
        currentSegmentId: 'request-id:RECOLECCION',
        segments: [
          RoadRouteSegment(
            id: 'request-id:RECOLECCION',
            requestId: 'request-id',
            requestNumber: 'SOL-1',
            shipmentOrder: 1,
            stopOrder: 1,
            stopType: 'RECOLECCION',
            requestStatus: 'ASSIGNED',
            isNext: true,
            origin: RouteSegmentPoint(
              latitude: '14.071',
              longitude: '-87.191',
              type: 'GPS',
            ),
            destination: RouteSegmentPoint(
              latitude: '14.072300',
              longitude: '-87.192100',
              locationId: 'location-id',
            ),
            withoutMovement: false,
            encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
          ),
        ],
        includesCompletedSegments: false,
        metricsInResponse: true,
        estimatedDistanceMeters: 5400,
        estimatedDurationSeconds: 900,
      );
      const initialRoute = DriverRoute(
        driverId: 'driver-id',
        currentVersion: 1,
        orderType: 'ASIGNACION',
        routeCalculated: false,
        stops: [stop],
        nextStop: stop,
        map: RouteMapConfiguration(
          mode: 'INTEGRADO',
          provider: 'GOOGLE_MAPS',
          showMap: true,
          showRoute: false,
          allowsExternalNavigation: false,
        ),
        roadRoute: pendingRoad,
        flow: DriverRouteFlow(
          mode: 'AUTOMATICO',
          screen: 'MAPA',
          requestId: 'request-id',
          stopType: 'RECOLECCION',
          status: 'ASSIGNED',
          segmentId: 'request-id:RECOLECCION',
        ),
      );
      const refreshedRoute = DriverRoute(
        driverId: 'driver-id',
        currentVersion: 1,
        orderType: 'ASIGNACION',
        routeCalculated: true,
        stops: [stop],
        nextStop: stop,
        map: RouteMapConfiguration(
          mode: 'INTEGRADO',
          provider: 'GOOGLE_MAPS',
          showMap: true,
          showRoute: true,
          allowsExternalNavigation: false,
        ),
        roadRoute: calculatedRoad,
        flow: DriverRouteFlow(
          mode: 'AUTOMATICO',
          screen: 'MAPA',
          requestId: 'request-id',
          stopType: 'RECOLECCION',
          status: 'ASSIGNED',
          segmentId: 'request-id:RECOLECCION',
        ),
      );
      final repository = _FakeRoutesRepository(
        route: refreshedRoute,
        calculatedRoad: calculatedRoad,
      );
      GoogleMap? currentMap;
      final theme = AppTheme.forMode(AppMode.corporate);
      final icons = await tester.runAsync(
        () => DriverMarkerIcons.load(
          color: theme.colorScheme.primary,
          devicePixelRatio: tester.view.devicePixelRatio,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routesRepositoryProvider.overrideWithValue(repository),
            deviceLocationServiceProvider.overrideWithValue(
              const _FakeDeviceLocationService(),
            ),
          ],
          child: MaterialApp(
            theme: theme,
            home: DriverRouteMapView(
              route: initialRoute,
              roadRoute: pendingRoad,
              canCalculate: true,
              mapBuilderForTesting: (map) {
                currentMap = map;
                return const ColoredBox(
                  key: Key('map-surface'),
                  color: Colors.blueGrey,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mapContext = tester.element(find.byType(DriverRouteMapView));
      await tester.runAsync(
        () => DriverMarkerIcons.load(
          color: Theme.of(mapContext).colorScheme.primary,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(mapContext),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        currentMap!.initialCameraPosition.target,
        const LatLng(14.071, -87.191),
      );
      final camera = _RecordingMapController();
      currentMap!.onMapCreated!(camera);
      await tester.pumpAndSettle();
      expect(camera.updates.last, [
        'newLatLngZoom',
        [14.071, -87.191],
        16.5,
      ]);
      expect(find.byTooltip('Siguiendo tu ubicación'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.text('Calcular ruta'), findsOneWidget);
      await tester.tap(find.text('Calcular ruta'));
      await tester.pumpAndSettle();

      expect(repository.calculateCalls, 1);
      expect(find.text('Ruta calculada'), findsOneWidget);
      expect(find.text('Calcular ruta'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      final originalLine = currentMap!.polylines.single;
      final originalStops = currentMap!.markers
          .where((marker) => marker.markerId.value.startsWith('stop-'))
          .map(
            (marker) => (marker.markerId, marker.position, marker.infoWindow),
          )
          .toList();
      final surface = tester.element(find.byKey(const Key('map-surface')));
      final tracking = ProviderScope.containerOf(
        tester.element(find.byType(DriverRouteMapView)),
      ).read(driverTrackingStatusProvider.notifier);

      for (final latitude in [14.0723, 14.0733, 14.0743]) {
        tracking.reportError('Sin conexión: puntos guardados para reenviar.');
        tracking.setCurrentLocation(
          DeviceLocation(
            latitude: latitude,
            longitude: -87.1921,
            recordedAt: DateTime.utc(2026, 10, 23),
            headingDegrees: 90,
            speedMetersPerSecond: 5,
          ),
        );
        await tester.pump();
        final driver = currentMap!.markers.singleWhere(
          (marker) => marker.markerId.value == 'driver-current-position',
        );
        expect(driver.position, LatLng(latitude, -87.1921));
        expect(camera.updates.last, [
          'newLatLngZoom',
          [latitude, -87.1921],
          16.5,
        ]);
        expect(driver.icon, same(icons!.mascot));
        expect(driver.anchor, const Offset(0.5, 0.5));
        expect(driver.flat, isFalse);
        expect(driver.rotation, 0);
        expect(driver.infoWindow.title, 'Tu posición');
        final heading = currentMap!.markers.singleWhere(
          (marker) => marker.markerId.value == 'driver-current-heading',
        );
        expect(heading.position, driver.position);
        expect(heading.icon, same(icons.heading));
        expect(heading.rotation, 90);
        expect(heading.flat, isTrue);
        expect(heading.anchor, driver.anchor);
        expect(heading.zIndexInt, lessThan(driver.zIndexInt));
        expect(currentMap!.polylines.single.points, originalLine.points);
        expect(
          currentMap!.markers
              .where((marker) => marker.markerId.value.startsWith('stop-'))
              .map(
                (marker) =>
                    (marker.markerId, marker.position, marker.infoWindow),
              ),
          originalStops,
        );
        expect(
          tester.element(find.byKey(const Key('map-surface'))),
          same(surface),
        );
      }
      tracking.setCurrentLocation(
        DeviceLocation(
          latitude: 14.0743,
          longitude: -87.1921,
          recordedAt: DateTime.utc(2026, 10, 23),
          headingDegrees: 180,
          speedMetersPerSecond: 0,
        ),
      );
      await tester.pump();
      expect(
        currentMap!.markers.where(
          (marker) => marker.markerId.value == 'driver-current-heading',
        ),
        isEmpty,
      );
      expect(repository.calculateCalls, 1);
      expect(repository.getCalls, 1);
      expect(currentMap!.mapToolbarEnabled, isFalse);

      // A map tap leaves following active; dragging pauses only the camera.
      await tester.tapAt(const Offset(140, 100));
      await tester.pump();
      expect(find.byTooltip('Siguiendo tu ubicación'), findsOneWidget);
      await tester.dragFrom(const Offset(140, 100), const Offset(70, 0));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Volver a seguir mi ubicación'), findsOneWidget);
      final pausedCount = camera.updates.length;
      tracking.setCurrentLocation(
        DeviceLocation(
          latitude: 14.0753,
          longitude: -87.1921,
          recordedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      await tester.pump();
      expect(camera.updates, hasLength(pausedCount));
      expect(
        currentMap!.markers
            .singleWhere(
              (marker) => marker.markerId.value == 'driver-current-position',
            )
            .position,
        const LatLng(14.0753, -87.1921),
      );
      await tester.tap(find.byTooltip('Volver a seguir mi ubicación'));
      await tester.pumpAndSettle();
      expect(camera.updates.last, [
        'newLatLngZoom',
        [14.0753, -87.1921],
        16.5,
      ]);
      expect(find.byTooltip('Siguiendo tu ubicación'), findsOneWidget);
      expect(repository.calculateCalls, 1);
      expect(repository.getCalls, 1);

      // Once GPS reaches the fixture's road, the travelled prefix disappears.
      final roadMiddle = originalLine.points[1];
      tracking.setCurrentLocation(
        DeviceLocation(
          latitude: roadMiddle.latitude,
          longitude: roadMiddle.longitude,
          accuracyMeters: 5,
          recordedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      await tester.pump();
      expect(currentMap!.polylines.single.points.first, roadMiddle);
      expect(currentMap!.polylines.single.points, hasLength(2));
      final destination = originalLine.points.last;
      tracking.setCurrentLocation(
        DeviceLocation(
          latitude: destination.latitude,
          longitude: destination.longitude,
          accuracyMeters: 5,
          recordedAt: DateTime.utc(2026, 10, 23),
        ),
      );
      await tester.pump();
      expect(currentMap!.polylines, isEmpty);
      expect(
        find.text('No hay un trazado disponible para este tramo.'),
        findsNothing,
      );
      expect(repository.calculateCalls, 1);
      expect(repository.getCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('centra el GPS más reciente y respeta movimiento reducido', (
    tester,
  ) async {
    final initialLocation = Completer<DeviceLocation>();
    final camera = _RecordingMapController();
    GoogleMap? map;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceLocationServiceProvider.overrideWithValue(
            _DelayedDeviceLocationService(initialLocation.future),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: DriverRouteMapView(
            route: const DriverRoute(
              driverId: 'd',
              orderType: 'ASIGNACION',
              routeCalculated: false,
              stops: [],
              map: RouteMapConfiguration(
                mode: 'INTEGRADO',
                provider: 'GOOGLE_MAPS',
                showMap: true,
                showRoute: false,
                allowsExternalNavigation: false,
              ),
              roadRoute: RoadRoute(
                status: 'NO_CONFIGURADA',
                provider: 'GOOGLE_MAPS',
                includesCompletedSegments: false,
                metricsInResponse: false,
              ),
            ),
            roadRoute: const RoadRoute(
              status: 'NO_CONFIGURADA',
              provider: 'GOOGLE_MAPS',
              includesCompletedSegments: false,
              metricsInResponse: false,
            ),
            mapBuilderForTesting: (value) {
              map = value;
              return const ColoredBox(color: Colors.blueGrey);
            },
          ),
        ),
      ),
    );
    final tracking = ProviderScope.containerOf(
      tester.element(find.byType(DriverRouteMapView)),
    ).read(driverTrackingStatusProvider.notifier);
    tracking.setCurrentLocation(
      DeviceLocation(
        latitude: 14.08,
        longitude: -87.19,
        recordedAt: DateTime.utc(2026, 10, 28),
      ),
    );
    await tester.pumpAndSettle();
    expect(map!.initialCameraPosition.target, const LatLng(14.08, -87.19));
    map!.onMapCreated!(camera);
    await tester.pumpAndSettle();
    expect(camera.animations, 0);
    expect(camera.updates.last, [
      'newLatLngZoom',
      [14.08, -87.19],
      16.5,
    ]);

    initialLocation.complete(
      DeviceLocation(
        latitude: 14.01,
        longitude: -87.19,
        recordedAt: DateTime.utc(2026, 10, 27),
      ),
    );
    await tester.pumpAndSettle();
    expect(camera.updates, hasLength(1));
    expect(
      map!.markers
          .singleWhere(
            (marker) => marker.markerId.value == 'driver-current-position',
          )
          .position,
      const LatLng(14.08, -87.19),
    );
    expect(tester.takeException(), isNull);
  });
}

class _RecordingMapController extends Fake implements GoogleMapController {
  final updates = <Object>[];
  int animations = 0;

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async {
    animations++;
    updates.add(cameraUpdate.toJson());
  }

  @override
  Future<void> moveCamera(CameraUpdate cameraUpdate) async {
    updates.add(cameraUpdate.toJson());
  }

  @override
  void dispose() {}
}

class _DelayedDeviceLocationService extends DeviceLocationService {
  _DelayedDeviceLocationService(this.location);
  final Future<DeviceLocation> location;

  @override
  Future<DeviceLocation> getCurrentLocation() => location;
}

class _FakeRoutesRepository implements RoutesRepository {
  _FakeRoutesRepository({required this.route, required this.calculatedRoad});

  final DriverRoute route;
  final RoadRoute calculatedRoad;
  int calculateCalls = 0;
  int getCalls = 0;

  @override
  Future<DriverRoute> getMyRoute() async {
    getCalls++;
    return route;
  }

  @override
  Future<RoadRoute> calculate(CalculateRouteInput input) async {
    calculateCalls++;
    return calculatedRoad;
  }
}

class _FakeDeviceLocationService extends DeviceLocationService {
  const _FakeDeviceLocationService();

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    return DeviceLocation(
      latitude: 14.071,
      longitude: -87.191,
      recordedAt: DateTime.utc(2026, 10, 14),
    );
  }
}
