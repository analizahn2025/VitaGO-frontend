import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';
import 'package:vitago_app/features/user_administration/repositories/users_repository.dart';
import 'package:vitago_app/features/user_administration/services/users_api_service.dart';

class UsersRepositoryImpl implements UsersRepository {
  const UsersRepositoryImpl(this._apiService);

  final UsersApiService _apiService;

  @override
  Future<PaginatedResult<ManagedUser>> getUsers({
    required int page,
    int pageSize = 20,
  }) => _apiService.getUsers(page: page, pageSize: pageSize);

  @override
  Future<List<AssignableRole>> getAssignableRoles(AssignableRolesQuery query) =>
      _apiService.getAssignableRoles(query);

  @override
  Future<ManagedUser> createUser(
    CreateUserInput input, {
    required bool usesLocalAuthentication,
  }) => _apiService.createUser(
    input,
    usesLocalAuthentication: usesLocalAuthentication,
  );

  @override
  Future<ManagedUser> getUser(String userId) => _apiService.getUser(userId);

  @override
  Future<ManagedUser> updateUser(String userId, UpdateUserInput input) =>
      _apiService.updateUser(userId, input);

  @override
  Future<void> resetPassword(String userId, String temporaryPassword) =>
      _apiService.resetPassword(userId, temporaryPassword);

  @override
  Future<List<UserRoleAssignment>> getUserRoles(String userId) =>
      _apiService.getUserRoles(userId);

  @override
  Future<UserRoleAssignment> assignRole(
    String userId,
    AssignUserRoleInput input,
  ) => _apiService.assignRole(userId, input);

  @override
  Future<void> revokeRole(String userId, String assignmentId) =>
      _apiService.revokeRole(userId, assignmentId);
}
