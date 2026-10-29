import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';

final arrivalPresentationStoreProvider = Provider<ArrivalPresentationStore>(
  (ref) => SecureArrivalPresentationStore(ref.watch(secureStoreProvider)),
);

abstract interface class ArrivalPresentationStore {
  Future<bool> wasShown(String scope, String eventId);
  Future<void> markShown(String scope, String eventId);
}

class SecureArrivalPresentationStore implements ArrivalPresentationStore {
  SecureArrivalPresentationStore(this._store);

  final SecureStore _store;

  String _key(String scope) =>
      'arrival_events_v1_${base64Url.encode(utf8.encode(scope))}';

  Future<List<String>> _read(String scope) async {
    final raw = await _store.read(_key(scope));
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Historial de llegadas inválido.');
    }
    return decoded.whereType<String>().toList();
  }

  @override
  Future<bool> wasShown(String scope, String eventId) async =>
      (await _read(scope)).contains(eventId);

  @override
  Future<void> markShown(String scope, String eventId) async {
    final ids = await _read(scope);
    ids.remove(eventId);
    ids.add(eventId);
    await _store.write(
      _key(scope),
      jsonEncode(ids.skip(ids.length > 512 ? ids.length - 512 : 0).toList()),
    );
  }
}
