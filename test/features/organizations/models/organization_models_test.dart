import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';

void main() {
  test('convierte la empresa con su país', () {
    final company = Company.fromJson({
      'id': 'company-id',
      'nombre': 'Analiza',
      'razon_social': null,
      'identificacion_fiscal': null,
      'telefono': null,
      'correo': null,
      'pais': {
        'id': 'country-id',
        'iso2': 'HN',
        'nombre': 'Honduras',
        'codigo_moneda': 'HNL',
        'zona_horaria_predeterminada': 'America/Tegucigalpa',
      },
      'estado': 'ACTIVO',
    });

    expect(company.name, 'Analiza');
    expect(company.country?.iso2, 'HN');
  });

  test('convierte una sucursal con ubicación', () {
    final branch = Branch.fromJson({
      'id': 'branch-id',
      'empresa_id': 'company-id',
      'nombre': 'Principal',
      'codigo': 'SPS-01',
      'telefono': null,
      'correo': null,
      'estado': 'ACTIVO',
      'ubicacion': {
        'id': 'location-id',
        'nombre': 'Sede principal',
        'tipo_ubicacion': {
          'id': 'type-id',
          'codigo': 'SUCURSAL',
          'nombre': 'Sucursal',
        },
        'direccion': 'Dirección registrada',
        'latitud': '14.072300',
        'longitud': '-87.192100',
        'estado': 'ACTIVO',
      },
    });

    expect(branch.code, 'SPS-01');
    expect(branch.location?.typeName, 'Sucursal');
  });

  test('normaliza el código al preparar una sucursal', () {
    const input = CreateBranchInput(
      name: 'Principal',
      code: 'tgu-01',
      locationId: 'location-id',
    );

    expect(input.toJson()['codigo'], 'TGU-01');
    expect(input.toJson()['ubicacion_id'], 'location-id');
  });
}
