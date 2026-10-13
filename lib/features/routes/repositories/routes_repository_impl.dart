import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/services/routes_api_service.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  const RoutesRepositoryImpl(this._apiService);

  final RoutesApiService _apiService;

  @override
  Future<DriverRoute> getMyRoute() => _apiService.getMyRoute();

  @override
  Future<RoadRoute> calculate(CalculateRouteInput input) =>
      _apiService.calculate(input);
}
