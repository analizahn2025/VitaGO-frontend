import 'package:vitago_app/core/models/json_readers.dart';

class RequestCreationOptions {
  const RequestCreationOptions({
    required this.companyId,
    required this.canCreateSpecial,
    required this.modalities,
    required this.origins,
    required this.destinations,
    this.branchId,
    this.selectedModality,
    this.availabilityMessage,
  });

  factory RequestCreationOptions.fromJson(Map<String, dynamic> json) {
    return RequestCreationOptions(
      companyId: requireString(json, 'empresa_id'),
      branchId: optionalString(json, 'sucursal_id'),
      selectedModality: optionalString(json, 'modalidad_seleccionada'),
      availabilityMessage: optionalString(json, 'mensaje_disponibilidad'),
      canCreateSpecial: optionalBool(json, 'puede_crear_envio_especial'),
      modalities: jsonMapList(
        json['modalidades'],
        'modalidades',
      ).map(RequestCreationModality.fromJson).toList(growable: false),
      origins: jsonMapList(
        json['origenes'],
        'origenes',
      ).map(RequestCreationLocationOption.fromJson).toList(growable: false),
      destinations: jsonMapList(
        json['destinos'],
        'destinos',
      ).map(RequestCreationLocationOption.fromJson).toList(growable: false),
    );
  }

  final String companyId;
  final String? branchId;
  final String? selectedModality;
  final String? availabilityMessage;
  final bool canCreateSpecial;
  final List<RequestCreationModality> modalities;
  final List<RequestCreationLocationOption> origins;
  final List<RequestCreationLocationOption> destinations;
}

class RequestCreationModality {
  const RequestCreationModality({
    required this.code,
    required this.name,
    required this.requiresRegisteredDestination,
    required this.routePresentation,
  });

  factory RequestCreationModality.fromJson(Map<String, dynamic> json) {
    return RequestCreationModality(
      code: requireString(json, 'codigo'),
      name: requireString(json, 'nombre'),
      requiresRegisteredDestination: optionalBool(
        json,
        'requiere_destino_registrado',
      ),
      routePresentation: requireString(json, 'presentacion_ruta'),
    );
  }

  final String code;
  final String name;
  final bool requiresRegisteredDestination;
  final String routePresentation;
}

class RequestCreationLocationOption {
  const RequestCreationLocationOption({
    required this.location,
    this.branchId,
    this.branchName,
  });

  factory RequestCreationLocationOption.fromJson(Map<String, dynamic> json) {
    return RequestCreationLocationOption(
      branchId: optionalString(json, 'sucursal_id'),
      branchName: optionalString(json, 'sucursal_nombre'),
      location: RequestCreationLocation.fromJson(
        requireJsonMap(json['ubicacion'], 'ubicacion'),
      ),
    );
  }

  final String? branchId;
  final String? branchName;
  final RequestCreationLocation location;

  String get displayName => branchName ?? location.name;
}

class RequestCreationLocation {
  const RequestCreationLocation({
    required this.id,
    required this.name,
    required this.typeCode,
    required this.address,
    this.department,
    this.municipality,
    this.city,
    this.neighborhood,
    this.latitude,
    this.longitude,
  });

  factory RequestCreationLocation.fromJson(Map<String, dynamic> json) {
    return RequestCreationLocation(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      typeCode: requireString(json, 'tipo_codigo'),
      department: optionalString(json, 'departamento'),
      municipality: optionalString(json, 'municipio'),
      city: optionalString(json, 'ciudad'),
      neighborhood: optionalString(json, 'colonia'),
      address: requireString(json, 'direccion'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
    );
  }

  final String id;
  final String name;
  final String typeCode;
  final String? department;
  final String? municipality;
  final String? city;
  final String? neighborhood;
  final String address;
  final String? latitude;
  final String? longitude;
}
