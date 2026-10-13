import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository.dart';
import 'package:vitago_app/features/routes/repositories/routes_repository_impl.dart';
import 'package:vitago_app/features/routes/services/routes_api_service.dart';

final routesApiServiceProvider = Provider<RoutesApiService>((ref) {
  return RoutesApiService(ref.watch(apiClientProvider));
});

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return RoutesRepositoryImpl(ref.watch(routesApiServiceProvider));
});

final myRouteProvider = FutureProvider.autoDispose<DriverRoute>((ref) {
  return ref.watch(routesRepositoryProvider).getMyRoute();
});

final calculateRouteProvider = Provider<RouteActionsController>((ref) {
  return RouteActionsController(ref.watch(routesRepositoryProvider));
});

class RouteActionsController {
  const RouteActionsController(this._repository);

  final RoutesRepository _repository;

  Future<RoadRoute> calculate(CalculateRouteInput input) =>
      _repository.calculate(input);
}
