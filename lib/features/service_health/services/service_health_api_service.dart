import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/service_health/models/service_health.dart';

class ServiceHealthApiService {
  const ServiceHealthApiService(this._dio);

  final Dio _dio;

  Future<ServiceHealth> check() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('salud/');
      final data = response.data;
      if (data == null) {
        throw const FormatException('Respuesta vacía.');
      }
      return ServiceHealth.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El estado del servicio no tiene el formato esperado.',
      );
    }
  }
}
