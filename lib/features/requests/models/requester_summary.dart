import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class RequesterSummary {
  const RequesterSummary({
    required this.total,
    required this.pending,
    required this.active,
    required this.delivered,
    required this.failed,
    required this.cancelled,
    required this.recent,
    this.operationalDate,
    this.operationalTimeZone,
    this.deliveredToday,
    this.recentDeliveredToday = const [],
  });

  factory RequesterSummary.fromJson(Map<String, dynamic> json) {
    return RequesterSummary(
      total: optionalInt(json, 'total'),
      pending: optionalInt(json, 'pendientes'),
      active: optionalInt(json, 'activas'),
      delivered: optionalInt(json, 'entregadas'),
      failed: optionalInt(json, 'fallidas'),
      cancelled: optionalInt(json, 'canceladas'),
      recent: jsonMapList(
        json['recientes'],
        'recientes',
      ).map(ServiceRequestSummary.fromJson).toList(growable: false),
      operationalDate: _operationalDate(json['fecha_operativa']),
      operationalTimeZone: _operationalTimeZone(json['zona_horaria_operativa']),
      deliveredToday: _deliveredToday(json['entregadas_del_dia']),
      recentDeliveredToday: json['entregas_recientes_del_dia'] == null
          ? const []
          : jsonMapList(
              json['entregas_recientes_del_dia'],
              'entregas_recientes_del_dia',
            ).map(DailyDelivery.fromJson).toList(growable: false),
    );
  }

  final int total;
  final int pending;
  final int active;
  final int delivered;
  final int failed;
  final int cancelled;
  final List<ServiceRequestSummary> recent;
  final String? operationalDate;
  final String? operationalTimeZone;
  final int? deliveredToday;
  final List<DailyDelivery> recentDeliveredToday;

  bool get hasDailySummary =>
      operationalDate != null &&
      operationalTimeZone != null &&
      deliveredToday != null;
}

class DailyDelivery {
  const DailyDelivery({required this.request, required this.deliveredAt});

  factory DailyDelivery.fromJson(Map<String, dynamic> json) {
    return DailyDelivery(
      request: ServiceRequestSummary.fromJson(json),
      deliveredAt: requireDateTime(json, 'entregada_en'),
    );
  }

  final ServiceRequestSummary request;
  final DateTime deliveredAt;
}

String? _operationalDate(Object? value) {
  if (value == null) return null;
  if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null &&
        parsed.year.toString().padLeft(4, '0') == value.substring(0, 4) &&
        parsed.month.toString().padLeft(2, '0') == value.substring(5, 7) &&
        parsed.day.toString().padLeft(2, '0') == value.substring(8, 10)) {
      return value;
    }
  }
  throw const FormatException('fecha_operativa no contiene una fecha válida.');
}

String? _operationalTimeZone(Object? value) {
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw const FormatException(
    'zona_horaria_operativa no contiene una zona horaria válida.',
  );
}

int? _deliveredToday(Object? value) {
  if (value == null) return null;
  if (value is int && value >= 0) return value;
  throw const FormatException(
    'entregadas_del_dia no contiene un conteo válido.',
  );
}
