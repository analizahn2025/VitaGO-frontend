import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

class DriverShift {
  const DriverShift({
    required this.id,
    required this.driverId,
    required this.status,
    required this.startedAt,
    required this.operationalKilometers,
    required this.mileageAvailable,
    required this.completedServices,
    required this.completedPickups,
    required this.completedDeliveries,
    required this.normalServices,
    required this.priorityServices,
    required this.activeMinutes,
    required this.reportedIncidents,
    required this.incidentsAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.finishedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.operationalMinutes,
    this.mileageQuality,
  });

  factory DriverShift.fromJson(Map<String, dynamic> json) {
    final mileageQuality = optionalJsonMap(json, 'calidad_kilometraje');
    return DriverShift(
      id: requireString(json, 'id'),
      driverId: requireString(json, 'repartidor_id'),
      status: requireString(json, 'estado'),
      startedAt: requireDateTime(json, 'iniciada_en'),
      finishedAt: optionalDateTime(json, 'finalizada_en'),
      startLatitude: optionalString(json, 'latitud_inicio'),
      startLongitude: optionalString(json, 'longitud_inicio'),
      endLatitude: optionalString(json, 'latitud_fin'),
      endLongitude: optionalString(json, 'longitud_fin'),
      operationalKilometers:
          optionalString(json, 'kilometros_operativos') ?? '0.000',
      mileageAvailable: optionalBool(json, 'kilometraje_disponible'),
      completedServices: optionalInt(json, 'servicios_completados'),
      completedPickups: optionalInt(json, 'recolecciones_completadas'),
      completedDeliveries: optionalInt(json, 'entregas_completadas'),
      normalServices: optionalInt(json, 'servicios_normales'),
      priorityServices: optionalInt(json, 'servicios_prioritarios'),
      activeMinutes: optionalInt(json, 'minutos_activos'),
      operationalMinutes: json['minutos_operativos'] == null
          ? null
          : optionalInt(json, 'minutos_operativos'),
      mileageQuality: mileageQuality == null || mileageQuality.isEmpty
          ? null
          : MileageQuality.fromJson(mileageQuality),
      reportedIncidents: optionalInt(json, 'incidencias_reportadas'),
      incidentsAvailable: optionalBool(
        json,
        'incidencias_disponibles',
        fallback: true,
      ),
      createdAt: requireDateTime(json, 'creado_en'),
      updatedAt: requireDateTime(json, 'actualizado_en'),
    );
  }

  final String id;
  final String driverId;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? startLatitude;
  final String? startLongitude;
  final String? endLatitude;
  final String? endLongitude;
  final String operationalKilometers;
  final bool mileageAvailable;
  final int completedServices;
  final int completedPickups;
  final int completedDeliveries;
  final int normalServices;
  final int priorityServices;
  final int activeMinutes;
  final int? operationalMinutes;
  final MileageQuality? mileageQuality;
  final int reportedIncidents;
  final bool incidentsAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVA';
}

class ShiftCoordinatesInput {
  const ShiftCoordinatesInput({
    this.latitude,
    this.longitude,
    this.gpsSessions,
  });

  final String? latitude;
  final String? longitude;
  final List<GpsSessionManifest>? gpsSessions;

  Map<String, dynamic> toJson() => {
    if (latitude != null) 'latitud': latitude,
    if (longitude != null) 'longitud': longitude,
    if (gpsSessions != null)
      'sesiones_gps': gpsSessions!
          .map((session) => session.toJson())
          .toList(growable: false),
  };
}

class MileageQuality {
  const MileageQuality({
    required this.status,
    required this.method,
    required this.synchronizationVerified,
    required this.pendingPoints,
    required this.gpsSessions,
    required this.consideredPoints,
    required this.discardedPoints,
    required this.pointsWithoutAccuracy,
    required this.validSegments,
    required this.detectedGaps,
    required this.coveredSeconds,
    required this.operationalSeconds,
    required this.specialsWithoutQuality,
    required this.pendingMovements,
    required this.coveragePercentage,
    required this.revision,
    this.updatedAt,
  });

  factory MileageQuality.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sesiones_gps'];
    return MileageQuality(
      status: optionalString(json, 'estado') ?? 'SIN_VERIFICAR',
      method: optionalString(json, 'metodo') ?? 'GPS_FILTRADO',
      synchronizationVerified: optionalBool(json, 'sincronizacion_verificada'),
      pendingPoints: optionalInt(json, 'puntos_pendientes'),
      gpsSessions: rawSessions is List
          ? jsonMapList(
              rawSessions,
              'sesiones GPS',
            ).map(GpsSessionManifest.fromJson).toList(growable: false)
          : const [],
      consideredPoints: optionalInt(json, 'puntos_considerados'),
      discardedPoints: optionalInt(json, 'puntos_descartados'),
      pointsWithoutAccuracy: optionalInt(json, 'puntos_sin_precision'),
      validSegments: optionalInt(json, 'segmentos_validos'),
      detectedGaps: optionalInt(json, 'huecos_detectados'),
      coveredSeconds: _optionalDouble(json, 'segundos_cubiertos') ?? 0,
      operationalSeconds: _optionalDouble(json, 'segundos_operativos') ?? 0,
      specialsWithoutQuality: optionalInt(json, 'especiales_sin_calidad'),
      pendingMovements: optionalInt(json, 'movimientos_pendientes'),
      coveragePercentage: _optionalDouble(json, 'cobertura_porcentaje') ?? 0,
      revision: optionalInt(json, 'revision'),
      updatedAt: optionalDateTime(json, 'actualizada_en'),
    );
  }

  final String status;
  final String method;
  final bool synchronizationVerified;
  final int pendingPoints;
  final List<GpsSessionManifest> gpsSessions;
  final int consideredPoints;
  final int discardedPoints;
  final int pointsWithoutAccuracy;
  final int validSegments;
  final int detectedGaps;
  final double coveredSeconds;
  final double operationalSeconds;
  final int specialsWithoutQuality;
  final int pendingMovements;
  final double coveragePercentage;
  final int revision;
  final DateTime? updatedAt;

  bool get isConsolidated => status == 'CONSOLIDADO';
}

class MileageRevision {
  const MileageRevision({
    required this.id,
    required this.shiftId,
    required this.number,
    required this.reason,
    required this.kilometers,
    required this.quality,
    required this.createdAt,
    this.specialMovementId,
  });

  factory MileageRevision.fromJson(Map<String, dynamic> json) {
    return MileageRevision(
      id: requireString(json, 'id'),
      shiftId: requireString(json, 'jornada_id'),
      specialMovementId: optionalString(json, 'movimiento_especial_id'),
      number: optionalInt(json, 'numero'),
      reason: requireString(json, 'motivo'),
      kilometers: requireString(json, 'kilometros'),
      quality: MileageQuality.fromJson(
        requireJsonMap(json['calidad'], 'calidad'),
      ),
      createdAt: requireDateTime(json, 'creado_en'),
    );
  }

  final String id;
  final String shiftId;
  final String? specialMovementId;
  final int number;
  final String reason;
  final String kilometers;
  final MileageQuality quality;
  final DateTime createdAt;
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class ShiftQuery {
  const ShiftQuery({
    this.driverId,
    this.status,
    this.from,
    this.to,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? driverId;
  final String? status;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    'pagina': page,
    'tamano_pagina': pageSize,
    if (driverId != null) 'repartidor_id': driverId,
    if (status != null) 'estado': status,
    if (from != null) 'desde': from!.toUtc().toIso8601String(),
    if (to != null) 'hasta': to!.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    return other is ShiftQuery &&
        other.driverId == driverId &&
        other.status == status &&
        other.from == from &&
        other.to == to &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(driverId, status, from, to, page, pageSize);
}
