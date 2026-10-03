import 'dart:convert';

import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';

class SessionStorage {
  SessionStorage(this._secureStore);

  static const _sessionKey = 'vitago_auth_session_v1';

  final SecureStore _secureStore;

  Future<AuthSession?> read() async {
    final encoded = await _secureStore.read(_sessionKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Formato de sesión inválido.');
      }
      return AuthSession.fromJson(decoded);
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(AuthSession session) {
    return _secureStore.write(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() => _secureStore.delete(_sessionKey);
}
