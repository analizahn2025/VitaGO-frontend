import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/models/location_inputs.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';
import 'package:vitago_app/features/locations/repositories/locations_repository.dart';
import 'package:vitago_app/features/locations/services/locations_api_service.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  const LocationsRepositoryImpl(this._apiService);

  final LocationsApiService _apiService;

  @override
  Future<PaginatedResult<CompanyLocation>> getLocations({
    required String companyId,
    required int page,
    int pageSize = 20,
  }) => _apiService.getLocations(
    companyId: companyId,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<List<LocationType>> getLocationTypes() =>
      _apiService.getLocationTypes();

  @override
  Future<Location> getLocation(String locationId) =>
      _apiService.getLocation(locationId);

  @override
  Future<void> createLocation(CreateLocationInput input) =>
      _apiService.createLocation(input);

  @override
  Future<void> updateAuthorization({
    required String locationId,
    required String companyId,
    required LocationAuthorizationInput input,
  }) => _apiService.updateAuthorization(
    locationId: locationId,
    companyId: companyId,
    input: input,
  );
}
