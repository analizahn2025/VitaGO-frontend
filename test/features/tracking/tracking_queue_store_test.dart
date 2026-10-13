import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('vitago-gps-test-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('persiste sesión, secuencia y punto exacto antes del envío', () async {
    final store = FileTrackingQueueStore(
      directoryProvider: () async => directory,
    );
    final first = await store.enqueue('shift-1', _point('point-1', 0));
    final second = await store.enqueue('shift-1', _point('point-2', 5));

    expect(first.gpsSession, isNotEmpty);
    expect(second.gpsSession, first.gpsSession);
    expect(first.sequence, 1);
    expect(second.sequence, 2);

    final restored = FileTrackingQueueStore(
      directoryProvider: () async => directory,
    );
    final pending = await restored.pendingPoints('shift-1', 200);
    expect(pending.map((point) => point.clientId), ['point-1', 'point-2']);
    expect(pending.last.recordedAt, _baseTime.add(const Duration(seconds: 5)));

    await restored.acknowledge('shift-1', ['point-1']);
    expect(await restored.pendingCount('shift-1'), 1);
    final manifest = await restored.manifest('shift-1');
    expect(manifest.single.gpsSession, first.gpsSession);
    expect(manifest.single.lastSequence, 2);
  });

  test('no reutiliza una sesión en otra jornada', () async {
    final store = FileTrackingQueueStore(
      directoryProvider: () async => directory,
    );
    final first = await store.enqueue('shift-1', _point('point-1', 0));
    final other = await store.enqueue('shift-2', _point('point-2', 1));

    expect(other.gpsSession, isNot(first.gpsSession));
    expect(other.sequence, 1);
  });
}

final _baseTime = DateTime.utc(2026, 10, 13, 16);

TrackingPointInput _point(String id, int seconds) => TrackingPointInput(
  clientId: id,
  latitude: '14.072300',
  longitude: '-87.192100',
  accuracyMeters: '5.00',
  speedMetersPerSecond: '2.500',
  recordedAt: _baseTime.add(Duration(seconds: seconds)),
);
