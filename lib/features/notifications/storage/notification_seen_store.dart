import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/notifications/models/notification_seen_state.dart';

final notificationSeenStoreProvider = Provider<NotificationSeenStore>(
  (ref) => SecureNotificationSeenStore(ref.watch(secureStoreProvider)),
);

abstract interface class NotificationSeenStore {
  Future<NotificationSeenState> load(String ownerKey);
  Future<void> save(String ownerKey, NotificationSeenState value);
}

class SecureNotificationSeenStore implements NotificationSeenStore {
  SecureNotificationSeenStore(this._store);
  final SecureStore _store;
  String _key(String ownerKey) =>
      'notification_seen_v1_${base64Url.encode(utf8.encode(ownerKey))}';

  @override
  Future<NotificationSeenState> load(String ownerKey) async {
    final raw = await _store.read(_key(ownerKey));
    if (raw == null) return const NotificationSeenState();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Estado de avisos inválido.');
    }
    return NotificationSeenState.fromJson(decoded);
  }

  @override
  Future<void> save(String ownerKey, NotificationSeenState value) =>
      _store.write(_key(ownerKey), jsonEncode(value.toJson()));
}
