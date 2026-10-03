import 'package:vitago_app/core/models/json_readers.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.companyId,
    this.brand,
    this.model,
    this.year,
    this.loadCapacityKg,
    this.notes,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: requireString(json, 'id'),
      companyId: optionalString(json, 'empresa_id'),
      plate: requireString(json, 'placa'),
      type: requireString(json, 'tipo'),
      brand: optionalString(json, 'marca'),
      model: optionalString(json, 'modelo'),
      year: json['anio'] == null ? null : optionalInt(json, 'anio'),
      loadCapacityKg: optionalString(json, 'capacidad_carga_kg'),
      status: requireString(json, 'estado'),
      notes: optionalString(json, 'notas'),
      createdAt: requireDateTime(json, 'creado_en'),
      updatedAt: requireDateTime(json, 'actualizado_en'),
    );
  }

  final String id;
  final String? companyId;
  final String plate;
  final String type;
  final String? brand;
  final String? model;
  final int? year;
  final String? loadCapacityKg;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final description = [brand, model].whereType<String>().join(' ');
    return description.isEmpty ? plate : '$plate · $description';
  }
}

class DriverUser {
  const DriverUser({
    required this.id,
    required this.email,
    required this.firstNames,
    required this.lastNames,
    required this.status,
    this.phone,
  });

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    return DriverUser(
      id: requireString(json, 'id'),
      email: requireString(json, 'correo'),
      firstNames: requireString(json, 'nombres'),
      lastNames: requireString(json, 'apellidos'),
      phone: optionalString(json, 'telefono'),
      status: requireString(json, 'estado'),
    );
  }

  final String id;
  final String email;
  final String firstNames;
  final String lastNames;
  final String? phone;
  final String status;

  String get fullName => '$firstNames $lastNames'.trim();
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.user,
    required this.operationalStatus,
    required this.capacity,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.activeRequests = 0,
    this.requestLimit = 5,
    this.canReceiveRequests = false,
    this.companyId,
    this.vehicle,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final vehicleJson = optionalJsonMap(json, 'vehiculo');
    return DriverProfile(
      id: requireString(json, 'id'),
      user: DriverUser.fromJson(requireJsonMap(json['usuario'], 'usuario')),
      companyId: optionalString(json, 'empresa_id'),
      vehicle: vehicleJson == null ? null : Vehicle.fromJson(vehicleJson),
      operationalStatus: requireString(json, 'estado_operativo'),
      capacity: requireString(json, 'capacidad'),
      activeRequests: optionalInt(json, 'solicitudes_activas'),
      requestLimit: optionalInt(json, 'limite_solicitudes', fallback: 5),
      canReceiveRequests: optionalBool(json, 'puede_recibir_solicitudes'),
      active: optionalBool(json, 'activo'),
      createdAt: requireDateTime(json, 'creado_en'),
      updatedAt: requireDateTime(json, 'actualizado_en'),
    );
  }

  final String id;
  final DriverUser user;
  final String? companyId;
  final Vehicle? vehicle;
  final String operationalStatus;
  final String capacity;
  final int activeRequests;
  final int requestLimit;
  final bool canReceiveRequests;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class VehicleQuery {
  const VehicleQuery({
    this.companyId,
    this.status,
    this.type,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? companyId;
  final String? status;
  final String? type;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    'pagina': page,
    'tamano_pagina': pageSize,
    if (companyId != null) 'empresa_id': companyId,
    if (status != null) 'estado': status,
    if (type != null) 'tipo': type,
  };

  @override
  bool operator ==(Object other) {
    return other is VehicleQuery &&
        other.companyId == companyId &&
        other.status == status &&
        other.type == type &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(companyId, status, type, page, pageSize);
}

class DriverQuery {
  const DriverQuery({
    this.companyId,
    this.operationalStatus,
    this.capacity,
    this.active,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? companyId;
  final String? operationalStatus;
  final String? capacity;
  final bool? active;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
    'pagina': page,
    'tamano_pagina': pageSize,
    if (companyId != null) 'empresa_id': companyId,
    if (operationalStatus != null) 'estado_operativo': operationalStatus,
    if (capacity != null) 'capacidad': capacity,
    if (active != null) 'activo': active,
  };

  @override
  bool operator ==(Object other) {
    return other is DriverQuery &&
        other.companyId == companyId &&
        other.operationalStatus == operationalStatus &&
        other.capacity == capacity &&
        other.active == active &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    operationalStatus,
    capacity,
    active,
    page,
    pageSize,
  );
}
