import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/features/routes/maps/route_map_geometry.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';

void main() {
  test('decodifica una polilínea codificada del backend', () {
    final points = decodeEncodedPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 0.00001));
    expect(points[0].longitude, closeTo(-120.2, 0.00001));
    expect(points[2].latitude, closeTo(43.252, 0.00001));
    expect(points[2].longitude, closeTo(-126.453, 0.00001));
  });

  test('no dibuja la polilínea cuando el backend oculta el trazado', () {
    final route = DriverRoute.fromJson(_routeJson(showRoute: false));

    expect(routePolylinePoints(route), isEmpty);
  });

  test('dibuja solamente la polilínea autorizada por el backend', () {
    final route = DriverRoute.fromJson(_routeJson(showRoute: true));

    expect(routePolylinePoints(route), const <LatLng>[
      LatLng(38.5, -120.2),
      LatLng(40.7, -120.95),
      LatLng(43.252, -126.453),
    ]);
  });

  test('puede dibujar el resultado fresco sin cerrar y abrir el mapa', () {
    final staleRoute = DriverRoute.fromJson(_routeJson(showRoute: false));
    final freshRoadRoute = DriverRoute.fromJson(_routeJson(showRoute: true))
        .roadRoute;

    expect(
      routePolylinePoints(
        staleRoute,
        roadRoute: freshRoadRoute,
        showRoute: true,
      ),
      const <LatLng>[
        LatLng(38.5, -120.2),
        LatLng(40.7, -120.95),
        LatLng(43.252, -126.453),
      ],
    );
  });

  test('descarta coordenadas de parada fuera del rango geográfico', () {
    const location = RouteLocation(
      id: 'location-id',
      name: 'Lugar',
      address: 'Dirección',
      latitude: '95',
      longitude: '-87',
    );

    expect(routeLocationPosition(location), isNull);
  });

  test('nunca usa la línea global si falta el desglose', () {
    final json = _routeJson(showRoute: true);
    final road = json['ruta_vial'] as Map<String, dynamic>;
    road['desglose_disponible'] = false;
    road['requiere_actualizar_desglose'] = true;
    road['tramos'] = [];
    expect(routePolylinePoints(DriverRoute.fromJson(json)), isEmpty);
  });

  test('conserva los tramos reutilizados al avanzar la versión de paradas', () {
    final json = _routeJson(showRoute: true);
    json['version_actual'] = 2;
    final road = json['ruta_vial'] as Map<String, dynamic>;
    road['version_actual'] = 2;
    road['version_calculada'] = 1;
    expect(routePolylinePoints(DriverRoute.fromJson(json)), hasLength(3));
  });

  test('no recupera otra línea para un tramo ausente o sin desplazamiento', () {
    final json = _routeJson(showRoute: true);
    final route = DriverRoute.fromJson(json);
    expect(routePolylinePoints(route), isNotEmpty);
    (json['flujo_actual'] as Map)['tramo_id'] = 'other:ENTREGA';
    expect(routePolylinePoints(DriverRoute.fromJson(json)), isEmpty);
    (json['flujo_actual'] as Map)['tramo_id'] = 'request-id:RECOLECCION';
    final road = json['ruta_vial'] as Map<String, dynamic>;
    (road['tramos'] as List).first['sin_desplazamiento'] = true;
    expect(routePolylinePoints(DriverRoute.fromJson(json)), isEmpty);
  });

  test('una geometría inválida no recupera la polilínea global', () {
    final json = _routeJson(showRoute: true);
    final road = json['ruta_vial'] as Map<String, dynamic>;
    (road['tramos'] as List).first['polilinea_codificada'] = 'invalid';
    expect(routePolylinePoints(DriverRoute.fromJson(json)), isEmpty);
  });
}

Map<String, dynamic> _routeJson({required bool showRoute}) => {
  'repartidor_id': 'driver-id',
  'jornada_id': 'shift-id',
  'ruta_id': 'route-id',
  'version_actual': 1,
  'orden_tipo': 'ASIGNACION',
  'ruta_calculada': showRoute,
  'flujo_actual': {
    'modo': 'AUTOMATICO',
    'requiere_aceptacion': false,
    'permite_elegir_etapa': false,
    'solicitud_id': 'request-id',
    'tipo_parada': 'RECOLECCION',
    'estado': 'GOING_TO_PICKUP',
    'tramo_id': 'request-id:RECOLECCION',
    'pantalla': 'MAPA',
  },
  'proxima_parada': _stop(1, 'RECOLECCION', 'Sucursal Centro'),
  'paradas': [
    _stop(1, 'RECOLECCION', 'Sucursal Centro'),
    _stop(2, 'ENTREGA', 'Sucursal Norte'),
  ],
  'mapa': {
    'modo': 'INTEGRADO',
    'proveedor': 'GOOGLE_MAPS',
    'mostrar_mapa': true,
    'mostrar_trazado': showRoute,
    'permite_navegacion_externa': false,
  },
  'ruta_vial': {
    'estado': showRoute ? 'CALCULADA' : 'NO_CONFIGURADA',
    'proveedor': 'GOOGLE_MAPS',
    'atribucion': showRoute ? 'Google Maps' : null,
    'aviso_motocicleta': 'Aviso beta de motocicletas.',
    'version_actual': 1,
    'version_calculada': showRoute ? 1 : null,
    'polilinea_codificada': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
    'incluye_tramos_completados': false,
    'calculada_en': null,
    'expira_en': null,
    'origen_gps': null,
    'codigo_error': null,
    'reintento_desde': null,
    'metricas_en_respuesta': false,
    'distancia_estimada_metros': null,
    'duracion_estimada_segundos': null,
    'modo_visualizacion': 'UN_TRAMO',
    'desglose_disponible': showRoute,
    'requiere_actualizar_desglose': false,
    'tramo_actual_id': 'request-id:RECOLECCION',
    'tramos': [
      {
        'tramo_id': 'request-id:RECOLECCION',
        'solicitud_id': 'request-id',
        'numero_solicitud': 'SOL-1',
        'orden_envio': 1,
        'orden_parada': 1,
        'tipo_parada': 'RECOLECCION',
        'estado_solicitud': 'ASSIGNED',
        'es_proximo': true,
        'origen': {
          'tipo': 'GPS',
          'latitud': '14.072000',
          'longitud': '-87.192000',
        },
        'destino': {
          'ubicacion_id': 'location-1',
          'latitud': '14.072300',
          'longitud': '-87.192100',
        },
        'polilinea_codificada': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        'sin_desplazamiento': false,
      },
    ],
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
