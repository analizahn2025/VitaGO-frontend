import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/fleet/models/fleet_inputs.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/providers/fleet_providers.dart';
import 'package:vitago_app/features/fleet/repositories/fleet_repository.dart';

final vehiclesControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Vehicle>, VehicleQuery>((ref, query) {
      return ref.watch(fleetRepositoryProvider).getVehicles(query);
    });

final vehicleSelectionControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Vehicle>, String?>((ref, companyId) {
      return ref
          .watch(fleetRepositoryProvider)
          .getVehicles(
            VehicleQuery(companyId: companyId, pageSize: 100, status: 'ACTIVO'),
          );
    });

final vehicleControllerProvider = FutureProvider.autoDispose
    .family<Vehicle, String>((ref, vehicleId) {
      return ref.watch(fleetRepositoryProvider).getVehicle(vehicleId);
    });

final driversControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DriverProfile>, DriverQuery>((ref, query) {
      return ref.watch(fleetRepositoryProvider).getDrivers(query);
    });

final availableDriversControllerProvider =
    FutureProvider.autoDispose<PaginatedResult<DriverProfile>>((ref) {
      return ref.watch(fleetRepositoryProvider).getAvailableDrivers();
    });

final driverControllerProvider = FutureProvider.autoDispose
    .family<DriverProfile, String>((ref, driverId) {
      return ref.watch(fleetRepositoryProvider).getDriver(driverId);
    });

final ownDriverProfileControllerProvider =
    FutureProvider.autoDispose<DriverProfile>((ref) {
      return ref.watch(fleetRepositoryProvider).getOwnDriverProfile();
    });

final fleetActionsControllerProvider = Provider<FleetActionsController>((ref) {
  return FleetActionsController(ref.watch(fleetRepositoryProvider));
});

class FleetActionsController {
  const FleetActionsController(this._repository);

  final FleetRepository _repository;

  Future<Vehicle> createVehicle(
    CreateVehicleInput input, {
    required bool isCorporate,
  }) => _repository.createVehicle(input, isCorporate: isCorporate);

  Future<DriverProfile> createDriver(
    CreateDriverInput input, {
    required bool isCorporate,
  }) => _repository.createDriver(input, isCorporate: isCorporate);

  Future<DriverProfile> updateDriverOperation(
    String driverId,
    UpdateDriverOperationInput input,
  ) => _repository.updateDriverOperation(driverId, input);
}
