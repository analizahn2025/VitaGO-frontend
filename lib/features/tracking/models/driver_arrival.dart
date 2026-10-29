import 'package:vitago_app/core/models/json_readers.dart';

/// A server-confirmed arrival, never a geofence calculated by the phone.
class DriverArrival {
  const DriverArrival({
    required this.eventId,
    required this.requestId,
    required this.status,
    required this.stopType,
    required this.detectedAt,
    required this.source,
    required this.screen,
  });

  factory DriverArrival.fromJson(Map<String, dynamic> json) => DriverArrival(
    eventId: requireString(json, 'evento_id'),
    requestId: requireString(json, 'solicitud_id'),
    status: requireString(json, 'estado'),
    stopType: requireString(json, 'tipo_parada'),
    detectedAt: requireDateTime(json, 'detectada_en'),
    source: requireString(json, 'fuente'),
    screen: requireString(json, 'pantalla'),
  );

  final String eventId;
  final String requestId;
  final String status;
  final String stopType;
  final DateTime detectedAt;
  final String source;
  final String screen;

  bool get isSupported =>
      (source == 'GPS' || source == 'MANUAL') &&
      ((status == 'AT_PICKUP' &&
              stopType == 'RECOLECCION' &&
              screen == 'RECOLECCION') ||
          (status == 'AT_DESTINATION' &&
              stopType == 'ENTREGA' &&
              screen == 'ENTREGA'));

  String get targetStatus => status == 'AT_PICKUP' ? 'PICKED_UP' : 'DELIVERED';
}

List<DriverArrival> parseDriverArrivals(dynamic value) {
  if (value is! List) return const [];
  final arrivals = <DriverArrival>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) continue;
    try {
      final arrival = DriverArrival.fromJson(item);
      if (arrival.isSupported) arrivals.add(arrival);
    } on FormatException {
      // Optional navigation metadata must not invalidate an accepted GPS batch.
    }
  }
  return List.unmodifiable(arrivals);
}
