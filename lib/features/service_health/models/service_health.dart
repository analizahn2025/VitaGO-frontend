import 'package:vitago_app/core/models/json_readers.dart';

class ServiceHealth {
  const ServiceHealth({required this.status, required this.service});

  factory ServiceHealth.fromJson(Map<String, dynamic> json) {
    return ServiceHealth(
      status: requireString(json, 'estado'),
      service: requireString(json, 'servicio'),
    );
  }

  final String status;
  final String service;

  bool get isHealthy => status.toLowerCase() == 'correcto';
}
