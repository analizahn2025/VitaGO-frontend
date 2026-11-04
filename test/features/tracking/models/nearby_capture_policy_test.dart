import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/models/nearby_capture_policy.dart';

void main() {
  test('aplica radios de entrada y salida con histéresis', () {
    final policy = NearbyCapturePolicy.fromJson({
      'habilitada': true,
      'radio_activacion_metros': 250,
      'radio_desactivacion_metros': 350,
      'intervalo_captura_segundos': 5,
      'intervalo_envio_segundos': 5,
      'enviar_al_entrar': true,
      'aplica_detenido': true,
      'objetivo': {
        'solicitud_id': 'request-1',
        'tipo_parada': 'RECOLECCION',
        'ubicacion_id': 'location-1',
        'latitud': '14.072300',
        'longitud': '-87.192100',
      },
    });

    expect(policy.isUsable, isTrue);
    expect(policy.target!.key, 'request-1:RECOLECCION:location-1');
    expect(
      policy.shouldBeNearby(14.0748, -87.1921, wasNearby: false),
      isFalse,
    ); // ~278 m
    expect(policy.shouldBeNearby(14.0748, -87.1921, wasNearby: true), isTrue);
    expect(
      policy.shouldBeNearby(14.0756, -87.1921, wasNearby: true),
      isFalse,
    ); // ~367 m
    expect(policy.shouldBeNearby(14.0740, -87.1921, wasNearby: false), isTrue);
  });

  test('no activa proximidad sin objetivo autorizado', () {
    final policy = NearbyCapturePolicy.fromJson({
      'habilitada': false,
      'radio_activacion_metros': 250,
      'radio_desactivacion_metros': 350,
      'intervalo_captura_segundos': 5,
      'intervalo_envio_segundos': 5,
      'enviar_al_entrar': true,
      'aplica_detenido': true,
      'objetivo': null,
    });
    expect(policy.isUsable, isFalse);
    expect(policy.shouldBeNearby(14.0723, -87.1921, wasNearby: true), isFalse);
  });
}
