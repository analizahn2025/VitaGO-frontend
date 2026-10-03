import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/incidents/repositories/incidents_repository.dart';
import 'package:vitago_app/features/incidents/repositories/incidents_repository_impl.dart';
import 'package:vitago_app/features/incidents/services/incidents_api_service.dart';

final incidentsApiServiceProvider = Provider<IncidentsApiService>((ref) {
  return IncidentsApiService(ref.watch(apiClientProvider));
});

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepositoryImpl(ref.watch(incidentsApiServiceProvider));
});
