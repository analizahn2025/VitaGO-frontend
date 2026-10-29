import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

void main() {
  test('interpreta flujo_actual independiente del estado del trazado', () {
    final route = _route(legacy: true);
    expect(route.flow!.mode, 'AUTOMATICO');
    expect(route.flow!.screen, 'MAPA');
    expect(route.flow!.requestId, 'first');
    expect(route.flow!.segmentId, 'first:RECOLECCION');
    expect(route.flow!.requiresAcceptance, isFalse);
    expect(route.flow!.allowsStageSelection, isFalse);
    expect(route.roadRoute.canUpdateBreakdown, isTrue);
  });
  testWidgets('muestra únicamente el tramo del flujo sin selectores', (
    tester,
  ) async {
    final harness = _Harness(_route());
    await harness.pump(tester);
    expect(harness.map!.polylines.single.polylineId.value, 'first:RECOLECCION');
    expect(find.byType(ChoiceChip), findsNothing);
    expect(
      harness.map!.markers.where((marker) => marker.onTap != null),
      isEmpty,
    );
    expect(harness.repository.calculations, isEmpty);
    expect(harness.repository.reads, 0);
    expect(harness.map!.mapToolbarEnabled, isFalse);
  });
  testWidgets(
    'un refresco sigue el nuevo flujo sin conservar el índice anterior',
    (tester) async {
      final harness = _Harness(_route());
      await harness.pump(tester);
      harness.repository.current = _route(firstCompleted: true);
      await tester.tap(find.byTooltip('Actualizar ruta y servicio'));
      await tester.pumpAndSettle();
      expect(
        harness.map!.polylines.single.polylineId.value,
        'second:RECOLECCION',
      );
      harness.repository.current = _route(
        firstCompleted: true,
        secondPickedUp: true,
      );
      await tester.tap(find.byTooltip('Actualizar ruta y servicio'));
      await tester.pumpAndSettle();
      expect(harness.map!.polylines.single.polylineId.value, 'second:ENTREGA');
      expect(harness.repository.calculations, isEmpty);
    },
  );
  testWidgets('una parada sin desplazamiento no rescata una línea vieja', (
    tester,
  ) async {
    final harness = _Harness(
      _route(noMovement: true, firstCompleted: true, secondPickedUp: true),
    );
    await harness.pump(tester);
    expect(harness.map!.polylines, isEmpty);
    await _expand(tester);
    expect(find.textContaining('No requiere desplazamiento'), findsOneWidget);
    expect(harness.map!.markers, isNotEmpty);
  });
  testWidgets(
    'un tramo ausente muestra el punto sin calcular automáticamente',
    (tester) async {
      final harness = _Harness(_route(omitSecond: true, firstCompleted: true));
      await harness.pump(tester);
      expect(harness.map!.polylines, isEmpty);
      await _expand(tester);
      expect(
        find.text('Tramo no incluido en el cálculo actual'),
        findsOneWidget,
      );
      expect(harness.repository.calculations, isEmpty);
    },
  );
  testWidgets(
    'actualizar desglose requiere confirmación explícita y reintentar true',
    (tester) async {
      final harness = _Harness(_route(legacy: true));
      await harness.pump(tester);
      expect(harness.map!.polylines, isEmpty);
      await _expand(tester);
      await tester.ensureVisible(find.text('Actualizar tramos'));
      await tester.tap(find.text('Actualizar tramos'));
      await tester.pumpAndSettle();
      expect(harness.repository.calculations, isEmpty);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(harness.repository.calculations, isEmpty);
      harness.repository.calculated = _route();
      await tester.tap(find.text('Actualizar tramos'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Actualizar tramos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.repository.calculations.single.toJson(), {
        'version_actual': 1,
        'reintentar': true,
      });
      expect(
        harness.map!.polylines.single.polylineId.value,
        'first:RECOLECCION',
      );
    },
  );
  testWidgets(
    'el panel automático soporta móvil angosto, paisaje y texto grande',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 667);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final harness = _Harness(_route());
      await harness.pump(tester, largeText: true);
      await _expand(tester);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(667, 375);
      await tester.pumpAndSettle();
      expect(harness.map!.polylines, hasLength(1));
      expect(find.byType(ChoiceChip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _expand(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -350));
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness(DriverRoute route) : repository = _Repository(route);
  final _Repository repository;
  GoogleMap? map;

  Future<void> pump(WidgetTester tester, {bool largeText = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routesRepositoryProvider.overrideWithValue(repository),
          deviceLocationServiceProvider.overrideWithValue(_LocationService()),
        ],
        child: MaterialApp(
          theme: largeText ? ThemeData.dark() : ThemeData.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(largeText ? 1.6 : 1),
            ),
            child: child!,
          ),
          home: DriverRouteMapView(
            route: repository.current,
            roadRoute: repository.current.roadRoute,
            canCalculate: true,
            mapBuilderForTesting: (value) {
              map = value;
              return const ColoredBox(color: Colors.blueGrey);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String key) async {
    await _expand(tester);
    final chip = find.byKey(ValueKey(key));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }
}

class _Repository implements RoutesRepository {
  _Repository(this.current);
  DriverRoute current;
  DriverRoute? calculated;
  final calculations = <CalculateRouteInput>[];
  int reads = 0;

  @override
  Future<DriverRoute> getMyRoute() async {
    reads++;
    return current;
  }

  @override
  Future<RoadRoute> calculate(CalculateRouteInput input) async {
    calculations.add(input);
    current = calculated ?? current;
    return current.roadRoute;
  }
}

class _LocationService extends DeviceLocationService {
  @override
  Future<DeviceLocation> getCurrentLocation() async => DeviceLocation(
    latitude: 14.0723,
    longitude: -87.1921,
    recordedAt: DateTime.utc(2026, 10, 23),
  );
}

// Synthetic fixtures only; production always uses backend geometry.
DriverRoute _route({
  bool legacy = false,
  bool noMovement = false,
  bool omitSecond = false,
  bool firstCompleted = false,
  bool secondPickedUp = false,
}) {
  final stops = [
    if (!firstCompleted) ...[
      _stop('first', 'RECOLECCION', 1),
      _stop('first', 'ENTREGA', 2),
    ],
    if (!secondPickedUp) _stop('second', 'RECOLECCION', 3),
    _stop('second', 'ENTREGA', 4),
  ];
  return DriverRoute.fromJson({
    'repartidor_id': 'driver-id',
    'version_actual': 1,
    'ruta_calculada': true,
    'flujo_actual': {
      'modo': 'AUTOMATICO',
      'pantalla': 'MAPA',
      'solicitud_id': stops.first['solicitud_id'],
      'tipo_parada': stops.first['tipo'],
      'estado': stops.first['estado_solicitud'],
      'tramo_id': '${stops.first['solicitud_id']}:${stops.first['tipo']}',
    },
    'paradas': stops,
    'proxima_parada': stops.first,
    'mapa': {
      'modo': 'INTEGRADO',
      'proveedor': 'GOOGLE_MAPS',
      'mostrar_mapa': true,
      'mostrar_trazado': true,
      'permite_navegacion_externa': false,
    },
    'ruta_vial': {
      'estado': 'CALCULADA',
      'proveedor': 'GOOGLE_MAPS',
      'atribucion': 'Google Maps',
      'version_actual': 1,
      'version_calculada': 1,
      'polilinea_codificada': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'modo_visualizacion': 'UN_TRAMO',
      'desglose_disponible': !legacy,
      'requiere_actualizar_desglose': legacy,
      'tramo_actual_id': legacy
          ? null
          : '${stops.first['solicitud_id']}:${stops.first['tipo']}',
      'tramos': legacy
          ? []
          : [
              for (final (index, stop) in stops.indexed)
                if (!omitSecond || stop['solicitud_id'] != 'second')
                  {
                    'tramo_id': '${stop['solicitud_id']}:${stop['tipo']}',
                    'solicitud_id': stop['solicitud_id'],
                    'numero_solicitud': stop['numero_solicitud'],
                    'orden_envio': stop['solicitud_id'] == 'first' ? 1 : 2,
                    'orden_parada': index + 1,
                    'tipo_parada': stop['tipo'],
                    'estado_solicitud': stop['estado_solicitud'],
                    'es_proximo': index == 0,
                    'origen': {
                      'tipo': index == 0 ? 'GPS' : 'PARADA',
                      'ubicacion_id': null,
                      'latitud': '14.072000',
                      'longitud': '-87.192000',
                    },
                    'destino': {
                      'ubicacion_id': '${stop['solicitud_id']}-${stop['tipo']}',
                      'latitud': '14.072300',
                      'longitud': '-87.192100',
                    },
                    'sin_desplazamiento':
                        noMovement && stop['tipo'] == 'ENTREGA',
                    'polilinea_codificada':
                        noMovement && stop['tipo'] == 'ENTREGA'
                        ? null
                        : stop['tipo'] == 'RECOLECCION'
                        ? '????'
                        : 'AAAAAA',
                  },
            ],
    },
  });
}

Map<String, dynamic> _stop(String id, String type, int order) => {
  'orden': order,
  'solicitud_id': id,
  'numero_solicitud': 'SOL-$id',
  'prioridad': 'NORMAL',
  'modalidad': 'ENTRE_SUCURSALES',
  'estado_solicitud': 'ASSIGNED',
  'tipo': type,
  'ubicacion': {
    'id': '$id-$type',
    'nombre': 'Sucursal $id $type',
    'direccion': 'Dirección de prueba',
    'latitud': '14.072300',
    'longitud': '-87.192100',
  },
};
