import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/home/models/app_section.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

void main() {
  UserProfile profileWith(List<String> permissions) {
    return UserProfile.fromJson({
      'usuario': {
        'id': 'user-id',
        'correo': 'usuario@empresa.com',
        'nombres': 'Nombre',
        'apellidos': 'Apellido',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa': null,
      'sucursal': null,
      'roles': [],
      'permisos': permissions,
    });
  }

  test('siempre muestra inicio y cuenta', () {
    final sections = AvailableAppSections.forProfile(profileWith([]));

    expect(sections, [AppSection.home, AppSection.account]);
  });

  test('habilita módulos solamente mediante permisos', () {
    final sections = AvailableAppSections.forProfile(
      profileWith(['empresa.ver', 'usuario.ver', 'ubicacion.ver']),
    );

    expect(sections, [
      AppSection.home,
      AppSection.organizations,
      AppSection.users,
      AppSection.locations,
      AppSection.account,
    ]);
  });

  test('muestra operación solo a un perfil de motorista con jornadas', () {
    final profile = UserProfile.fromJson({
      'usuario': {
        'id': 'driver-user-id',
        'correo': 'motorista@empresa.com',
        'nombres': 'Motorista',
        'apellidos': 'Prueba',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa': null,
      'sucursal': null,
      'roles': [
        {
          'codigo': 'REPARTIDOR_CORPORATIVO',
          'nombre': 'Repartidor corporativo',
          'tipo_alcance': 'EMPRESA',
          'empresa_id': 'company-id',
          'sucursal_id': null,
        },
      ],
      'permisos': ['jornada.ver'],
    });

    expect(AvailableAppSections.forProfile(profile), [
      AppSection.home,
      AppSection.operations,
      AppSection.history,
      AppSection.account,
    ]);
  });

  test('muestra solicitudes con cualquiera de sus permisos de lectura', () {
    final sections = AvailableAppSections.forProfile(
      profileWith(['solicitud.ver_asignadas']),
    );

    expect(sections, [
      AppSection.home,
      AppSection.requests,
      AppSection.account,
    ]);
  });

  test('un motorista usa Delivery en lugar de duplicar Solicitudes', () {
    final profile = UserProfile.fromJson({
      'usuario': {
        'id': 'driver-user-id',
        'correo': 'motorista@empresa.com',
        'nombres': 'Motorista',
        'apellidos': 'Prueba',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa': null,
      'sucursal': null,
      'roles': [
        {
          'codigo': 'REPARTIDOR_CORPORATIVO',
          'nombre': 'Repartidor corporativo',
          'tipo_alcance': 'EMPRESA',
          'empresa_id': 'company-id',
          'sucursal_id': null,
        },
      ],
      'permisos': ['jornada.ver', 'solicitud.ver_asignadas'],
    });

    expect(AvailableAppSections.forProfile(profile), [
      AppSection.home,
      AppSection.operations,
      AppSection.history,
      AppSection.account,
    ]);
  });
}
