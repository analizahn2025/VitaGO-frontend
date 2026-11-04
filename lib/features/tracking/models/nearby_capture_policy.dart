import 'dart:math' as math;

import 'package:vitago_app/core/models/json_readers.dart';

/// Server-selected stop and cadence. This never confirms an arrival locally.
class NearbyCapturePolicy {
  const NearbyCapturePolicy({
    required this.enabled,
    required this.activationMeters,
    required this.deactivationMeters,
    required this.captureSeconds,
    required this.sendSeconds,
    required this.sendOnEntry,
    required this.appliesStopped,
    this.target,
  });

  factory NearbyCapturePolicy.fromJson(Map<String, dynamic> json) {
    final targetJson = optionalJsonMap(json, 'objetivo');
    return NearbyCapturePolicy(
      enabled: optionalBool(json, 'habilitada'),
      activationMeters: _number(json, 'radio_activacion_metros'),
      deactivationMeters: _number(json, 'radio_desactivacion_metros'),
      captureSeconds: optionalInt(json, 'intervalo_captura_segundos'),
      sendSeconds: optionalInt(json, 'intervalo_envio_segundos'),
      sendOnEntry: optionalBool(json, 'enviar_al_entrar'),
      appliesStopped: optionalBool(json, 'aplica_detenido'),
      target: targetJson == null
          ? null
          : NearbyCaptureTarget.fromJson(targetJson),
    );
  }

  final bool enabled;
  final double activationMeters;
  final double deactivationMeters;
  final int captureSeconds;
  final int sendSeconds;
  final bool sendOnEntry;
  final bool appliesStopped;
  final NearbyCaptureTarget? target;

  bool get isUsable =>
      enabled &&
      target != null &&
      activationMeters > 0 &&
      deactivationMeters > activationMeters &&
      captureSeconds > 0 &&
      sendSeconds > 0;

  bool shouldBeNearby(
    double latitude,
    double longitude, {
    required bool wasNearby,
  }) {
    if (!isUsable) return false;
    final distance = target!.distanceMetersTo(latitude, longitude);
    return distance <= (wasNearby ? deactivationMeters : activationMeters);
  }
}

class NearbyCaptureTarget {
  const NearbyCaptureTarget({
    required this.requestId,
    required this.stopType,
    required this.locationId,
    required this.latitude,
    required this.longitude,
  });

  factory NearbyCaptureTarget.fromJson(Map<String, dynamic> json) =>
      NearbyCaptureTarget(
        requestId: requireString(json, 'solicitud_id'),
        stopType: requireString(json, 'tipo_parada'),
        locationId: requireString(json, 'ubicacion_id'),
        latitude: _number(json, 'latitud'),
        longitude: _number(json, 'longitud'),
      );

  final String requestId;
  final String stopType;
  final String locationId;
  final double latitude;
  final double longitude;

  String get key => '$requestId:$stopType:$locationId';

  double distanceMetersTo(double otherLatitude, double otherLongitude) {
    const earthRadius = 6371000.0;
    const radians = math.pi / 180;
    final latitudeDifference = (otherLatitude - latitude) * radians;
    final longitudeDifference = (otherLongitude - longitude) * radians;
    final arc =
        math.pow(math.sin(latitudeDifference / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(otherLatitude * radians) *
            math.pow(math.sin(longitudeDifference / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(arc.clamp(0.0, 1.0)));
  }
}

double _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('El campo $key no es numérico.');
  }
  return parsed;
}
