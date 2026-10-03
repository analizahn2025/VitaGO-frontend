import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

class FleetApiService {
  const FleetApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResult<Vehicle>> getVehicles(VehicleQuery query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'vehiculos/',
        queryParameters: query.toQueryParameters(),
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        Vehicle.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de vehículos no tiene el formato esperado.',
      );
    }
  }

  Future<Vehicle> getVehicle(String vehicleId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'vehiculos/$vehicleId/',
      );
      return Vehicle.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El vehículo no tiene el formato esperado.',
      );
    }
  }

  Future<Vehicle> createVehicle(
    CreateVehicleInput input, {
    required bool isCorporate,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'vehiculos/',
        data: input.toJson(isCorporate: isCorporate),
      );
      return Vehicle.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El vehículo creado no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<DriverProfile>> getDrivers(DriverQuery query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'repartidores/',
        queryParameters: query.toQueryParameters(),
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        DriverProfile.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de motoristas no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<DriverProfile>> getAvailableDrivers({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'repartidores/disponibles/',
        queryParameters: {'pagina': page, 'tamano_pagina': pageSize},
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        DriverProfile.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Los motoristas disponibles no tienen el formato esperado.',
      );
    }
  }

  Future<DriverProfile> getDriver(String driverId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'repartidores/$driverId/',
      );
      return DriverProfile.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El motorista no tiene el formato esperado.',
      );
    }
  }

  Future<DriverProfile> getOwnDriverProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'repartidores/mi-perfil/',
      );
      return DriverProfile.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Tu perfil de motorista no tiene el formato esperado.',
      );
    }
  }

  Future<DriverProfile> createDriver(
    CreateDriverInput input, {
    required bool isCorporate,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'repartidores/',
        data: input.toJson(isCorporate: isCorporate),
      );
      return DriverProfile.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El motorista creado no tiene el formato esperado.',
      );
    }
  }

  Future<DriverProfile> updateDriverOperation(
    String driverId,
    UpdateDriverOperationInput input,
  ) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        'repartidores/$driverId/operacion/',
        data: input.toJson(),
      );
      return DriverProfile.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El estado del motorista no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
