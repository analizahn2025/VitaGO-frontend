import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';

abstract interface class TrackingRepository {
  Future<TrackingConfiguration> getConfiguration();

  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input);

  Future<RequestTracking> getRequestTracking(String requestId);
}
