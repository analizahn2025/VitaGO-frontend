class CreateLocationInput {
  const CreateLocationInput({
    required this.companyId,
    required this.name,
    required this.locationTypeId,
    required this.countryId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.allowsOrigin,
    required this.allowsDestination,
    this.department,
    this.municipality,
    this.city,
    this.neighborhood,
    this.phone,
    this.contactName,
    this.openingHours,
    this.instructions,
  });

  final String companyId;
  final String name;
  final String locationTypeId;
  final String countryId;
  final String? department;
  final String? municipality;
  final String? city;
  final String? neighborhood;
  final String address;
  final String latitude;
  final String longitude;
  final String? phone;
  final String? contactName;
  final String? openingHours;
  final String? instructions;
  final bool allowsOrigin;
  final bool allowsDestination;

  Map<String, dynamic> toJson() => {
    'empresa_id': companyId,
    'nombre': name.trim(),
    'tipo_ubicacion_id': locationTypeId,
    'origen': 'REGISTRADA_USUARIO',
    'pais_id': countryId,
    'departamento': _nullable(department),
    'municipio': _nullable(municipality),
    'ciudad': _nullable(city),
    'colonia': _nullable(neighborhood),
    'direccion': address.trim(),
    'latitud': latitude.trim(),
    'longitud': longitude.trim(),
    'telefono': _nullable(phone),
    'nombre_contacto': _nullable(contactName),
    'horario_atencion': _nullable(openingHours),
    'instrucciones': _nullable(instructions),
    'permite_origen': allowsOrigin,
    'permite_destino': allowsDestination,
  };

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class LocationAuthorizationInput {
  const LocationAuthorizationInput({
    required this.allowsOrigin,
    required this.allowsDestination,
    required this.status,
  });

  final bool allowsOrigin;
  final bool allowsDestination;
  final String status;

  Map<String, dynamic> toJson() => {
    'permite_origen': allowsOrigin,
    'permite_destino': allowsDestination,
    'estado': status,
  };
}
