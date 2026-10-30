import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/authentication/models/auth_state.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  StreamSubscription<void>? _sessionExpiredSubscription;
  Timer? _loginRetryTimer;
  Stopwatch? _loginRetryStopwatch;
  int? _loginRetryTotalSeconds;
  String? _loginRateLimitMessage;

  @override
  Future<AuthState> build() async {
    final config = ref.watch(appConfigProvider);
    if (!config.usesLocalAuthentication) {
      return const AuthState.corporateAuthenticationRequired();
    }

    final repository = ref.watch(authRepositoryProvider);
    _sessionExpiredSubscription = repository.sessionExpired.listen((_) {
      state = const AsyncData(AuthState.unauthenticated());
    });
    ref.onDispose(() {
      _sessionExpiredSubscription?.cancel();
      _loginRetryTimer?.cancel();
    });

    final session = await repository.restoreSession();
    if (session == null) {
      return const AuthState.unauthenticated();
    }
    return AuthState.authenticated(session);
  }

  Future<void> login({required String email, required String password}) async {
    if (!ref.read(appConfigProvider).usesLocalAuthentication) {
      state = const AsyncData(AuthState.corporateAuthenticationRequired());
      return;
    }

    final retryAfterSeconds = _remainingLoginRetrySeconds;
    if (retryAfterSeconds > 0) {
      state = AsyncData(
        AuthState.unauthenticated(
          message: _loginRateLimitMessage,
          loginRetryAfterSeconds: retryAfterSeconds,
        ),
      );
      return;
    }

    state = const AsyncData(AuthState.unauthenticated(isProcessing: true));
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      _clearLoginRetryCountdown();
      state = AsyncData(AuthState.authenticated(session));
    } on AppFailure catch (failure) {
      final seconds =
          failure.retryAfterSeconds ??
          (failure.isOperationalRecoveryPending ? 5 : null);
      if ((failure.isRateLimited || failure.isOperationalRecoveryPending) &&
          seconds != null &&
          seconds > 0) {
        _startLoginRetryCountdown(seconds: seconds, message: failure.message);
        return;
      }
      state = AsyncData(
        AuthState.unauthenticated(
          message: failure.message,
          fieldErrors: failure.fieldErrors,
        ),
      );
    } on Object {
      state = const AsyncData(
        AuthState.unauthenticated(message: 'No fue posible iniciar sesión.'),
      );
    }
  }

  int get _remainingLoginRetrySeconds {
    final stopwatch = _loginRetryStopwatch;
    final totalSeconds = _loginRetryTotalSeconds;
    if (stopwatch == null || totalSeconds == null) {
      return 0;
    }

    final remainingMilliseconds =
        (totalSeconds * Duration.millisecondsPerSecond) -
        stopwatch.elapsedMilliseconds;
    if (remainingMilliseconds <= 0) {
      return 0;
    }
    return (remainingMilliseconds + Duration.millisecondsPerSecond - 1) ~/
        Duration.millisecondsPerSecond;
  }

  void _startLoginRetryCountdown({
    required int seconds,
    required String message,
  }) {
    _loginRetryTimer?.cancel();
    _loginRetryTotalSeconds = seconds;
    _loginRateLimitMessage = message;
    _loginRetryStopwatch = Stopwatch()..start();
    _emitLoginRetryState();
    _loginRetryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _emitLoginRetryState(),
    );
  }

  void _emitLoginRetryState() {
    final remainingSeconds = _remainingLoginRetrySeconds;
    if (remainingSeconds <= 0) {
      _clearLoginRetryCountdown();
      state = const AsyncData(AuthState.unauthenticated());
      return;
    }

    state = AsyncData(
      AuthState.unauthenticated(
        message: _loginRateLimitMessage,
        loginRetryAfterSeconds: remainingSeconds,
      ),
    );
  }

  void _clearLoginRetryCountdown() {
    _loginRetryTimer?.cancel();
    _loginRetryTimer = null;
    _loginRetryStopwatch?.stop();
    _loginRetryStopwatch = null;
    _loginRetryTotalSeconds = null;
    _loginRateLimitMessage = null;
  }

  Future<void> logout() => _closeSession(closeAll: false);

  Future<void> logoutAll() => _closeSession(closeAll: true);

  Future<void> _closeSession({required bool closeAll}) async {
    final currentSession = state.value?.session;
    if (currentSession == null) {
      state = AsyncData(_signedOutState());
      return;
    }

    state = AsyncData(
      AuthState.authenticated(currentSession, isProcessing: true),
    );
    try {
      final repository = ref.read(authRepositoryProvider);
      if (closeAll) {
        await repository.logoutAll();
      } else {
        await repository.logout();
      }
      state = AsyncData(_signedOutState());
    } on AppFailure catch (failure) {
      if (failure.isUnauthorized) {
        state = AsyncData(_signedOutState());
        return;
      }
      state = AsyncData(
        AuthState.authenticated(currentSession, message: failure.message),
      );
    } on Object {
      state = AsyncData(
        AuthState.authenticated(
          currentSession,
          message: 'No fue posible cerrar la sesión.',
        ),
      );
    }
  }

  AuthState _signedOutState() {
    final config = ref.read(appConfigProvider);
    return config.usesLocalAuthentication
        ? const AuthState.unauthenticated()
        : const AuthState.corporateAuthenticationRequired();
  }
}
