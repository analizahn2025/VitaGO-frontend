import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/controllers/route_deviation_alerts_controller.dart';
import 'package:vitago_app/features/tracking/models/route_deviation_alert.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

void main() {
  test('lee el aviso en una recepción GPS y conserva los demás campos', () {
    final result = TrackingBatchResult.fromJson({
      'recibidos': 1,
      'creados': 1,
      'repetidos': 0,
      'registros': <Map<String, dynamic>>[],
      'llegadas_detectadas': <Map<String, dynamic>>[],
      'alertas_ruta': [_alertJson()],
    });
    expect(result.received, 1);
    expect(result.routeAlerts.single.id, 'alert-id');
    expect(result.routeAlerts.single.requestId, 'request-id');
    expect(result.routeAlerts.single.isActive, isTrue);
  });

  test('deduplica respuestas repetidas y retira el aviso cuando se cierra', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(routeDeviationAlertProvider.notifier);
    final opened = RouteDeviationAlert.fromJson(_alertJson());
    final closed = RouteDeviationAlert.fromJson({
      ..._alertJson(),
      'finalizada_en': '2026-11-03T17:01:30Z',
    });

    expect(controller.receivedFromGps([opened]), isTrue);
    expect(container.read(routeDeviationAlertProvider)?.id, opened.id);
    final first = container.read(routeDeviationAlertProvider);
    expect(controller.receivedFromGps([opened]), isFalse);
    expect(
      identical(container.read(routeDeviationAlertProvider), first),
      isTrue,
    );
    expect(controller.receivedFromGps([closed]), isTrue);
    expect(container.read(routeDeviationAlertProvider), isNull);
    expect(controller.receivedFromGps([opened]), isFalse);
    expect(container.read(routeDeviationAlertProvider), isNull);
    controller.synchronizeFromRoute(opened);
    expect(container.read(routeDeviationAlertProvider), isNull);
    controller.synchronizeFromRoute(null);
    expect(container.read(routeDeviationAlertProvider), isNull);
  });

  test('mi-ruta recupera el aviso si se perdió la respuesta GPS', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(routeDeviationAlertProvider.notifier);
    controller.synchronizeFromRoute(RouteDeviationAlert.fromJson(_alertJson()));
    expect(container.read(routeDeviationAlertProvider)?.id, 'alert-id');
    controller.synchronizeFromRoute(null);
    expect(container.read(routeDeviationAlertProvider), isNull);
  });
}

Map<String, dynamic> _alertJson() => {
  'id': 'alert-id',
  'evento_id': 'event-id',
  'tipo': 'DESVIACION_RUTA',
  'solicitud_id': 'request-id',
  'tipo_parada': 'RECOLECCION',
  'detectada_en': '2026-11-03T17:00:00Z',
  'finalizada_en': null,
  'titulo': 'Desvío de ruta detectado',
  'mensaje': 'Revisa tu ruta y reporta cualquier incidencia.',
  'ruta': '/solicitudes/request-id',
};
