import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';

final requestTrackingControllerProvider = FutureProvider.autoDispose
    .family<RequestTracking, String>((ref, requestId) {
      return ref
          .watch(trackingRepositoryProvider)
          .getRequestTracking(requestId);
    });

final trackingActionsControllerProvider = Provider<TrackingActionsController>((
  ref,
) {
  return TrackingActionsController(ref.watch(trackingRepositoryProvider));
});

class TrackingActionsController {
  const TrackingActionsController(this._repository);

  final TrackingRepository _repository;

  Future<TrackingBatchResult> register(TrackingBatchInput input) =>
      _repository.registerPoints(input);
}
