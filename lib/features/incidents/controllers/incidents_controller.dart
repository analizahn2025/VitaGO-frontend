import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/incidents/providers/incidents_providers.dart';
import 'package:vitago_app/features/incidents/repositories/incidents_repository.dart';

final incidentsControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Incident>, IncidentQuery>((ref, query) {
      return ref.watch(incidentsRepositoryProvider).getIncidents(query);
    });

final incidentControllerProvider = FutureProvider.autoDispose
    .family<Incident, String>((ref, incidentId) {
      return ref.watch(incidentsRepositoryProvider).getIncident(incidentId);
    });

final incidentActionsControllerProvider = Provider<IncidentActionsController>((
  ref,
) {
  return IncidentActionsController(ref.watch(incidentsRepositoryProvider));
});

class IncidentActionsController {
  const IncidentActionsController(this._repository);

  final IncidentsRepository _repository;

  Future<Incident> create(CreateIncidentInput input) =>
      _repository.createIncident(input);

  Future<Incident> review(String incidentId, ReviewIncidentInput input) =>
      _repository.reviewIncident(incidentId, input);
}
