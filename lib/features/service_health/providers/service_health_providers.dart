import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/service_health/models/service_health.dart';
import 'package:vitago_app/features/service_health/services/service_health_api_service.dart';

final serviceHealthApiProvider = Provider<ServiceHealthApiService>((ref) {
  return ServiceHealthApiService(ref.watch(publicDioProvider));
});

final serviceHealthControllerProvider =
    FutureProvider.autoDispose<ServiceHealth>((ref) {
      return ref.watch(serviceHealthApiProvider).check();
    });
