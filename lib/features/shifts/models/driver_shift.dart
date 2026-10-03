import 'package:vitago_app/core/models/json_readers.dart';

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
  });

  factory DriverShift.fromJson(Map<String, dynamic> json) {
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
  final int reportedIncidents;
  final bool incidentsAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVA';
}

class ShiftCoordinatesInput {
  const ShiftCoordinatesInput({this.latitude, this.longitude});

  final String? latitude;
  final String? longitude;

  Map<String, dynamic> toJson() => {
    if (latitude != null) 'latitud': latitude,
    if (longitude != null) 'longitud': longitude,
  };
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
