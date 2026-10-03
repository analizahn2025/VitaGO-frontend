import 'package:vitago_app/features/authentication/models/auth_session.dart';

abstract interface class AuthRepository {
  Stream<void> get sessionExpired;

  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({required String email, required String password});

  Future<void> logout();

  Future<void> logoutAll();
}
