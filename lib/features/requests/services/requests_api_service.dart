import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/network/api_failure_diagnostics.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';

class RequestsApiService {
  const RequestsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RequestServiceType>> getServiceTypes() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/tipos-servicio/',
      );
      final data = _requiredData(response.data);
      return jsonMapList(
        data['resultados'],
        'tipos de servicio',
      ).map(RequestServiceType.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Los tipos de servicio no tienen el formato esperado.',
      );
    }
  }

  Future<RequestCreationOptions> getCreationOptions(
    RequestCreationOptionsQuery query,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/opciones-creacion/',
        queryParameters: query.toQueryParameters(),
      );
      return RequestCreationOptions.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Las opciones de creación no tienen el formato esperado.',
      );
    }
  }

  Future<RequesterSummary> getRequesterSummary(
    RequesterSummaryQuery query,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/resumen-solicitante/',
        queryParameters: query.toQueryParameters(),
      );
      return RequesterSummary.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El resumen de solicitudes no tiene el formato esperado.',
      );
    }
  }

  Future<PaginatedResult<ServiceRequestSummary>> getRequests(
    RequestQuery query,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/',
        queryParameters: query.toQueryParameters(),
      );
      return PaginatedResult.fromJson(
        _requiredData(response.data),
        ServiceRequestSummary.fromJson,
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La lista de solicitudes no tiene el formato esperado.',
      );
    }
  }

  Future<ServiceRequestDetail> getRequest(String requestId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'solicitudes/$requestId/',
      );
      return ServiceRequestDetail.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'El detalle de la solicitud no tiene el formato esperado.',
      );
    }
  }

  Future<ServiceRequestDetail> createRequest(
    CreateServiceRequestInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'solicitudes/',
        data: input.toJson(),
      );
      return ServiceRequestDetail.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La solicitud creada no tiene el formato esperado.',
      );
    }
  }

  Future<ServiceRequestDetail> assignDriver(
    String requestId,
    RequestAssignmentInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'solicitudes/$requestId/asignaciones/',
        data: input.toJson(),
      );
      return ServiceRequestDetail.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La asignación no tiene el formato esperado.',
      );
    }
  }

  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'solicitudes/$requestId/transiciones/',
        data: input.toJson(),
      );
      if (response.statusCode != 200) {
        ApiFailureDiagnostics.logUnexpectedResponse(
          operation: 'request transition',
          statusCode: response.statusCode,
          body: response.data,
        );
        throw AppFailure(
          message: 'El servidor no confirmó el cambio de estado esperado.',
          statusCode: response.statusCode,
        );
      }
      return ServiceRequestDetail.fromJson(_requiredData(response.data));
    } on DioException catch (error) {
      ApiFailureDiagnostics.logDio(
        operation: 'request transition',
        error: error,
      );
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La transición no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _requiredData(Map<String, dynamic>? data) {
    if (data == null) throw const FormatException('Respuesta vacía.');
    return data;
  }
}
