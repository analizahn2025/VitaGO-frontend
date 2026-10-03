import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/incidents/models/incident.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

void main() {
  group('jornadas', () {
    test('interpreta el resumen operativo documentado', () {
      final shift = DriverShift.fromJson(_shiftJson());

      expect(shift.id, 'shift-id');
      expect(shift.driverId, 'driver-id');
      expect(shift.isActive, isTrue);
      expect(shift.mileageAvailable, isFalse);
      expect(shift.operationalKilometers, '0.000');
      expect(shift.completedServices, 3);
      expect(shift.reportedIncidents, 1);
      expect(shift.incidentsAvailable, isTrue);
      expect(shift.finishedAt, isNull);
    });

    test('omite coordenadas ausentes al iniciar o finalizar', () {
      expect(const ShiftCoordinatesInput().toJson(), isEmpty);
      expect(
        const ShiftCoordinatesInput(
          latitude: '14.072300',
          longitude: '-87.192100',
        ).toJson(),
        {'latitud': '14.072300', 'longitud': '-87.192100'},
      );
    });

    test('serializa los filtros de historial con fechas UTC', () {
      final query = ShiftQuery(
        driverId: 'driver-id',
        status: 'FINALIZADA',
        from: DateTime.parse('2026-09-26T08:00:00-06:00'),
        to: DateTime.parse('2026-09-26T18:00:00-06:00'),
        page: 2,
        pageSize: 10,
      ).toQueryParameters();

      expect(query['repartidor_id'], 'driver-id');
      expect(query['estado'], 'FINALIZADA');
      expect(query['desde'], '2026-09-26T14:00:00.000Z');
      expect(query['hasta'], '2026-09-27T00:00:00.000Z');
      expect(query['pagina'], 2);
      expect(query['tamano_pagina'], 10);
    });
  });

  group('seguimiento GPS', () {
    test('envia el identificador idempotente sin calcular es_operativo', () {
      final point = TrackingPointInput(
        clientId: 'client-id',
        latitude: '14.072300',
        longitude: '-87.192100',
        accuracyMeters: '8.50',
        speedMetersPerSecond: '4.250',
        headingDegrees: '180.00',
        recordedAt: DateTime.parse('2026-09-26T15:10:00Z'),
      );

      final json = TrackingBatchInput(
        shiftId: 'shift-id',
        points: [point],
      ).toJson();
      final record = (json['registros'] as List).single as Map<String, dynamic>;

      expect(json['jornada_id'], 'shift-id');
      expect(record['id_cliente'], 'client-id');
      expect(record['registrada_en'], '2026-09-26T15:10:00.000Z');
      expect(record.containsKey('es_operativo'), isFalse);
    });

    test('interpreta creados y repetidos de una respuesta por lote', () {
      final result = TrackingBatchResult.fromJson({
        'recibidos': 2,
        'creados': 1,
        'repetidos': 1,
        'registros': [_trackingPointJson()],
      });

      expect(result.received, 2);
      expect(result.created, 1);
      expect(result.repeated, 1);
      expect(result.points.single.isOperational, isTrue);
      expect(result.points.single.clientId, 'client-id');
    });

    test('acepta seguimiento no disponible sin ubicacion', () {
      final tracking = RequestTracking.fromJson({
        'solicitud_id': 'request-id',
        'estado': 'DELIVERED',
        'seguimiento_disponible': false,
        'ubicacion': null,
      });

      expect(tracking.available, isFalse);
      expect(tracking.location, isNull);
    });
  });

  group('incidencias', () {
    test('interpreta la incidencia y su historial auditado', () {
      final incident = Incident.fromJson({
        'id': 'incident-id',
        'jornada_id': 'shift-id',
        'repartidor_id': 'driver-id',
        'solicitud_id': 'request-id',
        'estado': 'EN_REVISION',
        'descripcion': 'Calle cerrada.',
        'latitud': '14.072300',
        'longitud': '-87.192100',
        'reportada_en': '2026-09-26T16:10:00Z',
        'revisada_por_id': 'reviewer-id',
        'revisada_en': '2026-09-26T16:20:00Z',
        'cerrada_en': null,
        'eventos': [
          {
            'id': 'event-id',
            'tipo': 'REVISION',
            'estado_anterior': 'ABIERTA',
            'estado_nuevo': 'EN_REVISION',
            'realizado_por_id': 'reviewer-id',
            'notas': 'En verificacion.',
            'metadatos': {'origen': 'movil'},
            'creado_en': '2026-09-26T16:20:00Z',
          },
        ],
      });

      expect(incident.status, 'EN_REVISION');
      expect(incident.events.single.previousStatus, 'ABIERTA');
      expect(incident.events.single.newStatus, 'EN_REVISION');
      expect(incident.events.single.metadata?['origen'], 'movil');
      expect(incident.isClosed, isFalse);
    });

    test('serializa reporte y revision con los nombres del contrato', () {
      final report = CreateIncidentInput(
        requestId: null,
        description: '  Calle cerrada.  ',
        latitude: '14.072300',
        longitude: '-87.192100',
        reportedAt: DateTime.parse('2026-09-26T16:10:00Z'),
      ).toJson();
      const review = ReviewIncidentInput(
        status: 'CERRADA',
        notes: '  Resuelta.  ',
      );

      expect(report['solicitud_id'], isNull);
      expect(report['descripcion'], 'Calle cerrada.');
      expect(report['reportada_en'], '2026-09-26T16:10:00.000Z');
      expect(review.toJson(), {'estado': 'CERRADA', 'notas': 'Resuelta.'});
    });
  });

  test('interpreta metadatos de evidencia privada', () {
    final evidence = OperationalEvidence.fromJson({
      'id': 'evidence-id',
      'incidencia_id': 'incident-id',
      'repartidor_id': 'driver-id',
      'tipo_contenido': 'image/jpeg',
      'tamano_bytes': 245000,
      'latitud': '14.072300',
      'longitud': '-87.192100',
      'capturada_en': '2026-09-26T16:11:00Z',
      'notas': 'Acceso bloqueado.',
      'archivo_disponible': true,
      'creado_en': '2026-09-26T16:11:03Z',
    });

    expect(evidence.incidentId, 'incident-id');
    expect(evidence.contentType, 'image/jpeg');
    expect(evidence.sizeBytes, 245000);
    expect(evidence.fileAvailable, isTrue);
  });
}

Map<String, dynamic> _shiftJson() => {
  'id': 'shift-id',
  'repartidor_id': 'driver-id',
  'estado': 'ACTIVA',
  'iniciada_en': '2026-09-26T14:30:00Z',
  'finalizada_en': null,
  'latitud_inicio': '14.072300',
  'longitud_inicio': '-87.192100',
  'latitud_fin': null,
  'longitud_fin': null,
  'kilometros_operativos': '0.000',
  'kilometraje_disponible': false,
  'servicios_completados': 3,
  'recolecciones_completadas': 1,
  'entregas_completadas': 2,
  'servicios_normales': 2,
  'servicios_prioritarios': 1,
  'minutos_activos': 90,
  'incidencias_reportadas': 1,
  'incidencias_disponibles': true,
  'creado_en': '2026-09-26T14:30:00Z',
  'actualizado_en': '2026-09-26T16:00:00Z',
};

Map<String, dynamic> _trackingPointJson() => {
  'id': 'tracking-id',
  'id_cliente': 'client-id',
  'jornada_id': 'shift-id',
  'repartidor_id': 'driver-id',
  'latitud': '14.072300',
  'longitud': '-87.192100',
  'precision_metros': '8.50',
  'velocidad_metros_segundo': '4.250',
  'rumbo_grados': '180.00',
  'registrada_en': '2026-09-26T15:10:00Z',
  'es_operativo': true,
  'creado_en': '2026-09-26T15:10:03Z',
};
