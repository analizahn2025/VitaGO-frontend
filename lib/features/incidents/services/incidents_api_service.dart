import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';

class IncidentsApiService {
  const IncidentsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResult<Incident>> getIncidents(IncidentQuery query) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'incidencias/',
        queryParameters: query.toQueryParameters(),
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        Incident.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de incidencias no tiene el formato esperado.',
      );
    }
  }

  Future<Incident> getIncident(String incidentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'incidencias/$incidentId/',
      );
      return Incident.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El detalle de la incidencia no tiene el formato esperado.',
      );
    }
  }

  Future<Incident> createIncident(CreateIncidentInput input) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'incidencias/',
        data: input.toJson(),
      );
      return Incident.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La incidencia creada no tiene el formato esperado.',
      );
    }
  }

  Future<Incident> reviewIncident(
    String incidentId,
    ReviewIncidentInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'incidencias/$incidentId/revision/',
        data: input.toJson(),
      );
      return Incident.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La incidencia revisada no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
