import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';

void main() {
  test('separa las entregas diarias de los acumulados históricos', () {
    final summary = RequesterSummary.fromJson({
      ..._summaryJson(),
      'fecha_operativa': '2026-10-22',
      'zona_horaria_operativa': 'America/Tegucigalpa',
      'entregadas_del_dia': 2,
      'entregas_recientes_del_dia': [_deliveryJson()],
    });

    expect(summary.total, 40);
    expect(summary.delivered, 30);
    expect(summary.deliveredToday, 2);
    expect(summary.hasDailySummary, isTrue);
    expect(summary.operationalDate, '2026-10-22');
    expect(summary.operationalTimeZone, 'America/Tegucigalpa');
    expect(summary.recent.single.id, 'historical-request');
    final delivery = summary.recentDeliveredToday.single;
    expect(delivery.request.id, 'daily-request');
    expect(delivery.request.status, 'DELIVERED');
    expect(delivery.request.createdAt, DateTime.utc(2026, 10, 21, 20));
    expect(delivery.deliveredAt, DateTime.utc(2026, 10, 22, 18, 30));
  });

  test('un resumen anterior no convierte el acumulado en entregas de hoy', () {
    final summary = RequesterSummary.fromJson(_summaryJson());

    expect(summary.delivered, 30);
    expect(summary.deliveredToday, isNull);
    expect(summary.operationalDate, isNull);
    expect(summary.operationalTimeZone, isNull);
    expect(summary.recentDeliveredToday, isEmpty);
    expect(summary.hasDailySummary, isFalse);
  });

  test('campos diarios nulos o incompletos no muestran un cero inventado', () {
    final summary = RequesterSummary.fromJson({
      ..._summaryJson(),
      'fecha_operativa': '2026-10-22',
      'zona_horaria_operativa': null,
      'entregadas_del_dia': null,
      'entregas_recientes_del_dia': null,
    });

    expect(summary.deliveredToday, isNull);
    expect(summary.recentDeliveredToday, isEmpty);
    expect(summary.hasDailySummary, isFalse);
  });

  test('un día confirmado sin entregas conserva el cero del servidor', () {
    final summary = RequesterSummary.fromJson({
      ..._summaryJson(),
      'fecha_operativa': '2026-10-22',
      'zona_horaria_operativa': 'America/Tegucigalpa',
      'entregadas_del_dia': 0,
      'entregas_recientes_del_dia': [],
    });

    expect(summary.hasDailySummary, isTrue);
    expect(summary.deliveredToday, 0);
    expect(summary.recentDeliveredToday, isEmpty);
  });

  test('rechaza valores diarios inválidos en lugar de asumir cero', () {
    for (final invalid in <Map<String, dynamic>>[
      {'fecha_operativa': '2026-02-30'},
      {'fecha_operativa': '22/10/2026'},
      {'fecha_operativa': 20261022},
      {'zona_horaria_operativa': ''},
      {'zona_horaria_operativa': 6},
      {'entregadas_del_dia': -1},
      {'entregadas_del_dia': 1.5},
      {'entregadas_del_dia': '2'},
      {'entregas_recientes_del_dia': {}},
      {
        'entregas_recientes_del_dia': [
          {..._deliveryJson(), 'entregada_en': null},
        ],
      },
      {
        'entregas_recientes_del_dia': [
          {..._deliveryJson(), 'entregada_en': 'no-es-fecha'},
        ],
      },
    ]) {
      expect(
        () => RequesterSummary.fromJson({..._summaryJson(), ...invalid}),
        throwsFormatException,
        reason: 'Campo inválido: $invalid',
      );
    }
  });
}

Map<String, dynamic> _summaryJson() => {
  'total': 40,
  'pendientes': 2,
  'activas': 5,
  'entregadas': 30,
  'fallidas': 1,
  'canceladas': 2,
  'recientes': [
    {..._deliveryJson(), 'id': 'historical-request'},
  ],
};

Map<String, dynamic> _deliveryJson() => {
  'id': 'daily-request',
  'numero': 'SOL-0001',
  'empresa_id': 'company-id',
  'solicitada_por_id': 'requester-id',
  'prioridad': 'NORMAL',
  'modalidad': 'ENTRE_SUCURSALES',
  'tipo_servicio': {'id': 'service-id', 'codigo': 'ENVIO', 'nombre': 'Envío'},
  'origen': {
    'id': 'origin-id',
    'nombre': 'Sucursal origen',
    'direccion': 'Dirección de origen',
  },
  'destino': {
    'id': 'destination-id',
    'nombre': 'Sucursal destino',
    'direccion': 'Dirección de destino',
  },
  'presentacion_ruta': 'MAPA',
  'estado': 'DELIVERED',
  'creado_en': '2026-10-21T20:00:00Z',
  'entregada_en': '2026-10-22T18:30:00Z',
};
