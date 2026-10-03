import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';
import 'package:vitago_app/features/evidence/services/evidence_api_service.dart';

class EvidenceRepositoryImpl implements EvidenceRepository {
  const EvidenceRepositoryImpl(this._apiService);

  final EvidenceApiService _apiService;

  @override
  Future<PaginatedResult<OperationalEvidence>> getRequestEvidence({
    required String requestId,
    required int page,
  }) => _apiService.getRequestEvidence(requestId: requestId, page: page);

  @override
  Future<OperationalEvidence> uploadRequestEvidence(
    String requestId,
    EvidenceUploadInput input,
  ) => _apiService.uploadRequestEvidence(requestId, input);

  @override
  Future<EvidenceFile> downloadRequestEvidence({
    required String requestId,
    required String evidenceId,
  }) => _apiService.downloadRequestEvidence(
    requestId: requestId,
    evidenceId: evidenceId,
  );

  @override
  Future<PaginatedResult<OperationalEvidence>> getIncidentEvidence({
    required String incidentId,
    required int page,
  }) => _apiService.getIncidentEvidence(incidentId: incidentId, page: page);

  @override
  Future<OperationalEvidence> uploadIncidentEvidence(
    String incidentId,
    EvidenceUploadInput input,
  ) => _apiService.uploadIncidentEvidence(incidentId, input);

  @override
  Future<EvidenceFile> downloadIncidentEvidence({
    required String incidentId,
    required String evidenceId,
  }) => _apiService.downloadIncidentEvidence(
    incidentId: incidentId,
    evidenceId: evidenceId,
  );
}
