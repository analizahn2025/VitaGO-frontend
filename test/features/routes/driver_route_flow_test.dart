import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';

void main() {
  test('SIN_SERVICIOS acepta campos nulos sin fallar por bool', () {
    final flow = DriverRouteFlow.fromJson({
      'modo': 'AUTOMATICO',
      'pantalla': 'SIN_SERVICIOS',
      'requiere_aceptacion': null,
      'permite_elegir_etapa': null,
      'solicitud_id': null,
      'tramo_id': null,
      'estado': null,
      'tipo_parada': null,
    });
    expect(flow.hasNoServices, isTrue);
    expect(flow.photoTargetStatus, isNull);
    expect(flow.canFinishSpecial, isFalse);
  });
  for (final special in [false, true]) {
    test('ENTREGA reconoce la foto automática, especial=$special', () {
      final flow = DriverRouteFlow.fromJson({
        'modo': 'AUTOMATICO',
        'pantalla': 'ENTREGA',
        'estado': 'AT_DESTINATION',
        'tipo_parada': special ? 'ENVIO_ESPECIAL' : 'ENTREGA',
        'evidencia_requerida': 'FOTO_ENTREGA',
      });
      expect(flow.photoTargetStatus, 'DELIVERED');
    });
  }
  test('RECOLECCION solo habilita la foto requerida en AT_PICKUP', () {
    final input = {
      'modo': 'AUTOMATICO',
      'pantalla': 'RECOLECCION',
      'estado': 'AT_PICKUP',
      'tipo_parada': 'RECOLECCION',
      'evidencia_requerida': 'FOTO_RECOLECCION',
    };
    expect(DriverRouteFlow.fromJson(input).photoTargetStatus, 'PICKED_UP');
    expect(
      DriverRouteFlow.fromJson({...input, 'estado': 'GOING_TO_PICKUP'})
          .photoTargetStatus,
      isNull,
    );
    expect(
      DriverRouteFlow.fromJson({
        ...input,
        'evidencia_requerida': 'FOTO_INCIDENCIA',
      }).photoTargetStatus,
      isNull,
    );
  });
  test('pantallas desconocidas o una selección habilitada no operan automáticamente', () {
    expect(
      DriverRouteFlow.fromJson({
        'modo': 'AUTOMATICO',
        'pantalla': 'DESCONOCIDA',
      }).photoTargetStatus,
      isNull,
    );
    expect(
      DriverRouteFlow.fromJson({
        'modo': 'AUTOMATICO',
        'pantalla': 'MAPA',
        'permite_elegir_etapa': true,
      }).isAutomatic,
      isFalse,
    );
  });
  test('el especial sin destino conserva su única finalización manual', () {
    const flow = DriverRouteFlow(
      mode: 'AUTOMATICO',
      screen: 'FINALIZAR_ESPECIAL',
      status: 'IN_TRANSIT',
      stopType: 'ENVIO_ESPECIAL',
      requiresSpecialCompletion: true,
    );
    expect(flow.canFinishSpecial, isTrue);
    expect(flow.photoTargetStatus, isNull);
  });
  test('lee estado_solicitud actual en una evidencia', () {
    final evidence = OperationalEvidence.fromJson({
      'id': 'photo',
      'solicitud_id': 'request',
      'estado_solicitud': 'IN_TRANSIT',
      'tipo': 'FOTO_RECOLECCION',
      'tipo_contenido': 'image/jpeg',
      'latitud': '14',
      'longitud': '-87',
      'capturada_en': '2026-10-26T15:00:00Z',
      'creado_en': '2026-10-26T15:00:00Z',
    });
    expect(evidence.requestStatus, 'IN_TRANSIT');
  });
}
