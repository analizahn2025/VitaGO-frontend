import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/services/tracking_api_service.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl(this._apiService);

  final TrackingApiService _apiService;

  @override
  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input) =>
      _apiService.registerPoints(input);

  @override
  Future<RequestTracking> getRequestTracking(String requestId) =>
      _apiService.getRequestTracking(requestId);
}
