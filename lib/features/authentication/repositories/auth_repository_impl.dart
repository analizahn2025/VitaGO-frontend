import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/repositories/auth_repository.dart';
import 'package:vitago_app/features/authentication/services/auth_api_service.dart';
import 'package:vitago_app/features/authentication/services/session_storage.dart';
import 'package:vitago_app/features/authentication/services/token_refresh_coordinator.dart';

class AuthRepositoryImpl implements AuthRepository {
  factory AuthRepositoryImpl({
    required AuthApiService apiService,
    required SessionStorage storage,
    required TokenRefreshCoordinator refreshCoordinator,
  }) {
    return AuthRepositoryImpl._(apiService, storage, refreshCoordinator);
  }

  AuthRepositoryImpl._(
    this._apiService,
    this._storage,
    this._refreshCoordinator,
  );

  final AuthApiService _apiService;
  final SessionStorage _storage;
  final TokenRefreshCoordinator _refreshCoordinator;

  @override
  Stream<void> get sessionExpired => _refreshCoordinator.sessionExpired;

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _storage.read();
    if (session == null) {
      return null;
    }

    if (session.tokens.isAccessTokenValid(DateTime.now())) {
      return session;
    }

    try {
      return await _refreshCoordinator.refresh();
    } on AppFailure {
      return null;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _apiService.login(email: email, password: password);
    try {
      await _storage.save(session);
    } on SecureStoreException {
      throw const AppFailure(
        message:
            'El acceso fue validado, pero no fue posible guardar la sesión '
            'de forma segura en este dispositivo.',
      );
    }
    return session;
  }

  @override
  Future<void> logout() async {
    await _apiService.logout();
    await _storage.clear();
  }

  @override
  Future<void> logoutAll() async {
    await _apiService.logoutAll();
    await _storage.clear();
  }
}
