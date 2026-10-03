import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

class TrackingApiService {
  const TrackingApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'seguimiento/registros/',
        data: input.toJson(),
      );
      return TrackingBatchResult.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message:
            'La confirmación del seguimiento no tiene el formato esperado.',
      );
    }
  }

  Future<RequestTracking> getRequestTracking(String requestId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/$requestId/seguimiento/',
      );
      return RequestTracking.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El seguimiento de la solicitud no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
