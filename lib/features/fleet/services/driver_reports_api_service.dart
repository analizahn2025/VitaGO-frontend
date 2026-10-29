import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';

class DriverReportsApiService {
  const DriverReportsApiService(this._client);
  final ApiClient _client;
  Future<T> _get<T>(
    String path,
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      if (response.data == null) {
        throw const FormatException('Respuesta vacía.');
      }
      return parse(response.data!);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El reporte no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<DriverDailyReport>> getReports(
    DriverReportQuery query,
  ) => _get(
    'repartidores/resumenes/',
    query.toJson(),
    (json) => PaginatedResult.fromJson(json, DriverDailyReport.fromJson),
  );
  Future<DriverDailyReport> getReport(String id, String? date) => _get(
    'repartidores/$id/resumen/',
    {if (date?.isNotEmpty == true) 'fecha_operativa': date},
    DriverDailyReport.fromJson,
  );
  Future<PaginatedResult<DriverTemperatureReading>> getTemperatures(
    String id,
    String date,
    int page,
  ) => _get(
    'repartidores/$id/temperaturas/',
    {'fecha_operativa': date, 'pagina': page, 'tamano_pagina': 20},
    (json) => PaginatedResult.fromJson(json, DriverTemperatureReading.fromJson),
  );
}
