import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';

class ShiftsApiService {
  const ShiftsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<DriverShift> startShift(ShiftCoordinatesInput input) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'jornadas/iniciar/',
        data: input.toJson(),
      );
      return DriverShift.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La jornada iniciada no tiene el formato esperado.',
      );
    }
  }

  Future<DriverShift?> getActiveShift() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'jornadas/activa/',
      );
      final data = _requiredData(response.data);
      final shift = optionalJsonMap(data, 'jornada');
      return shift == null ? null : DriverShift.fromJson(shift);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La jornada activa no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<DriverShift>> getShifts(ShiftQuery query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'jornadas/',
        queryParameters: query.toQueryParameters(),
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        DriverShift.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El historial de jornadas no tiene el formato esperado.',
      );
    }
  }

  Future<DriverShift> getShift(String shiftId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'jornadas/$shiftId/',
      );
      return DriverShift.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El detalle de la jornada no tiene el formato esperado.',
      );
    }
  }

  Future<DriverShift> finishShift(
    String shiftId,
    ShiftCoordinatesInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'jornadas/$shiftId/finalizar/',
        data: input.toJson(),
      );
      return DriverShift.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La jornada finalizada no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
