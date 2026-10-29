import 'package:vitago_app/core/models/json_readers.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

class DriverLoadSnapshot {
  const DriverLoadSnapshot({
    this.tubeLimit,
    this.requestLimit,
    this.activeRequests,
    this.committedTubes,
    this.transportedTubes,
    this.reservedTubes,
    this.availableTubes,
    this.requestsWithoutTubeCount,
    required this.capacity,
    required this.canReceiveRequests,
  });
  factory DriverLoadSnapshot.fromJson(Map<String, dynamic> json) =>
      DriverLoadSnapshot(
        tubeLimit: nullableInt(json, 'limite_tubos'),
        requestLimit: nullableInt(json, 'limite_solicitudes'),
        activeRequests: nullableInt(json, 'solicitudes_activas'),
        committedTubes: nullableInt(json, 'tubos_comprometidos'),
        transportedTubes: nullableInt(json, 'tubos_en_transporte'),
        reservedTubes: nullableInt(json, 'tubos_reservados'),
        availableTubes: nullableInt(json, 'tubos_disponibles'),
        requestsWithoutTubeCount: nullableInt(
          json,
          'solicitudes_sin_cantidad_tubos',
        ),
        capacity: requireString(json, 'capacidad'),
        canReceiveRequests: optionalBool(json, 'puede_recibir_solicitudes'),
      );
  factory DriverLoadSnapshot.fromProfile(DriverProfile driver) =>
      DriverLoadSnapshot(
        tubeLimit: driver.tubeLimit,
        requestLimit: driver.requestLimit,
        activeRequests: driver.activeRequests,
        committedTubes: driver.committedTubes,
        transportedTubes: driver.transportedTubes,
        reservedTubes: driver.reservedTubes,
        availableTubes: driver.availableTubes,
        requestsWithoutTubeCount: driver.requestsWithoutTubeCount,
        capacity: driver.capacity,
        canReceiveRequests: driver.canReceiveRequests,
      );
  final int? tubeLimit,
      requestLimit,
      activeRequests,
      committedTubes,
      transportedTubes,
      reservedTubes,
      availableTubes,
      requestsWithoutTubeCount;
  final String capacity;
  final bool canReceiveRequests;
}
