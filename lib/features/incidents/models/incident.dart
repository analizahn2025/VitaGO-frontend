import 'package:vitago_app/core/models/json_readers.dart';

class Incident {
  const Incident({
    required this.id,
    required this.shiftId,
    required this.driverId,
    required this.status,
    required this.description,
    required this.reportedAt,
    required this.events,
    this.requestId,
    this.latitude,
    this.longitude,
    this.reviewedById,
    this.reviewedAt,
    this.closedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['eventos'];
    return Incident(
      id: requireString(json, 'id'),
      shiftId: requireString(json, 'jornada_id'),
      driverId: requireString(json, 'repartidor_id'),
      requestId: optionalString(json, 'solicitud_id'),
      status: requireString(json, 'estado'),
      description: requireString(json, 'descripcion'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
      reportedAt: requireDateTime(json, 'reportada_en'),
      reviewedById: optionalString(json, 'revisada_por_id'),
      reviewedAt: optionalDateTime(json, 'revisada_en'),
      closedAt: optionalDateTime(json, 'cerrada_en'),
      events: rawEvents is List
          ? jsonMapList(
              rawEvents,
              'eventos de incidencia',
            ).map(IncidentEvent.fromJson).toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String shiftId;
  final String driverId;
  final String? requestId;
  final String status;
  final String description;
  final String? latitude;
  final String? longitude;
  final DateTime reportedAt;
  final String? reviewedById;
  final DateTime? reviewedAt;
  final DateTime? closedAt;
  final List<IncidentEvent> events;

  bool get isClosed => status.toUpperCase() == 'CERRADA';
}

class IncidentEvent {
  const IncidentEvent({
    required this.type,
    this.id,
    this.previousStatus,
    this.newStatus,
    this.performedById,
    this.notes,
    this.metadata,
    this.createdAt,
  });

  factory IncidentEvent.fromJson(Map<String, dynamic> json) {
    return IncidentEvent(
      id: optionalString(json, 'id'),
      type: requireString(json, 'tipo'),
      previousStatus: optionalString(json, 'estado_anterior'),
      newStatus: optionalString(json, 'estado_nuevo'),
      performedById: optionalString(json, 'realizado_por_id'),
      notes: optionalString(json, 'notas'),
      metadata: optionalJsonMap(json, 'metadatos'),
      createdAt: optionalDateTime(json, 'creado_en'),
    );
  }

  final String? id;
  final String type;
  final String? previousStatus;
  final String? newStatus;
  final String? performedById;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
}

class CreateIncidentInput {
  const CreateIncidentInput({
    required this.description,
    required this.reportedAt,
    this.requestId,
    this.latitude,
    this.longitude,
  });

  final String? requestId;
  final String description;
  final String? latitude;
  final String? longitude;
  final DateTime reportedAt;

  Map<String, dynamic> toJson() => {
    'solicitud_id': _nullable(requestId),
    'descripcion': description.trim(),
    'latitud': _nullable(latitude),
    'longitud': _nullable(longitude),
    'reportada_en': reportedAt.toUtc().toIso8601String(),
  };
}

class ReviewIncidentInput {
  const ReviewIncidentInput({required this.status, this.notes});

  final String status;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'estado': status,
    'notas': _nullable(notes),
  };
}

class IncidentQuery {
  const IncidentQuery({
    this.status,
    this.shiftId,
    this.requestId,
    this.driverId,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? status;
  final String? shiftId;
  final String? requestId;
  final String? driverId;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    'pagina': page,
    'tamano_pagina': pageSize,
    if (status != null) 'estado': status,
    if (shiftId != null) 'jornada_id': shiftId,
    if (requestId != null) 'solicitud_id': requestId,
    if (driverId != null) 'repartidor_id': driverId,
  };

  @override
  bool operator ==(Object other) {
    return other is IncidentQuery &&
        other.status == status &&
        other.shiftId == shiftId &&
        other.requestId == requestId &&
        other.driverId == driverId &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode =>
      Object.hash(status, shiftId, requestId, driverId, page, pageSize);
}

String? _nullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
