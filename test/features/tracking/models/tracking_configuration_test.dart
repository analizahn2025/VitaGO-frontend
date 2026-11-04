import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';

void main() {
  test('lee la política cercana publicada dentro de llegada automática', () {
    final configuration = TrackingConfiguration.fromJson({
      ..._configurationJson,
      'llegada_automatica': {
        'habilitada': true,
        'radio_metros': 50,
        'permanencia_minima_segundos': 10,
        'minimo_puntos': 3,
        'precision_maxima_metros': 20,
        'antiguedad_maxima_segundos': 30,
        'solo_proxima_parada': true,
        'destino_especial_sin_coordenadas_manual': true,
        'captura_cercana': {
          'habilitada': true,
          'radio_activacion_metros': 250,
          'radio_desactivacion_metros': 350,
          'intervalo_captura_segundos': 5,
          'intervalo_envio_segundos': 5,
          'enviar_al_entrar': true,
          'aplica_detenido': true,
        },
      },
    });
    expect(configuration.nearbyCapture?.enabled, isTrue);
    expect(configuration.nearbyCapture?.activationMeters, 250);
    expect(configuration.nearbyCapture?.target, isNull);
  });

  test(
    'lee los umbrales informativos de desvío sin calcularlos en Flutter',
    () {
      final configuration = TrackingConfiguration.fromJson({
        ..._configurationJson,
        'desviacion_ruta': {
          'habilitada': true,
          'radio_metros': 150.0,
          'radio_regreso_metros': 75.0,
          'permanencia_minima_segundos': 60,
          'minimo_puntos': 3,
          'precision_maxima_metros': 50.0,
          'antiguedad_maxima_segundos': 60,
          'requiere_ruta_vial_vigente': true,
          'solo_proxima_parada': true,
        },
      });
      expect(configuration.routeDeviation?.enabled, isTrue);
      expect(configuration.routeDeviation?.radiusMeters, 150);
      expect(configuration.routeDeviation?.returnRadiusMeters, 75);
      expect(configuration.routeDeviation?.minimumPoints, 3);
      expect(configuration.routeDeviation?.requiresCurrentRoadRoute, isTrue);
      expect(
        TrackingConfiguration.fromJson(_configurationJson).routeDeviation,
        isNull,
      );
    },
  );

  test(
    'lee la autorización de GPS de la jornada sin depender de servicios',
    () {
      final configuration = TrackingConfiguration.fromJson({
        ..._configurationJson,
        'seguimiento_jornada': {
          'captura_habilitada': true,
          'jornada_id': 'shift-id',
          'cierre_programado_en': '2026-10-31T04:00:00+00:00',
          'requiere_servicio_activo': false,
          'incluye_tiempo_sin_servicios': true,
          'incluye_almuerzo': true,
          'detener_al_finalizar_jornada': true,
        },
      });
      final policy = configuration.shiftTracking!;
      expect(policy.permitsCaptureFor('shift-id'), isTrue);
      expect(policy.permitsCaptureFor('another-shift'), isFalse);
      expect(policy.requiresActiveService, isFalse);
      expect(policy.includesTimeWithoutServices, isTrue);
      expect(policy.includesLunch, isTrue);
      expect(policy.scheduledCloseAt, DateTime.utc(2026, 10, 31, 4));
    },
  );

  test(
    'sin jornada no autoriza capturas y acepta la configuración antigua',
    () {
      final configuration = TrackingConfiguration.fromJson({
        ..._configurationJson,
        'seguimiento_jornada': {
          'captura_habilitada': false,
          'jornada_id': null,
          'cierre_programado_en': null,
          'requiere_servicio_activo': false,
          'incluye_tiempo_sin_servicios': true,
          'incluye_almuerzo': true,
          'detener_al_finalizar_jornada': true,
        },
      });
      expect(
        configuration.shiftTracking!.permitsCaptureFor('shift-id'),
        isFalse,
      );
      expect(
        TrackingConfiguration.fromJson(_configurationJson).shiftTracking,
        isNull,
      );
    },
  );

  test(
    'lee configuración de llegada sin calcular geocercas en el teléfono',
    () {
      final config = TrackingConfiguration.fromJson({
        ..._configurationJson,
        'llegada_automatica': {
          'habilitada': true,
          'radio_metros': 50.0,
          'permanencia_minima_segundos': 10,
          'minimo_puntos': 3,
          'precision_maxima_metros': 20.0,
          'antiguedad_maxima_segundos': 30,
          'solo_proxima_parada': true,
          'destino_especial_sin_coordenadas_manual': true,
        },
      }).automaticArrival!;
      expect(config.enabled, isTrue);
      expect(config.radiusMeters, 50);
      expect(config.minimumDwellSeconds, 10);
      expect(config.minimumPoints, 3);
      expect(config.maximumAccuracyMeters, 20);
      expect(config.maximumAgeSeconds, 30);
      expect(config.onlyNextStop, isTrue);
      expect(config.manualSpecialDestinationWithoutCoordinates, isTrue);
      expect(
        TrackingConfiguration.fromJson(_configurationJson).automaticArrival,
        isNull,
      );
    },
  );
  test(
    'lee la cadencia 5/15 y el diagnóstico de captura del contrato 0.31.0',
    () {
      final configuration = TrackingConfiguration.fromJson({
        ..._configurationJson,
        'diagnostico_captura': {
          'muestra_puntos': 60,
          'intervalos_evaluados': 59,
          'intervalos_fuera_umbral': 2,
          'intervalo_maximo_observado_segundos': 42.5,
          'requiere_ajuste_captura': true,
          'mensaje': 'Se detectaron intervalos de captura mayores al umbral.',
          'umbral_segundos': 30,
        },
      });

      expect(configuration.movingCaptureSeconds, 5);
      expect(configuration.stoppedCaptureSeconds, 15);
      expect(configuration.sendIntervalSeconds, 20);
      expect(configuration.maximumMeasurementIntervalSeconds, 30);
      final diagnostics = configuration.captureDiagnostics!;
      expect(diagnostics.samplePoints, 60);
      expect(diagnostics.evaluatedIntervals, 59);
      expect(diagnostics.intervalsAboveThreshold, 2);
      expect(diagnostics.maximumObservedIntervalSeconds, 42.5);
      expect(diagnostics.requiresCaptureAdjustment, isTrue);
      expect(diagnostics.message, isNotEmpty);
      expect(diagnostics.thresholdSeconds, 30);
    },
  );

  test('acepta configuración previa y diagnóstico sin puntos de jornada', () {
    expect(
      TrackingConfiguration.fromJson(_configurationJson).captureDiagnostics,
      isNull,
    );
    final configuration = TrackingConfiguration.fromJson({
      ..._configurationJson,
      'diagnostico_captura': {
        'muestra_puntos': 0,
        'intervalos_evaluados': 0,
        'intervalos_fuera_umbral': 0,
        'intervalo_maximo_observado_segundos': null,
        'requiere_ajuste_captura': false,
        'mensaje': null,
        'umbral_segundos': 30,
      },
    });

    expect(
      configuration.captureDiagnostics!.maximumObservedIntervalSeconds,
      isNull,
    );
    expect(
      configuration.captureDiagnostics!.requiresCaptureAdjustment,
      isFalse,
    );
    expect(configuration.captureDiagnostics!.message, isNull);
    expect(TrackingConfiguration.defaults.stoppedCaptureSeconds, 15);
  });
}

const _configurationJson = <String, dynamic>{
  'hora_servidor': '2026-10-22T18:00:00Z',
  'zona_horaria_operativa': 'America/Tegucigalpa',
  'intervalo_captura_movimiento_segundos': 5,
  'intervalo_captura_detenido_segundos': 15,
  'intervalo_envio_segundos': 20,
  'tamano_maximo_lote': 200,
  'antiguedad_maxima_asignacion_segundos': 120,
  'precision_maxima_asignacion_metros': 50.0,
  'asignacion_requiere_gps_vigente': true,
  'intervalo_maximo_medicion_segundos': 30,
  'cobertura_minima_porcentaje': 90.0,
};
