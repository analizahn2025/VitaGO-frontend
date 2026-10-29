import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

void main() {
  test(
    'publica llegadas de todos los lotes sin perder cola ni duplicar GPS',
    () async {
      final store = _Queue();
      final repository = _Repository();
      final events = <DriverArrival>[];
      final coordinator = TrackingQueueCoordinator(
        store,
        repository,
        ServerTimeClock(),
        onArrivals: events.addAll,
      );
      await coordinator.capture('shift-id', _location, recordedAt: _now);
      await coordinator.capture(
        'shift-id',
        _location,
        recordedAt: _now.add(const Duration(seconds: 5)),
      );
      final sent = await coordinator.flush('shift-id', maximumBatchSize: 1);
      expect(sent, 2);
      expect(events.map((e) => e.eventId), ['event-1', 'event-2']);
      expect(await store.pendingCount('shift-id'), 0);
      expect(await coordinator.flush('shift-id', maximumBatchSize: 1), 0);
      expect(repository.calls, 2);
    },
  );

  test(
    'fallar navegación no convierte un lote aceptado en error GPS',
    () async {
      final store = _Queue();
      final coordinator = TrackingQueueCoordinator(
        store,
        _Repository(),
        ServerTimeClock(),
        onArrivals: (_) => throw StateError('UI no disponible'),
      );
      await coordinator.capture('shift-id', _location, recordedAt: _now);
      expect(await coordinator.flush('shift-id', maximumBatchSize: 200), 1);
      expect(await store.pendingCount('shift-id'), 0);
    },
  );
}

final _now = DateTime.utc(2026, 10, 23, 18);
final _location = DeviceLocation(
  latitude: 14,
  longitude: -87,
  recordedAt: _now,
);

class _Repository implements TrackingRepository {
  int calls = 0;
  @override
  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input) async {
    calls++;
    return TrackingBatchResult(
      received: input.points.length,
      created: input.points.length,
      repeated: 0,
      points: [],
      detectedArrivals: [
        DriverArrival(
          eventId: 'event-$calls',
          requestId: 'request-$calls',
          status: 'AT_PICKUP',
          stopType: 'RECOLECCION',
          detectedAt: _now,
          source: 'GPS',
          screen: 'RECOLECCION',
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Queue implements TrackingQueueStore {
  final points = <TrackingPointInput>[];
  @override
  Future<TrackingPointInput> enqueue(
    String shiftId,
    TrackingPointInput point,
  ) async {
    points.add(point);
    return point;
  }

  @override
  Future<List<TrackingPointInput>> pendingPoints(
    String shiftId,
    int limit,
  ) async => points.take(limit).toList();
  @override
  Future<void> acknowledge(String shiftId, Iterable<String> clientIds) async {
    points.removeWhere((point) => clientIds.contains(point.clientId));
  }

  @override
  Future<int> pendingCount(String shiftId) async => points.length;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
