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
    );
  }

  final int total;
  final int pending;
  final int active;
  final int delivered;
  final int failed;
  final int cancelled;
  final List<ServiceRequestSummary> recent;
}
