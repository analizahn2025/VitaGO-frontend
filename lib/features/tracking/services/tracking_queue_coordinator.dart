import 'package:uuid/uuid.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

class TrackingQueueCoordinator {
  const TrackingQueueCoordinator(
    this._store,
    this._repository,
    this._serverTimeClock, {
    this.onArrivals,
  });

  final void Function(List<DriverArrival>)? onArrivals;

  final TrackingQueueStore _store;
  final TrackingRepository _repository;
  final ServerTimeClock _serverTimeClock;
  final Uuid _uuid = const Uuid();

  Future<TrackingPointInput> capture(
    String shiftId,
    DeviceLocation location, {
    DateTime? recordedAt,
  }) {
    final officialRecordedAt = recordedAt ?? _serverTimeClock.currentUtc();
    if (officialRecordedAt == null) {
      throw const AppFailure(
        message: 'Conecta el teléfono para sincronizar la hora oficial antes de registrar el GPS.',
      );
    }
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
        recordedAt: officialRecordedAt,
      ),
    );
  }

  Future<int> flush(String shiftId, {required int maximumBatchSize}) async {
    var sent = 0;
    while (true) {
      final points = await _store.pendingPoints(shiftId, maximumBatchSize);
      if (points.isEmpty) return sent;
      final result = await _repository.registerPoints(
        TrackingBatchInput(shiftId: shiftId, points: points),
      );
      await _store.acknowledge(shiftId, points.map((point) => point.clientId));
      if (result.detectedArrivals.isNotEmpty) {
        try {
          onArrivals?.call(result.detectedArrivals);
        } on Object {
          // GPS is already acknowledged. mi-ruta can recover the arrival later.
        }
      }
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
