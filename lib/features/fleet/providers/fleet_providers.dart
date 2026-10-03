import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/fleet/repositories/fleet_repository.dart';
import 'package:vitago_app/features/fleet/repositories/fleet_repository_impl.dart';
import 'package:vitago_app/features/fleet/services/fleet_api_service.dart';

final fleetApiServiceProvider = Provider<FleetApiService>((ref) {
  return FleetApiService(ref.watch(apiClientProvider));
});

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepositoryImpl(ref.watch(fleetApiServiceProvider));
});
