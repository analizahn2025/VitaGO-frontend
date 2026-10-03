import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';

void main() {
  test('convierte la relación de ubicación autorizada', () {
    final item = CompanyLocation.fromJson({
      'id': 'relation-id',
      'empresa_id': 'company-id',
      'permite_origen': true,
      'permite_destino': false,
      'estado': 'APROBADO',
      'ubicacion': {
        'id': 'location-id',
        'nombre': 'Clínica Central',
        'origen': 'REGISTRADA_USUARIO',
        'departamento': 'Francisco Morazán',
        'municipio': 'Distrito Central',
        'ciudad': 'Tegucigalpa',
        'colonia': 'Colonia Palmira',
        'direccion': 'Dirección registrada',
        'latitud': '14.072300',
        'longitud': '-87.192100',
        'verificada': false,
        'estado': 'ACTIVO',
      },
    });

    expect(item.isApproved, isTrue);
    expect(item.allowsOrigin, isTrue);
    expect(item.location.name, 'Clínica Central');
    expect(item.location.department, 'Francisco Morazán');
    expect(item.location.municipality, 'Distrito Central');
    expect(item.location.city, 'Tegucigalpa');
    expect(item.location.neighborhood, 'Colonia Palmira');
  });

  test('serializa el registro manual sin campos de Google', () {
    const input = CreateLocationInput(
      companyId: 'company-id',
      name: 'Clínica Central',
      locationTypeId: 'type-id',
      countryId: 'country-id',
      department: ' Francisco Morazán ',
      municipality: 'Distrito Central',
      city: 'Tegucigalpa',
      neighborhood: 'Colonia Palmira',
      address: 'Dirección registrada',
      latitude: '14.072300',
      longitude: '-87.192100',
      allowsOrigin: true,
      allowsDestination: true,
    );

    final json = input.toJson();

    expect(json['origen'], 'REGISTRADA_USUARIO');
    expect(json.containsKey('identificador_lugar_google'), isFalse);
    expect(json['departamento'], 'Francisco Morazán');
    expect(json['municipio'], 'Distrito Central');
    expect(json['ciudad'], 'Tegucigalpa');
    expect(json['colonia'], 'Colonia Palmira');
    expect(json.containsKey('nivel_administrativo_1'), isFalse);
    expect(json.containsKey('nivel_administrativo_2'), isFalse);
    expect(json.containsKey('localidad'), isFalse);
    expect(json['permite_destino'], isTrue);
  });

  test('serializa únicamente los campos documentados de autorización', () {
    const input = LocationAuthorizationInput(
      allowsOrigin: true,
      allowsDestination: false,
      status: 'APROBADO',
    );

    expect(input.toJson(), {
      'permite_origen': true,
      'permite_destino': false,
      'estado': 'APROBADO',
    });
  });
}
