import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/app_roles.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';

abstract final class UserManagementPolicy {
  static bool canManage(UserProfile actor, ManagedUser target) {
    if (!actor.can(AppPermissions.manageUsers)) return false;
    if (!_isOperationsManager(actor)) return true;
    return !target.roles.any(
      (role) =>
          _protectedFromOperationsManager.contains(role.code.toUpperCase()),
    );
  }

  static bool canManageRoles(UserProfile actor, ManagedUser target) {
    return canManage(actor, target) && actor.can(AppPermissions.assignRoles);
  }

  static bool _isOperationsManager(UserProfile profile) {
    return profile.roles.any(
      (role) => role.code.toUpperCase() == AppRoles.operationsManager,
    );
  }

  static const _protectedFromOperationsManager = {
    AppRoles.masterAdmin,
    AppRoles.corporateAdmin,
    AppRoles.operationsManager,
  };
}
