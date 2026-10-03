import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/requests/services/requests_api_service.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  const RequestsRepositoryImpl(this._apiService);

  final RequestsApiService _apiService;

  @override
  Future<List<RequestServiceType>> getServiceTypes() =>
      _apiService.getServiceTypes();

  @override
  Future<RequestCreationOptions> getCreationOptions(
    RequestCreationOptionsQuery query,
  ) => _apiService.getCreationOptions(query);

  @override
  Future<RequesterSummary> getRequesterSummary(RequesterSummaryQuery query) =>
      _apiService.getRequesterSummary(query);

  @override
  Future<PaginatedResult<ServiceRequestSummary>> getRequests(
    RequestQuery query,
  ) => _apiService.getRequests(query);

  @override
  Future<ServiceRequestDetail> getRequest(String requestId) =>
      _apiService.getRequest(requestId);

  @override
  Future<ServiceRequestDetail> createRequest(CreateServiceRequestInput input) =>
      _apiService.createRequest(input);

  @override
  Future<ServiceRequestDetail> assignDriver(
    String requestId,
    RequestAssignmentInput input,
  ) => _apiService.assignDriver(requestId, input);

  @override
  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  ) => _apiService.transitionRequest(requestId, input);
}
