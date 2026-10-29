import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/widgets/driver_route_section.dart';

void main() {
  test(
    'conserva paradas intercaladas aunque reaparezca la misma solicitud',
    () {
      final stops = [
        for (final (index, id, type) in [
          (1, 'A', 'RECOLECCION'),
          (2, 'B', 'RECOLECCION'),
          (3, 'B', 'ENTREGA'),
          (4, 'A', 'ENTREGA'),
        ])
          _stop(index, type, '$id $type')
            ..['solicitud_id'] = id
            ..['orden_envio'] = id == 'A' ? 1 : 2,
      ];
      final route = DriverRoute.fromJson({
        ..._routeJson(),
        'orden_tipo': 'CERCANIA_GPS',
        'paradas': stops,
        'proxima_parada': stops.first,
        'flujo_actual': {
          'modo': 'AUTOMATICO',
          'pantalla': 'MAPA',
          'solicitud_id': 'A',
          'tipo_parada': 'RECOLECCION',
          'estado': 'GOING_TO_PICKUP',
          'tramo_id': 'A:RECOLECCION',
        },
      });
      expect(route.stops.map((stop) => '${stop.requestId}:${stop.type}'), [
        'A:RECOLECCION',
        'B:RECOLECCION',
        'B:ENTREGA',
        'A:ENTREGA',
      ]);
      expect(route.stops.map((stop) => stop.order), [1, 2, 3, 4]);
      expect(route.flow!.segmentId, 'A:RECOLECCION');
      expect(route.nextStop!.requestId, 'A');
    },
  );

  test(
    'acepta CERCANIA_GPS y conserva las paradas tal como las envía el backend',
    () {
      final json = _routeJson();
      final first = _stop(9, 'RECOLECCION', 'Servicio recibido primero')
        ..['solicitud_id'] = 'newer-request';
      final second = _stop(1, 'RECOLECCION', 'Servicio recibido después')
        ..['solicitud_id'] = 'older-request';
      json['orden_tipo'] = 'CERCANIA_GPS';
      json['paradas'] = [first, second];
      json['proxima_parada'] = first;
      final route = DriverRoute.fromJson(json);
      expect(route.orderType, 'CERCANIA_GPS');
      expect(route.stops.map((stop) => stop.requestId), [
        'newer-request',
        'older-request',
      ]);
      expect(route.nextStop!.requestId, 'newer-request');
      expect(route.roadRoute.estimatedDistanceMeters, isNull);
      expect(route.roadRoute.estimatedDurationSeconds, isNull);
      expect(DriverRoute.fromJson(_routeJson()).orderType, 'ASIGNACION');
    },
  );

  testWidgets(
    'la tarjeta muestra la próxima parada recibida sin afirmar orden por antigüedad',
    (tester) async {
      final json = _routeJson()..['orden_tipo'] = 'CERCANIA_GPS';
      json['proxima_parada'] = _stop(2, 'ENTREGA', 'Servicio en curso');
      json['paradas'] = [
        json['proxima_parada'],
        _stop(1, 'RECOLECCION', 'Servicio pendiente'),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routesRepositoryProvider.overrideWithValue(
              _RoutesRepository(DriverRoute.fromJson(json)),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DriverRouteSection(
                canCalculate: false,
                onOpenRequest: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Servicio en curso'), findsOneWidget);
      expect(find.text('2 paradas en el orden de tu ruta'), findsOneWidget);
      expect(find.textContaining('orden de asignación'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('flujo_actual conserva IDs reales cuando cambia el orden recibido', () {
    final first = _stop(1, 'RECOLECCION', 'Primero')
      ..['solicitud_id'] = 'first';
    final second = _stop(2, 'RECOLECCION', 'Segundo')
      ..['solicitud_id'] = 'second';
    final route = DriverRoute.fromJson({
      ..._routeJson(),
      'paradas': [second, first],
      'proxima_parada': second,
      'flujo_actual': {
        'modo': 'AUTOMATICO',
        'pantalla': 'MAPA',
        'solicitud_id': 'second',
        'tipo_parada': 'RECOLECCION',
        'estado': 'GOING_TO_PICKUP',
        'tramo_id': 'second:RECOLECCION',
      },
    });
    expect(route.stops.first.requestId, 'second');
    expect(route.flow!.requestId, 'second');
    expect(route.flow!.segmentId, 'second:RECOLECCION');
  });

  test('recupera llegada_actual sin navegación externa', () {
    final route = DriverRoute.fromJson({
      ..._routeJson(),
      'llegada_actual': {
        'evento_id': 'arrival-id',
        'solicitud_id': 'request-id',
        'estado': 'AT_DESTINATION',
        'tipo_parada': 'ENTREGA',
        'detectada_en': '2026-10-23T18:00:00Z',
        'fuente': 'GPS',
        'pantalla': 'ENTREGA',
      },
    });
    expect(route.currentArrival!.targetStatus, 'DELIVERED');
    expect(DriverRoute.fromJson(_routeJson()).currentArrival, isNull);
  });
  test(
    'interpreta el mapa integrado y el estado vial sin navegación externa',
    () {
      final route = DriverRoute.fromJson(_routeJson());

      expect(route.nextStop?.title, 'Sucursal Centro');
      expect(route.stops, hasLength(2));
      expect(route.map.mode, 'INTEGRADO');
      expect(route.map.provider, 'GOOGLE_MAPS');
      expect(route.map.showMap, isTrue);
      expect(route.map.showRoute, isFalse);
      expect(route.map.allowsExternalNavigation, isFalse);
      expect(route.roadRoute.status, 'NO_CONFIGURADA');
      expect(route.roadRoute.metricsInResponse, isFalse);
      expect(route.roadRoute.canCalculate, isFalse);
    },
  );

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
      expect(find.text('Ver mapa'), findsOneWidget);
      expect(find.text('Navegar'), findsNothing);
      expect(find.textContaining('beta'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no ofrece mapa cuando el backend lo oculta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routesRepositoryProvider.overrideWithValue(
            _RoutesRepository(DriverRoute.fromJson(_routeJson(showMap: false))),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DriverRouteSection(
              canCalculate: false,
              onOpenRequest: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver mapa'), findsNothing);
    expect(find.text('Ver solicitud'), findsOneWidget);
    expect(find.textContaining('beta'), findsNothing);
  });
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

Map<String, dynamic> _routeJson({bool showMap = true}) => {
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
  'mapa': {
    'modo': 'INTEGRADO',
    'proveedor': 'GOOGLE_MAPS',
    'mostrar_mapa': showMap,
    'mostrar_trazado': false,
    'permite_navegacion_externa': false,
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
