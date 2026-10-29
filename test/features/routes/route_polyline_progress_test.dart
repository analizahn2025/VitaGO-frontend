import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/routes/maps/route_polyline_progress.dart';

void main() {
  const points = [LatLng(14, -87), LatLng(14.001, -87), LatLng(14.002, -87)];

  DeviceLocation gps(
    double latitude, {
    double longitude = -87,
    double? accuracy,
  }) => DeviceLocation(
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracy,
    recordedAt: DateTime.utc(2026, 10, 28),
  );

  test('oculta solo lo recorrido sobre la geometría original', () {
    final progress = RoutePolylineProgress();
    final first = progress.remaining(
      segmentId: 'a',
      points: points,
      location: gps(14.0005),
    );
    expect(first.first.latitude, closeTo(14.0005, 0.0000001));
    expect(first.skip(1), points.skip(1));
    final second = progress.remaining(
      segmentId: 'a',
      points: points,
      location: gps(14.0015),
    );
    expect(second.first.latitude, closeTo(14.0015, 0.0000001));
    expect(second.last, points.last);
    expect(second, hasLength(2));
    expect(points.first, const LatLng(14, -87));
  });

  test('un salto GPS hacia atrás no hace reaparecer lo recorrido', () {
    final progress = RoutePolylineProgress();
    final clipped = progress.remaining(
      segmentId: 'a',
      points: points,
      location: gps(14.001),
    );
    expect(
      progress.remaining(
        segmentId: 'a',
        points: points,
        location: gps(14.00095),
      ),
      clipped,
    );
  });

  test('GPS impreciso, inválido o fuera del trazado no borra caminos', () {
    final progress = RoutePolylineProgress();
    for (final position in [
      gps(14.001, accuracy: 100),
      gps(14.001, longitude: -86.99),
      gps(double.nan),
      gps(14.001, accuracy: double.infinity),
    ]) {
      expect(
        progress.remaining(segmentId: 'a', points: points, location: position),
        points,
      );
    }
  });

  test('no crea líneas sin trazado ni sin GPS', () {
    final progress = RoutePolylineProgress();
    expect(
      progress.remaining(segmentId: 'a', points: points, location: null),
      points,
    );
    expect(
      progress.remaining(
        segmentId: 'a',
        points: const [],
        location: gps(14.001),
      ),
      isEmpty,
    );
    expect(
      progress.remaining(
        segmentId: 'a',
        points: [points.first],
        location: gps(14.001),
      ),
      [points.first],
    );
  });

  test(
    'conserva progreso al refrescar y reinicia ante otro tramo o geometría',
    () {
      final progress = RoutePolylineProgress();
      final clipped = progress.remaining(
        segmentId: 'a',
        points: points,
        location: gps(14.001),
      );
      expect(
        progress.remaining(
          segmentId: 'a',
          points: List.of(points),
          location: null,
        ),
        clipped,
      );
      expect(
        progress.remaining(segmentId: 'b', points: points, location: null),
        points,
      );
      progress.remaining(segmentId: 'b', points: points, location: gps(14.001));
      const changed = [LatLng(14, -87), LatLng(14.003, -87)];
      expect(
        progress.remaining(segmentId: 'b', points: changed, location: null),
        changed,
      );
    },
  );

  test('un cruce cercano no salta al final de un recorrido circular', () {
    final progress = RoutePolylineProgress();
    const loop = [
      LatLng(14, -87),
      LatLng(14.001, -87),
      LatLng(14.001, -86.999),
      LatLng(14, -86.999),
      LatLng(14, -86.9999),
    ];
    final clipped = progress.remaining(
      segmentId: 'a',
      points: loop,
      location: gps(14.0001),
    );
    final next = progress.remaining(
      segmentId: 'a',
      points: loop,
      location: gps(14, longitude: -86.9999),
    );
    expect(next, clipped);
    expect(next.last, loop.last);
    expect(next, hasLength(5));
  });

  test('al alcanzar el extremo no queda una línea residual', () {
    final progress = RoutePolylineProgress();
    expect(
      progress.remaining(segmentId: 'a', points: points, location: gps(14.002)),
      isEmpty,
    );
  });

  test('los vértices duplicados no producen divisiones por cero', () {
    final progress = RoutePolylineProgress();
    final result = progress.remaining(
      segmentId: 'a',
      points: [points.first, ...points],
      location: gps(14.0005),
    );
    expect(result.first.latitude, closeTo(14.0005, 0.0000001));
    expect(result.last, points.last);
  });
}
