import 'package:vitago_app/core/models/json_readers.dart';

class TrackingConfiguration {
  const TrackingConfiguration({
    required this.serverTime,
    required this.operationalTimeZone,
    required this.movingCaptureSeconds,
    required this.stoppedCaptureSeconds,
    required this.sendIntervalSeconds,
    required this.maximumBatchSize,
    required this.maximumAssignmentAgeSeconds,
    required this.maximumAssignmentAccuracyMeters,
    required this.assignmentRequiresCurrentGps,
    required this.maximumMeasurementIntervalSeconds,
    required this.minimumCoveragePercentage,
    this.captureDiagnostics,
    this.automaticArrival,
  });

  factory TrackingConfiguration.fromJson(Map<String, dynamic> json) {
    final diagnostics = optionalJsonMap(json, 'diagnostico_captura');
    final arrival = optionalJsonMap(json, 'llegada_automatica');
    return TrackingConfiguration(
      serverTime: requireDateTime(json, 'hora_servidor'),
      operationalTimeZone: requireString(json, 'zona_horaria_operativa'),
      movingCaptureSeconds: optionalInt(
        json,
        'intervalo_captura_movimiento_segundos',
      ),
      stoppedCaptureSeconds: optionalInt(
        json,
        'intervalo_captura_detenido_segundos',
      ),
      sendIntervalSeconds: optionalInt(json, 'intervalo_envio_segundos'),
      maximumBatchSize: optionalInt(json, 'tamano_maximo_lote'),
      maximumAssignmentAgeSeconds: optionalInt(
        json,
        'antiguedad_maxima_asignacion_segundos',
      ),
      maximumAssignmentAccuracyMeters: _double(
        json,
        'precision_maxima_asignacion_metros',
      ),
      assignmentRequiresCurrentGps: optionalBool(
        json,
        'asignacion_requiere_gps_vigente',
      ),
      maximumMeasurementIntervalSeconds: optionalInt(
        json,
        'intervalo_maximo_medicion_segundos',
      ),
      minimumCoveragePercentage: _double(json, 'cobertura_minima_porcentaje'),
      captureDiagnostics: diagnostics == null
          ? null
          : TrackingCaptureDiagnostics.fromJson(diagnostics),
      automaticArrival: arrival == null
          ? null
          : AutomaticArrivalConfiguration.fromJson(arrival),
    );
  }

  static const defaults = TrackingConfiguration(
    serverTime: null,
    operationalTimeZone: null,
    movingCaptureSeconds: 5,
    stoppedCaptureSeconds: 15,
    sendIntervalSeconds: 20,
    maximumBatchSize: 200,
    maximumAssignmentAgeSeconds: 120,
    maximumAssignmentAccuracyMeters: 50,
    assignmentRequiresCurrentGps: true,
    maximumMeasurementIntervalSeconds: 30,
    minimumCoveragePercentage: 90,
  );

  final DateTime? serverTime;
  final String? operationalTimeZone;
  final int movingCaptureSeconds;
  final int stoppedCaptureSeconds;
  final int sendIntervalSeconds;
  final int maximumBatchSize;
  final int maximumAssignmentAgeSeconds;
  final double maximumAssignmentAccuracyMeters;
  final bool assignmentRequiresCurrentGps;
  final int maximumMeasurementIntervalSeconds;
  final double minimumCoveragePercentage;
  final TrackingCaptureDiagnostics? captureDiagnostics;
  final AutomaticArrivalConfiguration? automaticArrival;
}

class AutomaticArrivalConfiguration {
  const AutomaticArrivalConfiguration({
    required this.enabled,
    required this.radiusMeters,
    required this.minimumDwellSeconds,
    required this.minimumPoints,
    required this.maximumAccuracyMeters,
    required this.maximumAgeSeconds,
    required this.onlyNextStop,
    required this.manualSpecialDestinationWithoutCoordinates,
  });

  factory AutomaticArrivalConfiguration.fromJson(Map<String, dynamic> json) =>
      AutomaticArrivalConfiguration(
        enabled: optionalBool(json, 'habilitada'),
        radiusMeters: _double(json, 'radio_metros'),
        minimumDwellSeconds: optionalInt(json, 'permanencia_minima_segundos'),
        minimumPoints: optionalInt(json, 'minimo_puntos'),
        maximumAccuracyMeters: _double(json, 'precision_maxima_metros'),
        maximumAgeSeconds: optionalInt(json, 'antiguedad_maxima_segundos'),
        onlyNextStop: optionalBool(json, 'solo_proxima_parada'),
        manualSpecialDestinationWithoutCoordinates: optionalBool(
          json,
          'destino_especial_sin_coordenadas_manual',
        ),
      );

  final bool enabled;
  final double radiusMeters;
  final int minimumDwellSeconds;
  final int minimumPoints;
  final double maximumAccuracyMeters;
  final int maximumAgeSeconds;
  final bool onlyNextStop;
  final bool manualSpecialDestinationWithoutCoordinates;
}

class TrackingCaptureDiagnostics {
  const TrackingCaptureDiagnostics({
    required this.samplePoints,
    required this.evaluatedIntervals,
    required this.intervalsAboveThreshold,
    required this.requiresCaptureAdjustment,
    required this.thresholdSeconds,
    this.maximumObservedIntervalSeconds,
    this.message,
  });

  factory TrackingCaptureDiagnostics.fromJson(Map<String, dynamic> json) {
    return TrackingCaptureDiagnostics(
      samplePoints: optionalInt(json, 'muestra_puntos'),
      evaluatedIntervals: optionalInt(json, 'intervalos_evaluados'),
      intervalsAboveThreshold: optionalInt(json, 'intervalos_fuera_umbral'),
      maximumObservedIntervalSeconds:
          json['intervalo_maximo_observado_segundos'] == null
          ? null
          : _double(json, 'intervalo_maximo_observado_segundos'),
      requiresCaptureAdjustment: optionalBool(json, 'requiere_ajuste_captura'),
      message: optionalString(json, 'mensaje'),
      thresholdSeconds: optionalInt(json, 'umbral_segundos'),
    );
  }

  final int samplePoints;
  final int evaluatedIntervals;
  final int intervalsAboveThreshold;
  final double? maximumObservedIntervalSeconds;
  final bool requiresCaptureAdjustment;
  final String? message;
  final int thresholdSeconds;
}

double _double(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('El campo $key no es numérico.');
  return parsed;
}
