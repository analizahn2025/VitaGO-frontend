import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';

void main() {
  test('convierte un usuario administrable con roles', () {
    final user = ManagedUser.fromJson({
      'id': 'user-id',
      'correo': 'usuario@empresa.com',
      'nombres': 'Nombre',
      'apellidos': 'Apellido',
      'telefono': null,
      'empresa_id': 'company-id',
      'sucursal_id': null,
      'estado': 'ACTIVO',
      'roles': [
        {
          'codigo': 'SOLICITANTE_EXTERNO',
          'nombre': 'Solicitante externo',
          'tipo_alcance': 'EMPRESA',
          'empresa_id': 'company-id',
          'sucursal_id': null,
        },
      ],
      'creado_en': '2026-09-24T16:00:00Z',
    });

    expect(user.fullName, 'Nombre Apellido');
    expect(user.roles.single.code, 'SOLICITANTE_EXTERNO');
    expect(user.createdAt, isNotNull);
  });

  test('envía contraseña temporal solamente con proveedor local', () {
    const input = CreateUserInput(
      email: 'usuario@empresa.com',
      firstNames: 'Nombre',
      lastNames: 'Apellido',
      temporaryPassword: 'secreto-temporal',
      externalAuthenticationId: 'corporate-123',
      roleCode: 'SOLICITANTE_EXTERNO',
      scopeType: ScopeType.company,
      companyId: 'company-id',
    );

    final json = input.toJson(usesLocalAuthentication: true);

    expect(json['contrasena_temporal'], 'secreto-temporal');
    expect(json.containsKey('identificador_autenticacion_externa'), isFalse);
  });

  test('envía identificador externo sin contraseña con JWT corporativo', () {
    const input = CreateUserInput(
      email: 'usuario@empresa.com',
      firstNames: 'Nombre',
      lastNames: 'Apellido',
      temporaryPassword: 'no-enviar',
      externalAuthenticationId: 'corporate-123',
      roleCode: 'CORPORATE_REQUESTER',
      scopeType: ScopeType.global,
    );

    final json = input.toJson(usesLocalAuthentication: false);

    expect(json['identificador_autenticacion_externa'], 'corporate-123');
    expect(json.containsKey('contrasena_temporal'), isFalse);
    expect(json.containsKey('empresa_id'), isFalse);
  });

  test('construye parámetros de roles según el alcance', () {
    const query = AssignableRolesQuery(
      scopeType: ScopeType.branch,
      companyId: 'company-id',
      branchId: 'branch-id',
    );

    expect(query.toQueryParameters(), {
      'tipo_alcance': 'SUCURSAL',
      'empresa_id': 'company-id',
      'sucursal_id': 'branch-id',
    });
  });

  test('construye los cambios permitidos de un usuario', () {
    const input = UpdateUserInput(
      firstNames: ' Nombre ',
      lastNames: ' Apellido ',
      phone: ' ',
      status: 'SUSPENDIDO',
    );

    expect(input.toJson(), {
      'nombres': 'Nombre',
      'apellidos': 'Apellido',
      'telefono': null,
      'estado': 'SUSPENDIDO',
    });
  });

  test('convierte una asignación de rol con trazabilidad', () {
    final assignment = UserRoleAssignment.fromJson({
      'id': 'assignment-id',
      'rol': {
        'codigo': 'SOLICITANTE_EXTERNO',
        'nombre': 'Solicitante externo',
        'descripcion': 'Solicitudes de una empresa externa.',
        'permite_alcance_global': false,
        'permite_alcance_empresa': true,
        'permite_alcance_sucursal': true,
      },
      'tipo_alcance': 'EMPRESA',
      'empresa_id': 'company-id',
      'sucursal_id': null,
      'activo': false,
      'asignado_por_id': 'admin-id',
      'asignado_en': '2026-09-24T18:00:00Z',
      'revocado_por_id': 'admin-id',
      'revocado_en': '2026-09-25T18:00:00Z',
    });

    expect(assignment.role.allowsCompanyScope, isTrue);
    expect(assignment.scopeType, ScopeType.company);
    expect(assignment.active, isFalse);
    expect(assignment.revokedAt, isNotNull);
  });

  test('construye una asignación de rol según el alcance', () {
    const input = AssignUserRoleInput(
      roleCode: 'SOLICITANTE_EXTERNO',
      scopeType: ScopeType.branch,
      companyId: 'company-id',
      branchId: 'branch-id',
    );

    expect(input.toJson(), {
      'rol_codigo': 'SOLICITANTE_EXTERNO',
      'tipo_alcance': 'SUCURSAL',
      'empresa_id': 'company-id',
      'sucursal_id': 'branch-id',
    });
  });
}
