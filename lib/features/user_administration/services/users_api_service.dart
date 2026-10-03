import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/models/update_user_input.dart';
import 'package:vitago_app/features/user_administration/models/user_role_assignment.dart';

class UsersApiService {
  const UsersApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResult<ManagedUser>> getUsers({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'usuarios/',
        queryParameters: {'pagina': page, 'tamano_pagina': pageSize},
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        ManagedUser.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de usuarios no tiene el formato esperado.',
      );
    }
  }

  Future<List<AssignableRole>> getAssignableRoles(
    AssignableRolesQuery query,
  ) async {
    try {
      final response = await _apiClient.get<Object>(
        'usuarios/roles-asignables/',
        queryParameters: query.toQueryParameters(),
      );
      final data = response.data;
      final Object? rawItems = data is Map
          ? requireJsonMap(data, 'roles-asignables')['resultados']
          : data;
      return jsonMapList(
        rawItems,
        'roles-asignables',
      ).map(AssignableRole.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Los roles asignables no tienen el formato esperado.',
      );
    }
  }

  Future<ManagedUser> createUser(
    CreateUserInput input, {
    required bool usesLocalAuthentication,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'usuarios/',
        data: input.toJson(usesLocalAuthentication: usesLocalAuthentication),
      );
      return ManagedUser.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El usuario creado no tiene el formato esperado.',
      );
    }
  }

  Future<ManagedUser> getUser(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'usuarios/$userId/',
      );
      return ManagedUser.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El detalle del usuario no tiene el formato esperado.',
      );
    }
  }

  Future<ManagedUser> updateUser(String userId, UpdateUserInput input) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        'usuarios/$userId/',
        data: input.toJson(),
      );
      return ManagedUser.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El usuario actualizado no tiene el formato esperado.',
      );
    }
  }

  Future<void> resetPassword(String userId, String temporaryPassword) async {
    try {
      await _apiClient.post<void>(
        'usuarios/$userId/restablecer-contrasena/',
        data: {'contrasena_temporal': temporaryPassword},
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }

  Future<List<UserRoleAssignment>> getUserRoles(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'usuarios/$userId/roles/',
      );
      final data = _requiredData(response.data);
      return jsonMapList(
        data['resultados'],
        'roles del usuario',
      ).map(UserRoleAssignment.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Los roles del usuario no tienen el formato esperado.',
      );
    }
  }

  Future<UserRoleAssignment> assignRole(
    String userId,
    AssignUserRoleInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'usuarios/$userId/roles/',
        data: input.toJson(),
      );
      return UserRoleAssignment.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El rol asignado no tiene el formato esperado.',
      );
    }
  }

  Future<void> revokeRole(String userId, String assignmentId) async {
    try {
      await _apiClient.delete<void>('usuarios/$userId/roles/$assignmentId/');
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('Respuesta vacía.');
    }
    return data;
  }
}
