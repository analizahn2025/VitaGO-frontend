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
    ref.onDispose(() => _sessionExpiredSubscription?.cancel());

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

    state = const AsyncData(AuthState.unauthenticated(isProcessing: true));
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      state = AsyncData(AuthState.authenticated(session));
    } on AppFailure catch (failure) {
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
