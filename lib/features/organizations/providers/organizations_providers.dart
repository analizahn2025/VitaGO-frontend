import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/organizations/repositories/organizations_repository.dart';
import 'package:vitago_app/features/organizations/repositories/organizations_repository_impl.dart';
import 'package:vitago_app/features/organizations/services/organizations_api_service.dart';

final organizationsApiServiceProvider = Provider<OrganizationsApiService>((
  ref,
) {
  return OrganizationsApiService(ref.watch(apiClientProvider));
});

final organizationsRepositoryProvider = Provider<OrganizationsRepository>((
  ref,
) {
  return OrganizationsRepositoryImpl(
    ref.watch(organizationsApiServiceProvider),
  );
});
