import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/app_roles.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/policies/user_management_policy.dart';

void main() {
  UserProfile actor(String roleCode) => UserProfile(
    user: const ProfileUser(
      id: 'actor-id',
      email: 'actor@vitago.test',
      firstNames: 'Actor',
      lastNames: 'Prueba',
      status: 'ACTIVO',
    ),
    roles: [
      ScopedRole(
        code: roleCode,
        name: roleCode,
        scopeType: ScopeType.company,
        companyId: 'company-id',
      ),
    ],
    permissions: const [AppPermissions.manageUsers, AppPermissions.assignRoles],
  );

  ManagedUser target(String roleCode) => ManagedUser(
    id: 'target-id',
    email: 'target@vitago.test',
    firstNames: 'Usuario',
    lastNames: 'Objetivo',
    status: 'ACTIVO',
    companyId: 'company-id',
    roles: [
      ScopedRole(
        code: roleCode,
        name: roleCode,
        scopeType: ScopeType.company,
        companyId: 'company-id',
      ),
    ],
  );

  test('el gerente de operaciones puede administrar usuarios operativos', () {
    final canManage = UserManagementPolicy.canManage(
      actor(AppRoles.operationsManager),
      target('REPARTIDOR_CORPORATIVO'),
    );

    expect(canManage, isTrue);
  });

  test('el gerente de operaciones no administra perfiles protegidos', () {
    final manager = actor(AppRoles.operationsManager);

    expect(
      UserManagementPolicy.canManage(manager, target(AppRoles.masterAdmin)),
      isFalse,
    );
    expect(
      UserManagementPolicy.canManage(manager, target(AppRoles.corporateAdmin)),
      isFalse,
    );
    expect(
      UserManagementPolicy.canManage(
        manager,
        target(AppRoles.operationsManager),
      ),
      isFalse,
    );
  });
}
