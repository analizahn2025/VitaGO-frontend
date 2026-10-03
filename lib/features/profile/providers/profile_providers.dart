import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/profile/repositories/profile_repository.dart';
import 'package:vitago_app/features/profile/repositories/profile_repository_impl.dart';
import 'package:vitago_app/features/profile/services/profile_api_service.dart';

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileApiServiceProvider));
});
