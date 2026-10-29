import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';

final driverArrivalsProvider = NotifierProvider<DriverArrivalsController, int>(
  DriverArrivalsController.new,
);

/// Signals new server arrivals or connectivity recovery. The route remains
/// authoritative: a delayed batch must not open an obsolete assignment.
class DriverArrivalsController extends Notifier<int> {
  @override
  int build() => 0;

  void received(List<DriverArrival> arrivals) {
    if (arrivals.any((arrival) => arrival.isSupported)) state++;
  }

  void recover() => state++;
}
