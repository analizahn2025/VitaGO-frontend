import 'package:vitago_app/core/models/json_readers.dart';

class DriverNotificationFeed {
  const DriverNotificationFeed({required this.count, required this.items});

  factory DriverNotificationFeed.fromJson(Object? data) {
    if (data is List) {
      final items = _parseItems(data);
      return DriverNotificationFeed(count: items.length, items: items);
    }

    final json = requireJsonMap(data, 'notificaciones');
    final rawItems = json['resultados'] ?? json['notificaciones'];
    final items = _parseItems(rawItems);
    return DriverNotificationFeed(
      count: optionalInt(json, 'conteo', fallback: items.length),
      items: items,
    );
  }

  final int count;
  final List<DriverNotification> items;

  static List<DriverNotification> _parseItems(Object? data) {
    return jsonMapList(
      data,
      'notificaciones',
    ).map(DriverNotification.fromJson).toList(growable: false);
  }
}

class DriverNotification {
  const DriverNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.isImportant,
    this.requestId,
    this.route,
    this.deepLink,
    this.createdAt,
    this.readAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    final type = optionalString(json, 'tipo') ?? 'ACTUALIZACION';
    final request = optionalJsonMap(json, 'solicitud');
    return DriverNotification(
      id: optionalString(json, 'id') ?? '${type}_${json.hashCode}',
      type: type,
      title: optionalString(json, 'titulo') ?? _titleFor(type),
      message:
          optionalString(json, 'mensaje') ??
          optionalString(json, 'descripcion') ??
          'Tienes una actualización en VitaGo.',
      requestId:
          optionalString(json, 'solicitud_id') ??
          (request == null ? null : optionalString(request, 'id')),
      route: optionalString(json, 'ruta'),
      deepLink: optionalString(json, 'enlace_profundo'),
      isRead: _boolValue(json['leida'] ?? json['leido']),
      isImportant:
          _boolValue(json['importante']) ||
          type.toUpperCase().contains('PRIORIT'),
      createdAt: optionalDateTime(json, 'creado_en'),
      readAt: optionalDateTime(json, 'leida_en'),
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final String? requestId;
  final String? route;
  final String? deepLink;
  final bool isRead;
  final bool isImportant;
  final DateTime? createdAt;
  final DateTime? readAt;

  static bool _boolValue(Object? value) {
    if (value is bool) return value;
    return switch (value?.toString().toLowerCase()) {
      '1' || 'true' || 'si' || 'sí' => true,
      _ => false,
    };
  }

  static String _titleFor(String type) {
    return switch (type.toUpperCase()) {
      'SOLICITUD_ASIGNADA' || 'ASIGNACION' => 'Servicio asignado',
      'SOLICITUD_PRIORITARIA' => 'Servicio prioritario',
      'SOLICITUD_ACTUALIZADA' => 'Servicio actualizado',
      _ => 'Actualización de VitaGo',
    };
  }
}
