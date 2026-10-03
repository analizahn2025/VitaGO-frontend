import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository_impl.dart';
import 'package:vitago_app/features/requests/services/requests_api_service.dart';

final requestsApiServiceProvider = Provider<RequestsApiService>((ref) {
  return RequestsApiService(ref.watch(apiClientProvider));
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepositoryImpl(ref.watch(requestsApiServiceProvider));
});
