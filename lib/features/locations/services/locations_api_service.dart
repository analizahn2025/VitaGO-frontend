import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';

class LocationsApiService {
  const LocationsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResult<CompanyLocation>> getLocations({
    required String companyId,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'ubicaciones/',
        queryParameters: {
          'empresa_id': companyId,
          'pagina': page,
          'tamano_pagina': pageSize,
        },
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        CompanyLocation.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de ubicaciones no tiene el formato esperado.',
      );
    }
  }

  Future<List<LocationType>> getLocationTypes() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'ubicaciones/tipos/',
      );
      final data = _requiredData(response.data);
      return jsonMapList(
        data['resultados'],
        'resultados',
      ).map(LocationType.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Los tipos de ubicación no tienen el formato esperado.',
      );
    }
  }

  Future<Location> getLocation(String locationId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'ubicaciones/$locationId/',
      );
      final data = _requiredData(response.data);
      final locationData = data['ubicacion'] is Map
          ? requireJsonMap(data['ubicacion'], 'ubicacion')
          : data;
      return Location.fromJson(locationData);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La ubicación recibida no tiene el formato esperado.',
      );
    }
  }

  Future<void> createLocation(CreateLocationInput input) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        'ubicaciones/',
        data: input.toJson(),
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }

  Future<void> updateAuthorization({
    required String locationId,
    required String companyId,
    required LocationAuthorizationInput input,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        'ubicaciones/$locationId/autorizacion-empresa/$companyId/',
        data: input.toJson(),
      );
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
