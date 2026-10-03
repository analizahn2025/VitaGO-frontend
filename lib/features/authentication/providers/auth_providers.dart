import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/network/dio_factory.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/repositories/auth_repository.dart';
import 'package:vitago_app/features/authentication/repositories/auth_repository_impl.dart';
import 'package:vitago_app/features/authentication/services/auth_api_service.dart';
import 'package:vitago_app/features/authentication/services/session_storage.dart';
import 'package:vitago_app/features/authentication/services/token_refresh_coordinator.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      migrateWithBackup: true,
      resetOnError: true,
      storageNamespace: 'vitago_auth_v1',
    ),
  );
});

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(ref.watch(flutterSecureStorageProvider));
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(secureStoreProvider));
});

final publicDioProvider = Provider<Dio>((ref) {
  return DioFactory.create(ref.watch(appConfigProvider));
});

final tokenRefreshCoordinatorProvider = Provider<TokenRefreshCoordinator>((
  ref,
) {
  final coordinator = TokenRefreshCoordinator(
    dio: ref.watch(publicDioProvider),
    storage: ref.watch(sessionStorageProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(sessionStorageProvider);
  final refreshCoordinator = ref.watch(tokenRefreshCoordinatorProvider);

  return ApiClient(
    dio: DioFactory.create(config),
    readAuthorization: () async {
      final session = await storage.read();
      if (session == null) {
        return null;
      }
      return '${session.tokens.tokenType} ${session.tokens.accessToken}';
    },
    refreshAuthorization: () async {
      if (!config.usesLocalAuthentication) {
        return null;
      }
      final session = await refreshCoordinator.refresh();
      if (session == null) {
        return null;
      }
      return '${session.tokens.tokenType} ${session.tokens.accessToken}';
    },
    invalidateAuthorization: () async {
      if (config.usesLocalAuthentication) {
        await refreshCoordinator.invalidate();
      }
    },
  );
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(
    publicDio: ref.watch(publicDioProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiService: ref.watch(authApiServiceProvider),
    storage: ref.watch(sessionStorageProvider),
    refreshCoordinator: ref.watch(tokenRefreshCoordinatorProvider),
  );
});
