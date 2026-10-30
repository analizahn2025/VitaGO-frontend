import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/models/driver_limits.dart';

class OrganizationsApiService {
  const OrganizationsApiService(this._apiClient);

  final ApiClient _apiClient;

  String _limitsPath(String? companyId) => companyId == null
      ? 'organizaciones/configuracion/limites-motoristas/'
      : 'organizaciones/empresas/$companyId/limites-motoristas/';
  Future<DriverLimits> getDriverLimits(String? companyId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        _limitsPath(companyId),
      );
      return DriverLimits.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La configuración de cupos no tiene el formato esperado.',
      );
    }
  }

  Future<DriverLimits> updateDriverLimits(
    String? companyId,
    UpdateDriverLimitsInput input,
  ) async {
    if (input.tubeLimit == null &&
        input.flaskLimit == null &&
        input.requestLimit == null) {
      throw const AppFailure(message: 'Cambia al menos un límite.');
    }
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        _limitsPath(companyId),
        data: input.toJson(),
      );
      return DriverLimits.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La configuración actualizada no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<Company>> getCompanies({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'organizaciones/empresas/',
        queryParameters: {'pagina': page, 'tamano_pagina': pageSize},
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        Company.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de empresas no tiene el formato esperado.',
      );
    }
  }

  Future<Company> getCompany(String companyId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'organizaciones/empresas/$companyId/',
      );
      return Company.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La empresa recibida no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<Branch>> getBranches({
    required String companyId,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'organizaciones/empresas/$companyId/sucursales/',
        queryParameters: {'pagina': page, 'tamano_pagina': pageSize},
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        Branch.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de sucursales no tiene el formato esperado.',
      );
    }
  }

  Future<Branch> getBranch(String branchId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'organizaciones/sucursales/$branchId/',
      );
      return Branch.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La sucursal recibida no tiene el formato esperado.',
      );
    }
  }

  Future<Branch> createBranch({
    required String companyId,
    required CreateBranchInput input,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'organizaciones/empresas/$companyId/sucursales/',
        data: input.toJson(),
      );
      return Branch.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La sucursal creada no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('Respuesta vacía.');
    }
    return data;
  }
}
