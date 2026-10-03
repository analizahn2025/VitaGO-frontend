import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';

abstract interface class RequestsRepository {
  Future<List<RequestServiceType>> getServiceTypes();

  Future<RequestCreationOptions> getCreationOptions(
    RequestCreationOptionsQuery query,
  );

  Future<RequesterSummary> getRequesterSummary(RequesterSummaryQuery query);

  Future<PaginatedResult<ServiceRequestSummary>> getRequests(
    RequestQuery query,
  );

  Future<ServiceRequestDetail> getRequest(String requestId);

  Future<ServiceRequestDetail> createRequest(CreateServiceRequestInput input);

  Future<ServiceRequestDetail> assignDriver(
    String requestId,
    RequestAssignmentInput input,
  );

  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  );
}
