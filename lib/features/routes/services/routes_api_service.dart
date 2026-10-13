import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';

class RoutesApiService {
  const RoutesApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<DriverRoute> getMyRoute() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'rutas/mi-ruta/',
      );
      return DriverRoute.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(message: 'Tu ruta no tiene el formato esperado.');
    }
  }

  Future<RoadRoute> calculate(CalculateRouteInput input) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'rutas/mi-ruta/calcular/',
        data: input.toJson(),
      );
      return RoadRoute.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El cálculo de la ruta no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
