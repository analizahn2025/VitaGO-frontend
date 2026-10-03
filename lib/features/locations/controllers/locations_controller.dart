import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';
import 'package:vitago_app/features/locations/providers/locations_providers.dart';
import 'package:vitago_app/features/locations/repositories/locations_repository.dart';

typedef LocationPageQuery = ({String companyId, int page, int pageSize});

final locationsControllerProvider = FutureProvider.autoDispose
    .family<PaginatedResult<CompanyLocation>, LocationPageQuery>((ref, query) {
      return ref
          .watch(locationsRepositoryProvider)
          .getLocations(
            companyId: query.companyId,
            page: query.page,
            pageSize: query.pageSize,
          );
    });

final locationTypesControllerProvider =
    FutureProvider.autoDispose<List<LocationType>>((ref) {
      return ref.watch(locationsRepositoryProvider).getLocationTypes();
    });

final locationControllerProvider = FutureProvider.autoDispose
    .family<Location, String>((ref, locationId) {
      return ref.watch(locationsRepositoryProvider).getLocation(locationId);
    });

final locationActionsControllerProvider = Provider<LocationActionsController>((
  ref,
) {
  return LocationActionsController(ref.watch(locationsRepositoryProvider));
});

class LocationActionsController {
  const LocationActionsController(this._repository);

  final LocationsRepository _repository;

  Future<void> createLocation(CreateLocationInput input) =>
      _repository.createLocation(input);

  Future<void> updateAuthorization({
    required String locationId,
    required String companyId,
    required LocationAuthorizationInput input,
  }) => _repository.updateAuthorization(
    locationId: locationId,
    companyId: companyId,
    input: input,
  );
}
