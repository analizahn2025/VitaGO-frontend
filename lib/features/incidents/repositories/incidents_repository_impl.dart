import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/incidents/repositories/incidents_repository.dart';
import 'package:vitago_app/features/incidents/services/incidents_api_service.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  const IncidentsRepositoryImpl(this._apiService);

  final IncidentsApiService _apiService;

  @override
  Future<PaginatedResult<Incident>> getIncidents(IncidentQuery query) =>
      _apiService.getIncidents(query);

  @override
  Future<Incident> getIncident(String incidentId) =>
      _apiService.getIncident(incidentId);

  @override
  Future<Incident> createIncident(CreateIncidentInput input) =>
      _apiService.createIncident(input);

  @override
  Future<Incident> reviewIncident(
    String incidentId,
    ReviewIncidentInput input,
  ) => _apiService.reviewIncident(incidentId, input);
}
