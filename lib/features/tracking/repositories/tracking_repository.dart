import 'package:vitago_app/features/tracking/models/tracking_point.dart';

abstract interface class TrackingRepository {
  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input);

  Future<RequestTracking> getRequestTracking(String requestId);
}
