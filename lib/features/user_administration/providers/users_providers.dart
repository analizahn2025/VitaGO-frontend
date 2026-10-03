import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/user_administration/repositories/users_repository.dart';
import 'package:vitago_app/features/user_administration/repositories/users_repository_impl.dart';
import 'package:vitago_app/features/user_administration/services/users_api_service.dart';

final usersApiServiceProvider = Provider<UsersApiService>((ref) {
  return UsersApiService(ref.watch(apiClientProvider));
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl(ref.watch(usersApiServiceProvider));
});
