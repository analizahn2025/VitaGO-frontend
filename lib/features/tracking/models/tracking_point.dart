import 'package:vitago_app/core/models/json_readers.dart';

class TrackingPoint {
  const TrackingPoint({
    required this.id,
    required this.clientId,
    required this.shiftId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.isOperational,
    required this.createdAt,
    this.accuracyMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      id: requireString(json, 'id'),
      clientId: requireString(json, 'id_cliente'),
      shiftId: requireString(json, 'jornada_id'),
      driverId: requireString(json, 'repartidor_id'),
      latitude: requireString(json, 'latitud'),
      longitude: requireString(json, 'longitud'),
      accuracyMeters: optionalString(json, 'precision_metros'),
      speedMetersPerSecond: optionalString(json, 'velocidad_metros_segundo'),
      headingDegrees: optionalString(json, 'rumbo_grados'),
      recordedAt: requireDateTime(json, 'registrada_en'),
      isOperational: optionalBool(json, 'es_operativo'),
      createdAt: requireDateTime(json, 'creado_en'),
    );
  }

  final String id;
  final String clientId;
  final String shiftId;
  final String driverId;
  final String latitude;
  final String longitude;
  final String? accuracyMeters;
  final String? speedMetersPerSecond;
  final String? headingDegrees;
  final DateTime recordedAt;
  final bool isOperational;
  final DateTime createdAt;
}

class TrackingPointInput {
  const TrackingPointInput({
    required this.clientId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  final String clientId;
  final String latitude;
  final String longitude;
  final String? accuracyMeters;
  final String? speedMetersPerSecond;
  final String? headingDegrees;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'id_cliente': clientId,
    'latitud': latitude,
    'longitud': longitude,
    'precision_metros': accuracyMeters,
    'velocidad_metros_segundo': speedMetersPerSecond,
    'rumbo_grados': headingDegrees,
    'registrada_en': recordedAt.toUtc().toIso8601String(),
  };
}

class TrackingBatchInput {
  const TrackingBatchInput({required this.shiftId, required this.points});

  final String shiftId;
  final List<TrackingPointInput> points;

  Map<String, dynamic> toJson() => {
    'jornada_id': shiftId,
    'registros': points.map((point) => point.toJson()).toList(growable: false),
  };
}

class TrackingBatchResult {
  const TrackingBatchResult({
    required this.received,
    required this.created,
    required this.repeated,
    required this.points,
  });

  factory TrackingBatchResult.fromJson(Map<String, dynamic> json) {
    return TrackingBatchResult(
      received: optionalInt(json, 'recibidos'),
      created: optionalInt(json, 'creados'),
      repeated: optionalInt(json, 'repetidos'),
      points: jsonMapList(
        json['registros'],
        'registros de seguimiento',
      ).map(TrackingPoint.fromJson).toList(growable: false),
    );
  }

  final int received;
  final int created;
  final int repeated;
  final List<TrackingPoint> points;
}

class RequestTracking {
  const RequestTracking({
    required this.requestId,
    required this.status,
    required this.available,
    this.location,
  });

  factory RequestTracking.fromJson(Map<String, dynamic> json) {
    final locationJson = optionalJsonMap(json, 'ubicacion');
    return RequestTracking(
      requestId: requireString(json, 'solicitud_id'),
      status: requireString(json, 'estado'),
      available: optionalBool(json, 'seguimiento_disponible'),
      location: locationJson == null
          ? null
          : TrackingPoint.fromJson(locationJson),
    );
  }

  final String requestId;
  final String status;
  final bool available;
  final TrackingPoint? location;
}
