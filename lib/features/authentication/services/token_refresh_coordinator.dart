import 'dart:async';

import 'package:dio/dio.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/models/token_bundle.dart';
import 'package:vitago_app/features/authentication/services/session_storage.dart';

class TokenRefreshCoordinator {
  factory TokenRefreshCoordinator({
    required Dio dio,
    required SessionStorage storage,
  }) {
    return TokenRefreshCoordinator._(dio, storage);
  }

  TokenRefreshCoordinator._(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  Future<AuthSession?>? _pendingRefresh;

  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  Future<void> invalidate() => _expireSession();

  Future<AuthSession?> refresh() {
    final pending = _pendingRefresh;
    if (pending != null) {
      return pending;
    }

    final operation = _refreshAndRelease();
    _pendingRefresh = operation;
    return operation;
  }

  Future<AuthSession?> _refreshAndRelease() async {
    try {
      return await _performRefresh();
    } finally {
      _pendingRefresh = null;
    }
  }

  Future<AuthSession?> _performRefresh() async {
    final currentSession = await _storage.read();
    if (currentSession == null ||
        !currentSession.tokens.isRefreshTokenValid(DateTime.now())) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'autenticacion/renovar/',
        data: {'token_refresco': currentSession.tokens.refreshToken},
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Respuesta de renovación vacía.');
      }

      final refreshedSession = currentSession.withTokens(
        TokenBundle.fromJson(data),
      );
      await _storage.save(refreshedSession);
      return refreshedSession;
    } on DioException catch (error) {
      await _expireSession();
      throw AppFailure.fromDio(error);
    } on FormatException {
      await _expireSession();
      throw const AppFailure(
        message: 'La respuesta de renovación no tiene el formato esperado.',
      );
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  Future<void> dispose() => _sessionExpiredController.close();
}
