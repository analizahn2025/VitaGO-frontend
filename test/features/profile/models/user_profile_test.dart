import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

void main() {
  test('convierte perfil, roles y permisos documentados', () {
    final profile = UserProfile.fromJson({
      'usuario': {
        'id': 'user-id',
        'correo': 'usuario@empresa.com',
        'nombres': 'Nombre',
        'apellidos': 'Apellido',
        'telefono': '+50499999999',
        'estado': 'ACTIVO',
      },
      'empresa': {'id': 'company-id', 'nombre': 'Analiza'},
      'sucursal': null,
      'roles': [
        {
          'codigo': 'ADMIN',
          'nombre': 'Administrador',
          'tipo_alcance': 'EMPRESA',
          'empresa_id': 'company-id',
          'sucursal_id': null,
        },
      ],
      'permisos': ['usuario.ver', 'ubicacion.ver', 'usuario.ver'],
    });

    expect(profile.user.fullName, 'Nombre Apellido');
    expect(profile.company?.name, 'Analiza');
    expect(profile.branch, isNull);
    expect(profile.roles.single.scopeType, ScopeType.company);
    expect(profile.permissions.length, 2);
    expect(profile.can(AppPermissions.viewUsers), isTrue);
    expect(profile.can(AppPermissions.manageUsers), isFalse);
    expect(profile.isMasterAdmin, isFalse);
  });

  test('acepta usuario sin empresa, roles ni permisos', () {
    final profile = UserProfile.fromJson({
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
      'permisos': [],
    });

    expect(profile.company, isNull);
    expect(profile.roles, isEmpty);
    expect(profile.permissions, isEmpty);
  });

  test('identifica únicamente el rol maestro documentado', () {
    final profile = UserProfile.fromJson({
      'usuario': {
        'id': 'master-id',
        'correo': 'master@vitago.com',
        'nombres': 'Admin',
        'apellidos': 'Maestro',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa': null,
      'sucursal': null,
      'roles': [
        {
          'codigo': 'SUPERADMINISTRADOR',
          'nombre': 'Administrador maestro',
          'tipo_alcance': 'GLOBAL',
          'empresa_id': null,
          'sucursal_id': null,
        },
      ],
      'permisos': ['usuario.ver', 'empresa.ver'],
    });

    expect(profile.isMasterAdmin, isTrue);
  });
}
