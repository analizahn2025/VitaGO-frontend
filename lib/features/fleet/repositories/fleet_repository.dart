import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';

abstract interface class FleetRepository {
  Future<PaginatedResult<Vehicle>> getVehicles(VehicleQuery query);
  Future<Vehicle> getVehicle(String vehicleId);
  Future<Vehicle> createVehicle(
    CreateVehicleInput input, {
    required bool isCorporate,
  });
  Future<PaginatedResult<DriverProfile>> getDrivers(DriverQuery query);
  Future<PaginatedResult<DriverProfile>> getAvailableDrivers();
  Future<DriverProfile> getDriver(String driverId);
  Future<DriverProfile> getOwnDriverProfile();
  Future<DriverProfile> createDriver(
    CreateDriverInput input, {
    required bool isCorporate,
  });
  Future<DriverProfile> updateDriverOperation(
    String driverId,
    UpdateDriverOperationInput input,
  );
}
