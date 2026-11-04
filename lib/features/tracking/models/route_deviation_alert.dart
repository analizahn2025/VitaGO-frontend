import 'package:vitago_app/core/models/json_readers.dart';

class RouteDeviationAlert {
  const RouteDeviationAlert({
    required this.id,
    required this.eventId,
    required this.type,
    required this.requestId,
    required this.stopType,
    required this.detectedAt,
    required this.title,
    required this.message,
    required this.route,
    this.finalizedAt,
  });

  factory RouteDeviationAlert.fromJson(Map<String, dynamic> json) {
    return RouteDeviationAlert(
      id: requireString(json, 'id'),
      eventId: requireString(json, 'evento_id'),
      type: requireString(json, 'tipo'),
      requestId: requireString(json, 'solicitud_id'),
      stopType: requireString(json, 'tipo_parada'),
      detectedAt: requireDateTime(json, 'detectada_en'),
      finalizedAt: optionalDateTime(json, 'finalizada_en'),
      title: requireString(json, 'titulo'),
      message: requireString(json, 'mensaje'),
      route: requireString(json, 'ruta'),
    );
  }

  final String id;
  final String eventId;
  final String type;
  final String requestId;
  final String stopType;
  final DateTime detectedAt;
  final DateTime? finalizedAt;
  final String title;
  final String message;
  final String route;

  bool get isActive => finalizedAt == null;
}

List<RouteDeviationAlert> parseRouteDeviationAlerts(Object? raw) => raw == null
    ? const []
    : jsonMapList(
        raw,
        'alertas_ruta',
      ).map(RouteDeviationAlert.fromJson).toList(growable: false);
