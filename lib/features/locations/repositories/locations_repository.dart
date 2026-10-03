import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';

abstract interface class LocationsRepository {
  Future<PaginatedResult<CompanyLocation>> getLocations({
    required String companyId,
    required int page,
    int pageSize,
  });

  Future<List<LocationType>> getLocationTypes();

  Future<Location> getLocation(String locationId);

  Future<void> createLocation(CreateLocationInput input);

  Future<void> updateAuthorization({
    required String locationId,
    required String companyId,
    required LocationAuthorizationInput input,
  });
}
