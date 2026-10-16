import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

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
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map-surface')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
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
