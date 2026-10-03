import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';

abstract interface class UsersRepository {
  Future<PaginatedResult<ManagedUser>> getUsers({
    required int page,
    int pageSize,
  });

  Future<List<AssignableRole>> getAssignableRoles(AssignableRolesQuery query);

  Future<ManagedUser> createUser(
    CreateUserInput input, {
    required bool usesLocalAuthentication,
  });

  Future<ManagedUser> getUser(String userId);

  Future<ManagedUser> updateUser(String userId, UpdateUserInput input);

  Future<void> resetPassword(String userId, String temporaryPassword);

  Future<List<UserRoleAssignment>> getUserRoles(String userId);

  Future<UserRoleAssignment> assignRole(
    String userId,
    AssignUserRoleInput input,
  );

  Future<void> revokeRole(String userId, String assignmentId);
}
