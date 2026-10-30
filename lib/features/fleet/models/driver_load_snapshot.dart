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
    this.flaskLimit,
    this.committedFlasks,
    this.transportedFlasks,
    this.reservedFlasks,
    this.availableFlasks,
    this.requestsWithoutFlaskCount,
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
        flaskLimit: nullableInt(json, 'limite_frascos'),
        committedFlasks: nullableInt(json, 'frascos_comprometidos'),
        transportedFlasks: nullableInt(json, 'frascos_en_transporte'),
        reservedFlasks: nullableInt(json, 'frascos_reservados'),
        availableFlasks: nullableInt(json, 'frascos_disponibles'),
        requestsWithoutFlaskCount: nullableInt(
          json,
          'solicitudes_sin_cantidad_frascos',
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
        flaskLimit: driver.flaskLimit,
        committedFlasks: driver.committedFlasks,
        transportedFlasks: driver.transportedFlasks,
        reservedFlasks: driver.reservedFlasks,
        availableFlasks: driver.availableFlasks,
        requestsWithoutFlaskCount: driver.requestsWithoutFlaskCount,
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
      requestsWithoutTubeCount,
      flaskLimit,
      committedFlasks,
      transportedFlasks,
      reservedFlasks,
      availableFlasks,
      requestsWithoutFlaskCount;
  final String capacity;
  final bool canReceiveRequests;
}
