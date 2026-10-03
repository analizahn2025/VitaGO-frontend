import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/locations/repositories/locations_repository.dart';
import 'package:vitago_app/features/locations/repositories/locations_repository_impl.dart';
import 'package:vitago_app/features/locations/services/locations_api_service.dart';

final locationsApiServiceProvider = Provider<LocationsApiService>((ref) {
  return LocationsApiService(ref.watch(apiClientProvider));
});

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepositoryImpl(ref.watch(locationsApiServiceProvider));
});
