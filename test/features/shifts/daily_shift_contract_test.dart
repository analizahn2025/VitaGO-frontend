import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/services/shifts_api_service.dart';

import '../../support/admin_contract_fixtures.dart';

void main() {
  test('la jornada vencida no es operativa aunque siga activa', () {
    final day = ActiveShiftDay.fromJson({
      'jornada': _shiftJson(puedeOperar: false),
      'hora_servidor': '2026-10-29T22:01:00-06:00',
      'fecha_operativa': '2026-10-29',
      'zona_horaria_operativa': 'America/Tegucigalpa',
      'cierre_programado_en': '2026-10-29T22:00:00-06:00',
      'jornada_iniciada_hoy': true,
      'puede_iniciar_jornada': false,
      'cierre_pendiente': true,
    });
    expect(day.shift!.isActive, isTrue);
    expect(day.shift!.isOperational, isFalse);
    expect(day.isAfterCut, isTrue);
    expect(day.closurePending, isTrue);
    expect(day.canStartShift, isFalse);
  });

  test('el almuerzo se interpreta por campo explícito e historial', () {
    final shift = DriverShift.fromJson({
      ..._shiftJson(puedeOperar: false),
      'en_almuerzo': true,
      'almuerzos': [
        {
          'id': 'lunch-id',
          'iniciada_en': '2026-10-29T12:00:00-06:00',
          'finalizada_en': null,
          'finalizada_por_id': null,
          'motivo_cierre': '',
        },
      ],
    });
    expect(shift.onLunch, isTrue);
    expect(shift.isOperational, isFalse);
    expect(shift.lunchIntervals.single.finishedAt, isNull);
    expect(
      shift.lunchIntervals.single.startedAt,
      DateTime.utc(2026, 10, 29, 18),
    );
  });

  test('la respuesta anterior sigue disponible sin acciones de almuerzo', () {
    final day = ActiveShiftDay.fromJson({'jornada': _shiftJson()});
    expect(day.supportsDailySchedule, isFalse);
    expect(day.shift!.isOperational, isTrue);
    expect(day.shift!.onLunch, isFalse);
  });

  test('almuerzo envía cuerpo vacío a los dos endpoints exactos', () async {
    final api = ContractApi((options) => (status: 200, data: _shiftJson()));
    final service = ShiftsApiService(api.client);
    await service.startLunch('shift-id');
    await service.finishLunch('shift-id');
    expect(api.calls.map((call) => call.path), [
      'jornadas/shift-id/almuerzo/iniciar/',
      'jornadas/shift-id/almuerzo/finalizar/',
    ]);
    expect(
      api.calls.every((call) => call.data is Map && (call.data as Map).isEmpty),
      isTrue,
    );
  });

  test('se conserva el motivo de validación de almuerzo', () async {
    final api = ContractApi(
      (options) =>
          (status: 400, data: {'almuerzo': 'Hay trabajos pendientes.'}),
    );
    try {
      await ShiftsApiService(api.client).startLunch('shift-id');
      fail('Debía rechazar el almuerzo.');
    } on AppFailure catch (failure) {
      expect(failure.fieldMessage('almuerzo'), 'Hay trabajos pendientes.');
    }
  });

  test('el filtro administrativo no confunde PAUSED con almuerzo', () {
    expect(
      const DriverQuery(onLunch: true).toQueryParameters()['en_almuerzo'],
      true,
    );
    expect(
      const DriverQuery(onLunch: false).toQueryParameters()['en_almuerzo'],
      false,
    );
    expect(
      const DriverQuery().toQueryParameters().containsKey('en_almuerzo'),
      isFalse,
    );
    final profile = DriverProfile.fromJson({
      'id': 'driver-id',
      'usuario': {
        'id': 'user-id',
        'correo': 'motorista@example.com',
        'nombres': 'Ana',
        'apellidos': 'López',
        'estado': 'ACTIVO',
      },
      'estado_operativo': 'PAUSED',
      'capacidad': 'AVAILABLE',
      'activo': true,
      'en_almuerzo': false,
      'almuerzo_iniciado_en': null,
      'creado_en': '2026-10-29T08:00:00-06:00',
      'actualizado_en': '2026-10-29T08:00:00-06:00',
    });
    expect(profile.operationalStatus, 'PAUSED');
    expect(profile.onLunch, isFalse);
    expect(profile.lunchStartedAt, isNull);
  });
}

Map<String, dynamic> _shiftJson({bool? puedeOperar}) {
  final json = <String, dynamic>{
    'id': 'shift-id',
    'repartidor_id': 'driver-id',
    'estado': 'ACTIVA',
    'iniciada_en': '2026-10-29T08:00:00-06:00',
    'creado_en': '2026-10-29T08:00:00-06:00',
    'actualizado_en': '2026-10-29T08:00:00-06:00',
  };
  if (puedeOperar != null) json['puede_operar'] = puedeOperar;
  return json;
}
