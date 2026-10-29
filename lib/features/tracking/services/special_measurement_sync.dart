import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

final specialMeasurementSyncProvider = Provider<SpecialMeasurementSync>(
  (ref) => SpecialMeasurementSync(
    ref.watch(secureStoreProvider),
    ref.watch(requestsRepositoryProvider),
    ref.watch(appConfigProvider).apiBaseUri.toString(),
  ),
);

/// Durable confirmation manifests; never stores/retries an evidence upload.
class SpecialMeasurementSync {
  SpecialMeasurementSync(this._store, this._requests, this._server);
  final SecureStore _store;
  final RequestsRepository _requests;
  final String _server;
  Future<void> _tail = Future.value();

  String _key(String driverId) =>
      'special_gps_v1_${base64Url.encode(utf8.encode('$_server|$driverId'))}';

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Map<String, dynamic>> _read(String driverId) async {
    final raw = await _store.read(_key(driverId));
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> enqueue({
    required String driverId,
    required String requestId,
    required String movementId,
    required List<GpsSessionManifest> sessions,
  }) => _serial(() async {
    final pending = await _read(driverId);
    pending[movementId] = {
      'solicitud_id': requestId,
      'sesiones_gps': sessions.map((entry) => entry.toJson()).toList(),
    };
    await _store.write(_key(driverId), jsonEncode(pending));
  });

  Future<void> flush(String driverId) => _serial(() async {
    try {
      final pending = await _read(driverId);
      for (final entry in pending.entries.toList()) {
        try {
          final data = Map<String, dynamic>.from(entry.value as Map);
          final requestId = data['solicitud_id'] as String;
          final request = await _requests.getRequest(requestId);
          final movement = [
            ...request.specialMovements,
            if (request.specialMovement != null) request.specialMovement!,
          ].where((movement) => movement.id == entry.key).firstOrNull;
          if (!request.isTerminal &&
              (movement == null || movement.status == 'ACTIVO')) {
            continue;
          }
          final sessions = (data['sesiones_gps'] as List)
              .map(
                (value) => GpsSessionManifest.fromJson(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList();
          await _requests.confirmGpsSynchronization(
            requestId,
            GpsSynchronizationInput(sessions, movementId: entry.key),
          );
          pending.remove(entry.key);
          await _store.write(_key(driverId), jsonEncode(pending));
        } on Object {
          // Keep the original UUID/sequences for a later connection/session.
        }
      }
    } on Object {
      // A storage/network failure must not turn a delivered photo into a retry.
    }
  });
}
