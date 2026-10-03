import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/models/auth_user.dart';
import 'package:vitago_app/features/authentication/models/token_bundle.dart';
import 'package:vitago_app/features/authentication/repositories/auth_repository_impl.dart';
import 'package:vitago_app/features/authentication/services/auth_api_service.dart';
import 'package:vitago_app/features/authentication/services/session_storage.dart';
import 'package:vitago_app/features/authentication/services/token_refresh_coordinator.dart';

void main() {
  test('identifica un fallo al guardar una sesión validada', () async {
    final repository = AuthRepositoryImpl(
      apiService: _SuccessfulAuthApiService(),
      storage: _FailingSessionStorage(),
      refreshCoordinator: _UnusedRefreshCoordinator(),
    );

    await expectLater(
      repository.login(email: 'usuario@empresa.com', password: 'secreto'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          contains('guardar la sesión'),
        ),
      ),
    );
  });
}

AuthSession _session() {
  return AuthSession(
    tokens: TokenBundle(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      accessTokenExpiresAt: DateTime.utc(2026, 9, 22, 20),
      refreshTokenExpiresAt: DateTime.utc(2026, 9, 29, 20),
      sessionId: '0b6be16f-4695-46ec-8d75-dbf2566e49e2',
    ),
    user: const AuthUser(
      id: '40bc6f06-8634-4103-93d9-aeebda6b19e0',
      email: 'usuario@empresa.com',
      firstNames: 'Nombre',
      lastNames: 'Apellido',
    ),
  );
}

class _SuccessfulAuthApiService implements AuthApiService {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _session();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}
}

class _FailingSessionStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) {
    throw const SecureStoreException(operation: 'write', code: 'test_error');
  }
}

class _UnusedRefreshCoordinator implements TokenRefreshCoordinator {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> invalidate() async {}

  @override
  Future<AuthSession?> refresh() async => null;

  @override
  Stream<void> get sessionExpired => const Stream.empty();
}
