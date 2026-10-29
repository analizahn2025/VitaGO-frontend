import 'package:vitago_app/core/models/json_readers.dart';

/// Temporary geometry supplied by the backend, never a live GPS measurement.
class RoadRouteSegment {
  const RoadRouteSegment({
    required this.id,
    required this.requestId,
    required this.requestNumber,
    required this.shipmentOrder,
    required this.stopOrder,
    required this.stopType,
    required this.requestStatus,
    required this.isNext,
    required this.origin,
    required this.destination,
    required this.withoutMovement,
    this.encodedPolyline,
  });

  factory RoadRouteSegment.fromJson(Map<String, dynamic> json) =>
      RoadRouteSegment(
        id: requireString(json, 'tramo_id'),
        requestId: requireString(json, 'solicitud_id'),
        requestNumber: requireString(json, 'numero_solicitud'),
        shipmentOrder: optionalInt(json, 'orden_envio'),
        stopOrder: optionalInt(json, 'orden_parada'),
        stopType: requireString(json, 'tipo_parada'),
        requestStatus: requireString(json, 'estado_solicitud'),
        isNext: optionalBool(json, 'es_proximo'),
        origin: RouteSegmentPoint.fromJson(
          requireJsonMap(json['origen'], 'origen'),
        ),
        destination: RouteSegmentPoint.fromJson(
          requireJsonMap(json['destino'], 'destino'),
        ),
        encodedPolyline: optionalString(json, 'polilinea_codificada'),
        withoutMovement: optionalBool(json, 'sin_desplazamiento'),
      );

  final String id;
  final String requestId;
  final String requestNumber;
  final int shipmentOrder;
  final int stopOrder;
  final String stopType;
  final String requestStatus;
  final bool isNext;
  final RouteSegmentPoint origin;
  final RouteSegmentPoint destination;
  final String? encodedPolyline;
  final bool withoutMovement;
}

class RouteSegmentPoint {
  const RouteSegmentPoint({
    required this.latitude,
    required this.longitude,
    this.type,
    this.locationId,
  });

  factory RouteSegmentPoint.fromJson(Map<String, dynamic> json) =>
      RouteSegmentPoint(
        type: optionalString(json, 'tipo'),
        locationId: optionalString(json, 'ubicacion_id'),
        latitude: requireString(json, 'latitud'),
        longitude: requireString(json, 'longitud'),
      );

  final String? type;
  final String? locationId;
  final String latitude;
  final String longitude;
}
