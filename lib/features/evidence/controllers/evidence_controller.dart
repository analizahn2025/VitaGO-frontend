import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';

typedef EvidencePageQuery = ({String ownerId, int page});
typedef EvidenceFileQuery = ({String ownerId, String evidenceId});

final requestEvidenceControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<OperationalEvidence>, EvidencePageQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(evidenceRepositoryProvider)
          .getRequestEvidence(requestId: query.ownerId, page: query.page);
    });

final incidentEvidenceControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<OperationalEvidence>, EvidencePageQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(evidenceRepositoryProvider)
          .getIncidentEvidence(incidentId: query.ownerId, page: query.page);
    });

final requestEvidenceFileProvider = FutureProvider.autoDispose
    .family<EvidenceFile, EvidenceFileQuery>((ref, query) {
      return ref
          .watch(evidenceRepositoryProvider)
          .downloadRequestEvidence(
            requestId: query.ownerId,
            evidenceId: query.evidenceId,
          );
    });

final incidentEvidenceFileProvider = FutureProvider.autoDispose
    .family<EvidenceFile, EvidenceFileQuery>((ref, query) {
      return ref
          .watch(evidenceRepositoryProvider)
          .downloadIncidentEvidence(
            incidentId: query.ownerId,
            evidenceId: query.evidenceId,
          );
    });

final evidenceActionsControllerProvider = Provider<EvidenceActionsController>((
  ref,
) {
  return EvidenceActionsController(ref.watch(evidenceRepositoryProvider));
});

class EvidenceActionsController {
  const EvidenceActionsController(this._repository);

  final EvidenceRepository _repository;

  Future<OperationalEvidence> uploadRequest(
    String requestId,
    EvidenceUploadInput input,
  ) => _repository.uploadRequestEvidence(requestId, input);

  Future<OperationalEvidence> uploadIncident(
    String incidentId,
    EvidenceUploadInput input,
  ) => _repository.uploadIncidentEvidence(incidentId, input);
}
