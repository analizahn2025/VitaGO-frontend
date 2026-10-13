import 'package:uuid/uuid.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

class TrackingQueueCoordinator {
  const TrackingQueueCoordinator(this._store, this._repository);

  final TrackingQueueStore _store;
  final TrackingRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<TrackingPointInput> capture(String shiftId, DeviceLocation location) {
    return _store.enqueue(
      shiftId,
      TrackingPointInput(
        clientId: _uuid.v4(),
        latitude: location.latitudeText,
        longitude: location.longitudeText,
        accuracyMeters: location.accuracyMeters?.toStringAsFixed(2),
        speedMetersPerSecond: location.speedMetersPerSecond?.toStringAsFixed(3),
        headingDegrees: location.headingDegrees
            ?.clamp(0, 359.99)
            .toStringAsFixed(2),
        recordedAt: location.recordedAt,
      ),
    );
  }

  Future<int> flush(String shiftId, {required int maximumBatchSize}) async {
    var sent = 0;
    while (true) {
      final points = await _store.pendingPoints(shiftId, maximumBatchSize);
      if (points.isEmpty) return sent;
      await _repository.registerPoints(
        TrackingBatchInput(shiftId: shiftId, points: points),
      );
      await _store.acknowledge(shiftId, points.map((point) => point.clientId));
      sent += points.length;
      if (points.length < maximumBatchSize) return sent;
    }
  }

  Future<void> flushAll({required int maximumBatchSize}) async {
    for (final shiftId in await _store.shiftsWithPendingPoints()) {
      try {
        await flush(shiftId, maximumBatchSize: maximumBatchSize);
      } on Object {
        // Conservar la cola exacta y permitir que la próxima sincronización
        // reintente. Una jornada antigua no bloquea la jornada actual.
      }
    }
  }

  Future<List<GpsSessionManifest>> manifest(String shiftId) =>
      _store.manifest(shiftId);

  Future<int> pendingCount(String shiftId) => _store.pendingCount(shiftId);

  Future<void> clearShift(String shiftId) => _store.clearShift(shiftId);
}
