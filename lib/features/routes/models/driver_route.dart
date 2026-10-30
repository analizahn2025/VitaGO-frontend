import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/routes/models/road_route_segment.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';

class DriverRoute {
  const DriverRoute({
    required this.driverId,
    required this.orderType,
    required this.routeCalculated,
    required this.stops,
    required this.map,
    required this.roadRoute,
    this.shiftId,
    this.routeId,
    this.currentVersion,
    this.nextStop,
    this.currentArrival,
    this.flow,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    final nextStop = optionalJsonMap(json, 'proxima_parada');
    final arrival = parseDriverArrivals([json['llegada_actual']]).firstOrNull;
    final flow = optionalJsonMap(json, 'flujo_actual');
    return DriverRoute(
      driverId: requireString(json, 'repartidor_id'),
      shiftId: optionalString(json, 'jornada_id'),
      routeId: optionalString(json, 'ruta_id'),
      currentVersion: json['version_actual'] == null
          ? null
          : optionalInt(json, 'version_actual'),
      orderType: optionalString(json, 'orden_tipo') ?? 'ASIGNACION',
      routeCalculated: optionalBool(json, 'ruta_calculada'),
      nextStop: nextStop == null ? null : DriverRouteStop.fromJson(nextStop),
      currentArrival: arrival,
      flow: flow == null ? null : DriverRouteFlow.fromJson(flow),
      stops: jsonMapList(
        json['paradas'],
        'paradas de la ruta',
      ).map(DriverRouteStop.fromJson).toList(growable: false),
      map: RouteMapConfiguration.fromJson(requireJsonMap(json['mapa'], 'mapa')),
      roadRoute: RoadRoute.fromJson(
        requireJsonMap(json['ruta_vial'], 'ruta_vial'),
      ),
    );
  }

  final String driverId;
  final String? shiftId;
  final String? routeId;
  final int? currentVersion;
  final String orderType;
  final bool routeCalculated;
  final DriverRouteStop? nextStop;
  final DriverArrival? currentArrival;
  final DriverRouteFlow? flow;
  final List<DriverRouteStop> stops;
  final RouteMapConfiguration map;
  final RoadRoute roadRoute;
}

class DriverRouteStop {
  const DriverRouteStop({
    required this.order,
    required this.requestId,
    required this.requestNumber,
    required this.priority,
    required this.modality,
    required this.requestStatus,
    required this.type,
    required this.routePresentation,
    this.location,
    this.specialDestination,
    this.tubeCount,
    this.flaskCount,
  });

  factory DriverRouteStop.fromJson(Map<String, dynamic> json) {
    final location = optionalJsonMap(json, 'ubicacion');
    return DriverRouteStop(
      order: optionalInt(json, 'orden'),
      requestId: requireString(json, 'solicitud_id'),
      requestNumber: requireString(json, 'numero_solicitud'),
      tubeCount: nullableInt(json, 'cantidad_tubos'),
      flaskCount: nullableInt(json, 'cantidad_frascos'),
      priority: requireString(json, 'prioridad'),
      modality: requireString(json, 'modalidad'),
      requestStatus: requireString(json, 'estado_solicitud'),
      type: requireString(json, 'tipo'),
      location: location == null ? null : RouteLocation.fromJson(location),
      specialDestination: optionalString(json, 'destino_especial'),
      routePresentation: optionalString(json, 'presentacion_ruta') ?? 'MAPA',
    );
  }

  final int order;
  final String requestId;
  final String requestNumber;
  final int? tubeCount;
  final int? flaskCount;
  final String priority;
  final String modality;
  final String requestStatus;
  final String type;
  final RouteLocation? location;
  final String? specialDestination;
  final String routePresentation;

  String get title => location?.name ?? specialDestination ?? 'Parada especial';

  String get actionLabel => type == 'RECOLECCION' ? 'Recoger' : 'Entregar';
}

class RouteLocation {
  const RouteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory RouteLocation.fromJson(Map<String, dynamic> json) {
    return RouteLocation(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      address: requireString(json, 'direccion'),
      latitude: requireString(json, 'latitud'),
      longitude: requireString(json, 'longitud'),
    );
  }

  final String id;
  final String name;
  final String address;
  final String latitude;
  final String longitude;
}

class RouteMapConfiguration {
  const RouteMapConfiguration({
    required this.mode,
    required this.provider,
    required this.showMap,
    required this.showRoute,
    required this.allowsExternalNavigation,
  });

  factory RouteMapConfiguration.fromJson(Map<String, dynamic> json) {
    return RouteMapConfiguration(
      mode: requireString(json, 'modo'),
      provider: requireString(json, 'proveedor'),
      showMap: optionalBool(json, 'mostrar_mapa'),
      showRoute: optionalBool(json, 'mostrar_trazado'),
      allowsExternalNavigation: optionalBool(
        json,
        'permite_navegacion_externa',
      ),
    );
  }

  final String mode;
  final String provider;
  final bool showMap;
  final bool showRoute;
  final bool allowsExternalNavigation;
}

class RoadRoute {
  const RoadRoute({
    required this.status,
    required this.provider,
    required this.includesCompletedSegments,
    required this.metricsInResponse,
    this.attribution,
    this.motorcycleWarning,
    this.currentVersion,
    this.calculatedVersion,
    this.encodedPolyline,
    this.calculatedAt,
    this.expiresAt,
    this.originGps,
    this.errorCode,
    this.retryFrom,
    this.estimatedDistanceMeters,
    this.estimatedDurationSeconds,
    this.visualizationMode = 'UN_TRAMO',
    this.breakdownAvailable = false,
    this.requiresBreakdownUpdate = false,
    this.currentSegmentId,
    this.segments = const [],
  });

  factory RoadRoute.fromJson(Map<String, dynamic> json) {
    final origin = optionalJsonMap(json, 'origen_gps');
    return RoadRoute(
      status: requireString(json, 'estado'),
      provider: requireString(json, 'proveedor'),
      attribution: optionalString(json, 'atribucion'),
      motorcycleWarning: optionalString(json, 'aviso_motocicleta'),
      currentVersion: json['version_actual'] == null
          ? null
          : optionalInt(json, 'version_actual'),
      calculatedVersion: json['version_calculada'] == null
          ? null
          : optionalInt(json, 'version_calculada'),
      encodedPolyline: optionalString(json, 'polilinea_codificada'),
      includesCompletedSegments: optionalBool(
        json,
        'incluye_tramos_completados',
      ),
      calculatedAt: optionalDateTime(json, 'calculada_en'),
      expiresAt: optionalDateTime(json, 'expira_en'),
      originGps: origin == null ? null : RouteGpsOrigin.fromJson(origin),
      errorCode: optionalString(json, 'codigo_error'),
      retryFrom: optionalDateTime(json, 'reintento_desde'),
      visualizationMode:
          optionalString(json, 'modo_visualizacion') ?? 'UN_TRAMO',
      breakdownAvailable: optionalBool(json, 'desglose_disponible'),
      requiresBreakdownUpdate: optionalBool(
        json,
        'requiere_actualizar_desglose',
      ),
      currentSegmentId: optionalString(json, 'tramo_actual_id'),
      segments: jsonMapList(
        json['tramos'] ?? const [],
        'tramos',
      ).map(RoadRouteSegment.fromJson).toList(growable: false),
      metricsInResponse: optionalBool(json, 'metricas_en_respuesta'),
      estimatedDistanceMeters: _optionalDouble(
        json,
        'distancia_estimada_metros',
      ),
      estimatedDurationSeconds: _optionalDouble(
        json,
        'duracion_estimada_segundos',
      ),
    );
  }

  final String status;
  final String provider;
  final String? attribution;
  final String? motorcycleWarning;
  final int? currentVersion;
  final int? calculatedVersion;
  final String? encodedPolyline;
  final bool includesCompletedSegments;
  final DateTime? calculatedAt;
  final DateTime? expiresAt;
  final RouteGpsOrigin? originGps;
  final String? errorCode;
  final DateTime? retryFrom;
  final bool metricsInResponse;
  final double? estimatedDistanceMeters;
  final double? estimatedDurationSeconds;
  final String visualizationMode;
  final bool breakdownAvailable;
  final bool requiresBreakdownUpdate;
  final String? currentSegmentId;
  final List<RoadRouteSegment> segments;

  RoadRouteSegment? segmentForStop(DriverRouteStop? stop) {
    if (stop == null) return null;
    return segments
        .where(
          (segment) =>
              segment.id == '${stop.requestId}:${stop.type}' &&
              segment.requestId == stop.requestId &&
              segment.stopType == stop.type,
        )
        .firstOrNull;
  }

  bool get canUpdateBreakdown =>
      status == 'CALCULADA' && requiresBreakdownUpdate && !breakdownAvailable;

  bool get canCalculate =>
      const {'PENDIENTE', 'ITINERARIO_CAMBIO'}.contains(status);

  bool get canRetry =>
      status == 'FALLIDA' &&
      retryFrom != null &&
      !DateTime.now().isBefore(retryFrom!);
}

class RouteGpsOrigin {
  const RouteGpsOrigin({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
  });

  factory RouteGpsOrigin.fromJson(Map<String, dynamic> json) {
    return RouteGpsOrigin(
      latitude: requireString(json, 'latitud'),
      longitude: requireString(json, 'longitud'),
      recordedAt: requireDateTime(json, 'registrada_en'),
      accuracyMeters: optionalString(json, 'precision_metros'),
    );
  }

  final String latitude;
  final String longitude;
  final DateTime recordedAt;
  final String? accuracyMeters;
}

class CalculateRouteInput {
  const CalculateRouteInput({required this.currentVersion, this.retry = false});

  final int currentVersion;
  final bool retry;

  Map<String, dynamic> toJson() => {
    'version_actual': currentVersion,
    'reintentar': retry,
  };
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value.toString());
  if (parsed == null) throw FormatException('El campo $key no es numérico.');
  return parsed;
}
