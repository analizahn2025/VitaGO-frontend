import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class SecureStoreException implements Exception {
  const SecureStoreException({required this.operation, required this.code});

  final String operation;
  final String code;

  @override
  String toString() => 'SecureStoreException($operation, $code)';
}

class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      throw SecureStoreException(operation: 'read', code: error.code);
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      throw SecureStoreException(operation: 'write', code: error.code);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (error) {
      throw SecureStoreException(operation: 'delete', code: error.code);
    }
  }
}
