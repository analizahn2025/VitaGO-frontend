import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';
import 'package:vitago_app/features/user_administration/providers/users_providers.dart';
import 'package:vitago_app/features/user_administration/repositories/users_repository.dart';

final usersControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ManagedUser>, int>((ref, page) {
      return ref.watch(usersRepositoryProvider).getUsers(page: page);
    });

final userSelectionControllerProvider =
    FutureProvider.autoDispose<PaginatedResult<ManagedUser>>((ref) {
      return ref
          .watch(usersRepositoryProvider)
          .getUsers(page: 1, pageSize: 100);
    });

final assignableRolesControllerProvider = FutureProvider.autoDispose
    .family<List<AssignableRole>, AssignableRolesQuery>((ref, query) {
      return ref.watch(usersRepositoryProvider).getAssignableRoles(query);
    });

final userDetailControllerProvider = FutureProvider.autoDispose
    .family<ManagedUser, String>((ref, userId) {
      return ref.watch(usersRepositoryProvider).getUser(userId);
    });

final userRolesControllerProvider = FutureProvider.autoDispose
    .family<List<UserRoleAssignment>, String>((ref, userId) {
      return ref.watch(usersRepositoryProvider).getUserRoles(userId);
    });

final userActionsControllerProvider = Provider<UserActionsController>((ref) {
  return UserActionsController(ref.watch(usersRepositoryProvider));
});

class UserActionsController {
  const UserActionsController(this._repository);

  final UsersRepository _repository;

  Future<ManagedUser> createUser(
    CreateUserInput input, {
    required bool usesLocalAuthentication,
  }) => _repository.createUser(
    input,
    usesLocalAuthentication: usesLocalAuthentication,
  );

  Future<ManagedUser> updateUser(String userId, UpdateUserInput input) =>
      _repository.updateUser(userId, input);

  Future<void> resetPassword(String userId, String temporaryPassword) =>
      _repository.resetPassword(userId, temporaryPassword);

  Future<UserRoleAssignment> assignRole(
    String userId,
    AssignUserRoleInput input,
  ) => _repository.assignRole(userId, input);

  Future<void> revokeRole(String userId, String assignmentId) =>
      _repository.revokeRole(userId, assignmentId);
}
