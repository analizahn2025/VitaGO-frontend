import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';

class Location {
  const Location({
    required this.id,
    required this.name,
    required this.source,
    required this.address,
    required this.status,
    required this.verified,
    this.type,
    this.googlePlaceId,
    this.countryId,
    this.countryName,
    this.department,
    this.municipality,
    this.city,
    this.neighborhood,
    this.latitude,
    this.longitude,
    this.phone,
    this.contactName,
    this.openingHours,
    this.instructions,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    final typeJson = optionalJsonMap(json, 'tipo_ubicacion');
    final countryJson = optionalJsonMap(json, 'pais');
    return Location(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      type: typeJson == null ? null : LocationType.fromJson(typeJson),
      source: requireString(json, 'origen'),
      googlePlaceId: optionalString(json, 'identificador_lugar_google'),
      countryId: countryJson == null
          ? optionalString(json, 'pais_id')
          : optionalString(countryJson, 'id'),
      countryName: countryJson == null
          ? null
          : optionalString(countryJson, 'nombre'),
      department: optionalString(json, 'departamento'),
      municipality: optionalString(json, 'municipio'),
      city: optionalString(json, 'ciudad'),
      neighborhood: optionalString(json, 'colonia'),
      address: requireString(json, 'direccion'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
      phone: optionalString(json, 'telefono'),
      contactName: optionalString(json, 'nombre_contacto'),
      openingHours: json['horario_atencion'],
      instructions: optionalString(json, 'instrucciones'),
      verified: optionalBool(json, 'verificada'),
      status: requireString(json, 'estado'),
    );
  }

  final String id;
  final String name;
  final LocationType? type;
  final String source;
  final String? googlePlaceId;
  final String? countryId;
  final String? countryName;
  final String? department;
  final String? municipality;
  final String? city;
  final String? neighborhood;
  final String address;
  final String? latitude;
  final String? longitude;
  final String? phone;
  final String? contactName;
  final Object? openingHours;
  final String? instructions;
  final bool verified;
  final String status;
}

class CompanyLocation {
  const CompanyLocation({
    required this.id,
    required this.companyId,
    required this.allowsOrigin,
    required this.allowsDestination,
    required this.status,
    required this.location,
  });

  factory CompanyLocation.fromJson(Map<String, dynamic> json) {
    return CompanyLocation(
      id: requireString(json, 'id'),
      companyId: requireString(json, 'empresa_id'),
      allowsOrigin: optionalBool(json, 'permite_origen'),
      allowsDestination: optionalBool(json, 'permite_destino'),
      status: requireString(json, 'estado'),
      location: Location.fromJson(
        requireJsonMap(json['ubicacion'], 'ubicacion'),
      ),
    );
  }

  final String id;
  final String companyId;
  final bool allowsOrigin;
  final bool allowsDestination;
  final String status;
  final Location location;

  bool get isApproved => status.toUpperCase() == 'APROBADO';
}
