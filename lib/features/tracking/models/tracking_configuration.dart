import 'package:vitago_app/core/models/json_readers.dart';

class TrackingConfiguration {
  const TrackingConfiguration({
    required this.movingCaptureSeconds,
    required this.stoppedCaptureSeconds,
    required this.sendIntervalSeconds,
    required this.maximumBatchSize,
    required this.maximumAssignmentAgeSeconds,
    required this.maximumAssignmentAccuracyMeters,
    required this.assignmentRequiresCurrentGps,
    required this.maximumMeasurementIntervalSeconds,
    required this.minimumCoveragePercentage,
  });

  factory TrackingConfiguration.fromJson(Map<String, dynamic> json) {
    return TrackingConfiguration(
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
    );
  }

  static const defaults = TrackingConfiguration(
    movingCaptureSeconds: 5,
    stoppedCaptureSeconds: 30,
    sendIntervalSeconds: 20,
    maximumBatchSize: 200,
    maximumAssignmentAgeSeconds: 120,
    maximumAssignmentAccuracyMeters: 50,
    assignmentRequiresCurrentGps: true,
    maximumMeasurementIntervalSeconds: 30,
    minimumCoveragePercentage: 90,
  );

  final int movingCaptureSeconds;
  final int stoppedCaptureSeconds;
  final int sendIntervalSeconds;
  final int maximumBatchSize;
  final int maximumAssignmentAgeSeconds;
  final double maximumAssignmentAccuracyMeters;
  final bool assignmentRequiresCurrentGps;
  final int maximumMeasurementIntervalSeconds;
  final double minimumCoveragePercentage;
}

double _double(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('El campo $key no es numérico.');
  return parsed;
}
