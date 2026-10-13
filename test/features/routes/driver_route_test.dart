import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/widgets/driver_route_section.dart';

void main() {
  test('interpreta navegación y estado vial sin guardar una clave', () {
    final route = DriverRoute.fromJson(_routeJson());

    expect(route.nextStop?.title, 'Sucursal Centro');
    expect(route.stops, hasLength(2));
    expect(route.navigation?.requiresApiKey, isFalse);
    expect(route.navigation?.url.host, 'www.google.com');
    expect(route.roadRoute.status, 'NO_CONFIGURADA');
    expect(route.roadRoute.metricsInResponse, isFalse);
    expect(route.roadRoute.canCalculate, isFalse);
  });

  testWidgets(
    'la tarjeta de ruta no desborda en móvil angosto con texto grande',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routesRepositoryProvider.overrideWithValue(
              _RoutesRepository(DriverRoute.fromJson(_routeJson())),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DriverRouteSection(
                  canCalculate: true,
                  onOpenRequest: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi ruta'), findsOneWidget);
      expect(find.text('Navegar'), findsOneWidget);
      expect(find.textContaining('beta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RoutesRepository implements RoutesRepository {
  const _RoutesRepository(this.route);

  final DriverRoute route;

  @override
  Future<DriverRoute> getMyRoute() async => route;

  @override
  Future<RoadRoute> calculate(CalculateRouteInput input) async =>
      route.roadRoute;
}

Map<String, dynamic> _routeJson() => {
  'repartidor_id': 'driver-id',
  'jornada_id': 'shift-id',
  'ruta_id': 'route-id',
  'version_actual': 1,
  'orden_tipo': 'ASIGNACION',
  'ruta_calculada': false,
  'proxima_parada': _stop(1, 'RECOLECCION', 'Sucursal Centro'),
  'paradas': [
    _stop(1, 'RECOLECCION', 'Sucursal Centro'),
    _stop(2, 'ENTREGA', 'Sucursal Norte'),
  ],
  'navegacion': {
    'proveedor': 'GOOGLE_MAPS',
    'requiere_clave_api': false,
    'solicitud_id': 'request-id',
    'tipo_parada': 'RECOLECCION',
    'url': 'https://www.google.com/maps/dir/?api=1&destination=14.072300%2C-87.192100&travelmode=two-wheeler',
  },
  'ruta_vial': {
    'estado': 'NO_CONFIGURADA',
    'proveedor': 'GOOGLE_MAPS',
    'atribucion': null,
    'aviso_motocicleta':
        'Las rutas para motocicletas están en beta. Verifica la vía.',
    'version_actual': 1,
    'version_calculada': null,
    'polilinea_codificada': null,
    'incluye_tramos_completados': false,
    'calculada_en': null,
    'expira_en': null,
    'origen_gps': null,
    'codigo_error': null,
    'reintento_desde': null,
    'metricas_en_respuesta': false,
    'distancia_estimada_metros': null,
    'duracion_estimada_segundos': null,
  },
};

Map<String, dynamic> _stop(int order, String type, String name) => {
  'orden': order,
  'solicitud_id': 'request-id',
  'numero_solicitud': 'SOL-1',
  'prioridad': 'NORMAL',
  'modalidad': 'ENTRE_SUCURSALES',
  'estado_solicitud': 'ASSIGNED',
  'tipo': type,
  'ubicacion': {
    'id': 'location-$order',
    'nombre': name,
    'direccion': 'Tegucigalpa',
    'latitud': '14.072300',
    'longitud': '-87.192100',
  },
  'destino_especial': null,
  'presentacion_ruta': 'MAPA',
};
