import 'package:vitago_app/features/routes/models/driver_route.dart';

abstract interface class RoutesRepository {
  Future<DriverRoute> getMyRoute();

  Future<RoadRoute> calculate(CalculateRouteInput input);
}
