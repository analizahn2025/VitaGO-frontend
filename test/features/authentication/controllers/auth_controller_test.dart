import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/authentication/repositories/auth_repository.dart';

void main() {
  test('bloquea nuevos envíos durante la espera informada por el 429', () async {
    final repository = _RateLimitedAuthRepository();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            mode: AppMode.corporate,
            apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
          ),
        ),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);

    await controller.login(
      email: 'usuario@empresa.com',
      password: 'incorrecta',
    );

    final blockedState = container.read(authControllerProvider).value;
    expect(blockedState?.isLoginRateLimited, isTrue);
    expect(blockedState?.loginRetryAfterSeconds, 125);
    expect(repository.loginCalls, 1);

    await controller.login(
      email: 'usuario@empresa.com',
      password: 'otro-intento',
    );

    expect(repository.loginCalls, 1);
  });
}

class _RateLimitedAuthRepository implements AuthRepository {
  int loginCalls = 0;

  @override
  Stream<void> get sessionExpired => const Stream.empty();

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    throw const AppFailure(
      message: 'Se alcanzó el límite de intentos de inicio de sesión.',
      statusCode: 429,
      retryAfterSeconds: 125,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}
}
