import 'package:vitago_app/core/models/json_readers.dart';

class Branch {
  const Branch({
    required this.id,
    required this.companyId,
    required this.name,
    required this.status,
    this.code,
    this.phone,
    this.email,
    this.location,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    final locationJson = optionalJsonMap(json, 'ubicacion');
    return Branch(
      id: requireString(json, 'id'),
      companyId: requireString(json, 'empresa_id'),
      name: requireString(json, 'nombre'),
      code: optionalString(json, 'codigo'),
      phone: optionalString(json, 'telefono'),
      email: optionalString(json, 'correo'),
      status: requireString(json, 'estado'),
      location: locationJson == null
          ? null
          : BranchLocation.fromJson(locationJson),
    );
  }

  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? phone;
  final String? email;
  final String status;
  final BranchLocation? location;
}

class BranchLocation {
  const BranchLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    this.latitude,
    this.longitude,
    this.typeName,
  });

  factory BranchLocation.fromJson(Map<String, dynamic> json) {
    final typeJson = optionalJsonMap(json, 'tipo_ubicacion');
    return BranchLocation(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      address: requireString(json, 'direccion'),
      latitude: optionalString(json, 'latitud'),
      longitude: optionalString(json, 'longitud'),
      status: requireString(json, 'estado'),
      typeName: typeJson == null ? null : optionalString(typeJson, 'nombre'),
    );
  }

  final String id;
  final String name;
  final String address;
  final String? latitude;
  final String? longitude;
  final String status;
  final String? typeName;
}

class CreateBranchInput {
  const CreateBranchInput({
    required this.name,
    required this.locationId,
    this.code,
    this.phone,
    this.email,
  });

  final String name;
  final String locationId;
  final String? code;
  final String? phone;
  final String? email;

  Map<String, dynamic> toJson() => {
    'nombre': name.trim(),
    'codigo': _nullable(code)?.toUpperCase(),
    'ubicacion_id': locationId,
    'telefono': _nullable(phone),
    'correo': _nullable(email),
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
