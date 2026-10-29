import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';

void main() {
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
