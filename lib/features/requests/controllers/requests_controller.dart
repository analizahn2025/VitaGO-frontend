import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';

final requestServiceTypesControllerProvider =
    FutureProvider.autoDispose<List<RequestServiceType>>((ref) {
      return ref.watch(requestsRepositoryProvider).getServiceTypes();
    });

final requestCreationOptionsControllerProvider = FutureProvider.autoDispose
    .family<RequestCreationOptions, RequestCreationOptionsQuery>((ref, query) {
      return ref.watch(requestsRepositoryProvider).getCreationOptions(query);
    });

final requesterSummaryControllerProvider = FutureProvider.autoDispose
    .family<RequesterSummary, RequesterSummaryQuery>((ref, query) {
      return ref.watch(requestsRepositoryProvider).getRequesterSummary(query);
    });

final requestsControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ServiceRequestSummary>, RequestQuery>((ref, query) {
      return ref.watch(requestsRepositoryProvider).getRequests(query);
    });

final requestControllerProvider = FutureProvider.autoDispose
    .family<ServiceRequestDetail, String>((ref, requestId) {
      return ref.watch(requestsRepositoryProvider).getRequest(requestId);
    });

final requestActionsControllerProvider = Provider<RequestActionsController>((
  ref,
) {
  return RequestActionsController(ref.watch(requestsRepositoryProvider));
});

class RequestActionsController {
  const RequestActionsController(this._repository);

  final RequestsRepository _repository;

  Future<ServiceRequestDetail> create(CreateServiceRequestInput input) =>
      _repository.createRequest(input);

  Future<ServiceRequestDetail> assign(
    String requestId,
    RequestAssignmentInput input,
  ) => _repository.assignDriver(requestId, input);

  Future<ServiceRequestDetail> transition(
    String requestId,
    RequestTransitionInput input,
  ) => _repository.transitionRequest(requestId, input);
}
