import 'package:vitago_app/core/models/json_readers.dart';

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.status,
    this.legalName,
    this.taxId,
    this.phone,
    this.email,
    this.country,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    final countryJson = optionalJsonMap(json, 'pais');
    return Company(
      id: requireString(json, 'id'),
      name: requireString(json, 'nombre'),
      legalName: optionalString(json, 'razon_social'),
      taxId: optionalString(json, 'identificacion_fiscal'),
      phone: optionalString(json, 'telefono'),
      email: optionalString(json, 'correo'),
      country: countryJson == null ? null : Country.fromJson(countryJson),
      status: requireString(json, 'estado'),
    );
  }

  final String id;
  final String name;
  final String? legalName;
  final String? taxId;
  final String? phone;
  final String? email;
  final Country? country;
  final String status;
}

class Country {
  const Country({
    required this.id,
    required this.iso2,
    required this.name,
    required this.currencyCode,
    required this.defaultTimeZone,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: requireString(json, 'id'),
      iso2: requireString(json, 'iso2'),
      name: requireString(json, 'nombre'),
      currencyCode: requireString(json, 'codigo_moneda'),
      defaultTimeZone: requireString(json, 'zona_horaria_predeterminada'),
    );
  }

  final String id;
  final String iso2;
  final String name;
  final String currencyCode;
  final String defaultTimeZone;
}
