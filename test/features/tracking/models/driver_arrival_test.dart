import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/models/driver_arrival.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

void main() {
  test('interpreta llegada GPS y no utiliza una ruta enviada como enlace', () {
    final event = DriverArrival.fromJson(_event);
    expect(event.isSupported, isTrue);
    expect(event.eventId, 'event-1');
    expect(event.detectedAt, DateTime.utc(2026, 10, 23, 18));
    expect(event.targetStatus, 'PICKED_UP');
    final delivered = DriverArrival.fromJson({
      ..._event,
      'estado': 'AT_DESTINATION',
      'tipo_parada': 'ENTREGA',
      'pantalla': 'ENTREGA',
      'fuente': 'MANUAL',
    });
    expect(delivered.isSupported, isTrue);
    expect(delivered.targetStatus, 'DELIVERED');
  });

  test(
    'lotes previos y metadatos opcionales inválidos conservan el acuse GPS',
    () {
      final old = TrackingBatchResult.fromJson({
        'recibidos': 1,
        'creados': 1,
        'repetidos': 0,
        'registros': [],
      });
      expect(old.detectedArrivals, isEmpty);
      final result = TrackingBatchResult.fromJson({
        'recibidos': 1,
        'creados': 1,
        'repetidos': 0,
        'registros': [],
        'llegadas_detectadas': [
          {},
          {..._event, 'pantalla': 'URL_EXTERNA'},
          _event,
        ],
      });
      expect(result.created, 1);
      expect(result.detectedArrivals.single.eventId, 'event-1');
      expect(parseDriverArrivals(null), isEmpty);
    },
  );
}

const _event = <String, dynamic>{
  'evento_id': 'event-1',
  'solicitud_id': 'request-1',
  'estado': 'AT_PICKUP',
  'tipo_parada': 'RECOLECCION',
  'detectada_en': '2026-10-23T18:00:00Z',
  'fuente': 'GPS',
  'pantalla': 'RECOLECCION',
  'ruta': 'https://not-a-navigation-target.invalid',
};
