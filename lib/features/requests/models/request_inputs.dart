import 'package:vitago_app/features/tracking/models/tracking_point.dart';

class CreateServiceRequestInput {
  const CreateServiceRequestInput({
    required this.companyId,
    required this.priority,
    required this.modality,
    required this.serviceTypeId,
    required this.originId,
    required this.tubeCount,
    required this.flaskCount,
    this.branchId,
    this.destinationId,
    this.specialDestination,
    this.notes,
  });

  final String companyId;
  final String? branchId;
  final String priority;
  final String modality;
  final String serviceTypeId;
  final String originId;
  final String? destinationId;
  final String? specialDestination;
  final String? notes;
  final int tubeCount;
  final int flaskCount;

  Map<String, dynamic> toJson() => {
    'empresa_id': companyId,
    'sucursal_id': _nullable(branchId),
    'prioridad': priority,
    'modalidad': modality,
    'tipo_servicio_id': serviceTypeId,
    'origen_id': originId,
    'destino_id': _nullable(destinationId),
    'destino_especial': _nullable(specialDestination),
    'notas': _nullable(notes),
    'cantidad_tubos': tubeCount,
    'cantidad_frascos': flaskCount,
  };
}

class UpdateRequestLoadInput {
  const UpdateRequestLoadInput({
    required this.reason,
    this.tubeCount,
    this.flaskCount,
  });

  final int? tubeCount;
  final int? flaskCount;
  final String reason;

  Map<String, dynamic> toJson() => {
    if (tubeCount != null) 'cantidad_tubos': tubeCount,
    if (flaskCount != null) 'cantidad_frascos': flaskCount,
    'motivo': reason.trim(),
  };
}

class RequestAssignmentInput {
  const RequestAssignmentInput({required this.driverId, this.reason});

  final String driverId;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'repartidor_id': driverId,
    'motivo': _nullable(reason),
  };
}

class RequestTransitionInput {
  const RequestTransitionInput({
    required this.targetStatus,
    this.latitude,
    this.longitude,
    this.reason,
    this.gpsSessions,
  });

  final String targetStatus;
  final String? latitude;
  final String? longitude;
  final String? reason;
  final List<GpsSessionManifest>? gpsSessions;

  Map<String, dynamic> toJson() => {
    'estado_destino': targetStatus,
    'latitud': _nullable(latitude),
    'longitud': _nullable(longitude),
    'motivo': _nullable(reason),
    if (gpsSessions != null)
      'sesiones_gps': gpsSessions!
          .map((session) => session.toJson())
          .toList(growable: false),
  };
}

class GpsSynchronizationInput {
  const GpsSynchronizationInput(this.sessions, {this.movementId});

  final List<GpsSessionManifest> sessions;
  final String? movementId;

  Map<String, dynamic> toJson() => {
    if (movementId != null) 'movimiento_id': movementId,
    'sesiones_gps': sessions
        .map((session) => session.toJson())
        .toList(growable: false),
  };
}

class RequestQuery {
  const RequestQuery({
    this.companyId,
    this.branchId,
    this.priority,
    this.status,
    this.modality,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? companyId;
  final String? branchId;
  final String? priority;
  final String? status;
  final String? modality;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    'pagina': page,
    'tamano_pagina': pageSize,
    if (companyId != null) 'empresa_id': companyId,
    if (branchId != null) 'sucursal_id': branchId,
    if (priority != null) 'prioridad': priority,
    if (status != null) 'estado': status,
    if (modality != null) 'modalidad': modality,
  };

  @override
  bool operator ==(Object other) {
    return other is RequestQuery &&
        other.companyId == companyId &&
        other.branchId == branchId &&
        other.priority == priority &&
        other.status == status &&
        other.modality == modality &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    branchId,
    priority,
    status,
    modality,
    page,
    pageSize,
  );
}

class RequestCreationOptionsQuery {
  const RequestCreationOptionsQuery({
    required this.companyId,
    this.branchId,
    this.modality,
    this.originId,
  });

  final String companyId;
  final String? branchId;
  final String? modality;
  final String? originId;

  Map<String, dynamic> toQueryParameters() => {
    'empresa_id': companyId,
    if (branchId != null) 'sucursal_id': branchId,
    if (modality != null) 'modalidad': modality,
    if (originId != null) 'origen_id': originId,
  };

  @override
  bool operator ==(Object other) {
    return other is RequestCreationOptionsQuery &&
        other.companyId == companyId &&
        other.branchId == branchId &&
        other.modality == modality &&
        other.originId == originId;
  }

  @override
  int get hashCode => Object.hash(companyId, branchId, modality, originId);
}

class RequesterSummaryQuery {
  const RequesterSummaryQuery({this.companyId, this.branchId});

  final String? companyId;
  final String? branchId;

  Map<String, dynamic> toQueryParameters() => {
    if (companyId != null) 'empresa_id': companyId,
    if (branchId != null) 'sucursal_id': branchId,
  };

  @override
  bool operator ==(Object other) {
    return other is RequesterSummaryQuery &&
        other.companyId == companyId &&
        other.branchId == branchId;
  }

  @override
  int get hashCode => Object.hash(companyId, branchId);
}

String? _nullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
