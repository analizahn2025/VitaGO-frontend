import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/network/api_failure_diagnostics.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';

class EvidenceApiService {
  const EvidenceApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResult<OperationalEvidence>> getRequestEvidence({
    required String requestId,
    required int page,
  }) => _getEvidence('solicitudes/$requestId/evidencias/', page);

  Future<OperationalEvidence> uploadRequestEvidence(
    String requestId,
    EvidenceUploadInput input,
  ) => _uploadEvidence(
    'solicitudes/$requestId/evidencias/',
    input,
    includeType: true,
  );

  Future<EvidenceFile> downloadRequestEvidence({
    required String requestId,
    required String evidenceId,
  }) => _download('solicitudes/$requestId/evidencias/$evidenceId/archivo/');

  Future<PaginatedResult<OperationalEvidence>> getIncidentEvidence({
    required String incidentId,
    required int page,
  }) => _getEvidence('incidencias/$incidentId/evidencias/', page);

  Future<OperationalEvidence> uploadIncidentEvidence(
    String incidentId,
    EvidenceUploadInput input,
  ) => _uploadEvidence(
    'incidencias/$incidentId/evidencias/',
    input,
    includeType: false,
  );

  Future<EvidenceFile> downloadIncidentEvidence({
    required String incidentId,
    required String evidenceId,
  }) => _download('incidencias/$incidentId/evidencias/$evidenceId/archivo/');

  Future<PaginatedResult<OperationalEvidence>> _getEvidence(
    String path,
    int page,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: {'pagina': page, 'tamano_pagina': 20},
      );
      final data = response.data;
      if (data == null) throw const FormatException('Respuesta vacía.');
      return PaginatedResult.fromJson(data, OperationalEvidence.fromJson);
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'Las evidencias no tienen el formato esperado.',
      );
    }
  }

  Future<OperationalEvidence> _uploadEvidence(
    String path,
    EvidenceUploadInput input, {
    required bool includeType,
  }) async {
    try {
      final form = FormData.fromMap({
        if (includeType) 'tipo': input.type,
        'archivo': await MultipartFile.fromFile(
          input.filePath,
          filename: input.fileName,
        ),
        'latitud': input.latitude,
        'longitud': input.longitude,
        'capturada_en': input.capturedAt.toUtc().toIso8601String(),
        'notas': input.notes,
      });
      final response = await _apiClient.post<Map<String, dynamic>>(
        path,
        data: form,
      );
      if (response.statusCode != 201) {
        ApiFailureDiagnostics.logUnexpectedResponse(
          operation: 'evidence upload',
          statusCode: response.statusCode,
          body: response.data,
        );
        throw AppFailure(
          message: 'El servidor no confirmó el registro de la evidencia.',
          statusCode: response.statusCode,
        );
      }
      final data = response.data;
      if (data == null) throw const FormatException('Respuesta vacía.');
      return OperationalEvidence.fromJson(data);
    } on DioException catch (error) {
      ApiFailureDiagnostics.logDio(operation: 'evidence upload', error: error);
      throw AppFailure.fromDio(error);
    } on FormatException {
      throw const AppFailure(
        message: 'La evidencia creada no tiene el formato esperado.',
      );
    }
  }

  Future<EvidenceFile> _download(String path) async {
    try {
      final response = await _apiClient.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) {
        throw const AppFailure(message: 'El archivo de evidencia está vacío.');
      }
      return EvidenceFile(
        bytes: bytes,
        contentType:
            response.headers.value(Headers.contentTypeHeader) ??
            'application/octet-stream',
      );
    } on DioException catch (error) {
      throw AppFailure.fromDio(error);
    }
  }
}
