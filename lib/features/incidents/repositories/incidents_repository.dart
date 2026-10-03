import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';

abstract interface class IncidentsRepository {
  Future<PaginatedResult<Incident>> getIncidents(IncidentQuery query);

  Future<Incident> getIncident(String incidentId);

  Future<Incident> createIncident(CreateIncidentInput input);

  Future<Incident> reviewIncident(String incidentId, ReviewIncidentInput input);
}
