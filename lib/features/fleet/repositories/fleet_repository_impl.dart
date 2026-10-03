import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/repositories/fleet_repository.dart';
import 'package:vitago_app/features/fleet/services/fleet_api_service.dart';

class FleetRepositoryImpl implements FleetRepository {
  const FleetRepositoryImpl(this._apiService);

  final FleetApiService _apiService;

  @override
  Future<PaginatedResult<Vehicle>> getVehicles(VehicleQuery query) =>
      _apiService.getVehicles(query);

  @override
  Future<Vehicle> getVehicle(String vehicleId) =>
      _apiService.getVehicle(vehicleId);

  @override
  Future<Vehicle> createVehicle(
    CreateVehicleInput input, {
    required bool isCorporate,
  }) => _apiService.createVehicle(input, isCorporate: isCorporate);

  @override
  Future<PaginatedResult<DriverProfile>> getDrivers(DriverQuery query) =>
      _apiService.getDrivers(query);

  @override
  Future<PaginatedResult<DriverProfile>> getAvailableDrivers() =>
      _apiService.getAvailableDrivers();

  @override
  Future<DriverProfile> getDriver(String driverId) =>
      _apiService.getDriver(driverId);

  @override
  Future<DriverProfile> getOwnDriverProfile() =>
      _apiService.getOwnDriverProfile();

  @override
  Future<DriverProfile> createDriver(
    CreateDriverInput input, {
    required bool isCorporate,
  }) => _apiService.createDriver(input, isCorporate: isCorporate);

  @override
  Future<DriverProfile> updateDriverOperation(
    String driverId,
    UpdateDriverOperationInput input,
  ) => _apiService.updateDriverOperation(driverId, input);
}
