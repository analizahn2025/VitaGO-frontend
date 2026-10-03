import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';

abstract interface class EvidenceRepository {
  Future<PaginatedResult<OperationalEvidence>> getRequestEvidence({
    required String requestId,
    required int page,
  });

  Future<OperationalEvidence> uploadRequestEvidence(
    String requestId,
    EvidenceUploadInput input,
  );

  Future<EvidenceFile> downloadRequestEvidence({
    required String requestId,
    required String evidenceId,
  });

  Future<PaginatedResult<OperationalEvidence>> getIncidentEvidence({
    required String incidentId,
    required int page,
  });

  Future<OperationalEvidence> uploadIncidentEvidence(
    String incidentId,
    EvidenceUploadInput input,
  );

  Future<EvidenceFile> downloadIncidentEvidence({
    required String incidentId,
    required String evidenceId,
  });
}
