import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';

typedef TrackingDirectoryProvider = Future<Directory> Function();

abstract interface class TrackingQueueStore {
  Future<TrackingPointInput> enqueue(String shiftId, TrackingPointInput point);

  Future<List<TrackingPointInput>> pendingPoints(String shiftId, int limit);

  Future<void> acknowledge(String shiftId, Iterable<String> clientIds);

  Future<List<GpsSessionManifest>> manifest(String shiftId);

  Future<List<String>> shiftsWithPendingPoints();

  Future<int> pendingCount(String shiftId);

  Future<void> clearShift(String shiftId);
}

class FileTrackingQueueStore implements TrackingQueueStore {
  FileTrackingQueueStore({TrackingDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final TrackingDirectoryProvider _directoryProvider;
  final Uuid _uuid = const Uuid();
  Future<void> _tail = Future<void>.value();

  @override
  Future<TrackingPointInput> enqueue(
    String shiftId,
    TrackingPointInput point,
  ) => _locked(() async {
    final state = await _read();
    final shifts = _shifts(state);
    final shift = _shift(shifts, shiftId);
    final session = (shift['sesion_activa'] as String?) ?? _uuid.v4();
    final nextSequence = (shift['proxima_secuencia'] as num?)?.toInt() ?? 1;
    final queued = TrackingPointInput(
      clientId: point.clientId,
      latitude: point.latitude,
      longitude: point.longitude,
      accuracyMeters: point.accuracyMeters,
      speedMetersPerSecond: point.speedMetersPerSecond,
      headingDegrees: point.headingDegrees,
      recordedAt: point.recordedAt,
      gpsSession: session,
      sequence: nextSequence,
    );
    final points = _points(shift);
    points.add(queued.toJson());
    shift['sesion_activa'] = session;
    shift['proxima_secuencia'] = nextSequence + 1;
    final sessions = _sessions(shift);
    sessions[session] = nextSequence;
    await _write(state);
    return queued;
  });

  @override
  Future<List<TrackingPointInput>> pendingPoints(String shiftId, int limit) =>
      _locked(() async {
        final state = await _read();
        final shift = _existingShift(state, shiftId);
        if (shift == null) return const [];
        return _points(shift)
            .take(limit)
            .map((item) => TrackingPointInput.fromJson(_jsonMap(item)))
            .toList(growable: false);
      });

  @override
  Future<void> acknowledge(String shiftId, Iterable<String> clientIds) =>
      _locked(() async {
        final state = await _read();
        final shift = _existingShift(state, shiftId);
        if (shift == null) return;
        final accepted = clientIds.toSet();
        _points(shift).removeWhere((item) {
          final map = _jsonMap(item);
          return accepted.contains(map['id_cliente']);
        });
        await _write(state);
      });

  @override
  Future<List<GpsSessionManifest>> manifest(String shiftId) =>
      _locked(() async {
        final state = await _read();
        final shift = _existingShift(state, shiftId);
        if (shift == null) return const [];
        final sessions = _sessions(shift);
        return sessions.entries
            .map(
              (entry) => GpsSessionManifest(
                gpsSession: entry.key,
                lastSequence: (entry.value as num).toInt(),
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<List<String>> shiftsWithPendingPoints() => _locked(() async {
    final state = await _read();
    return _shifts(state).entries
        .where((entry) => _points(_jsonMap(entry.value)).isNotEmpty)
        .map((entry) => entry.key)
        .toList(growable: false);
  });

  @override
  Future<int> pendingCount(String shiftId) => _locked(() async {
    final state = await _read();
    final shift = _existingShift(state, shiftId);
    return shift == null ? 0 : _points(shift).length;
  });

  @override
  Future<void> clearShift(String shiftId) => _locked(() async {
    final state = await _read();
    _shifts(state).remove(shiftId);
    await _write(state);
  });

  Future<T> _locked<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> _read() async {
    final file = await _file();
    if (!await file.exists()) return _emptyState();
    try {
      final decoded = jsonDecode(await file.readAsString());
      return _jsonMap(decoded);
    } on Object {
      final damaged = File('${file.path}.damaged');
      if (await damaged.exists()) await damaged.delete();
      await file.rename(damaged.path);
      return _emptyState();
    }
  }

  Future<void> _write(Map<String, dynamic> state) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(state), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<File> _file() async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}gps_queue_v1.json');
  }
}

Map<String, dynamic> _emptyState() => {
  'version': 1,
  'jornadas': <String, dynamic>{},
};

Map<String, dynamic> _shifts(Map<String, dynamic> state) {
  return state.putIfAbsent('jornadas', () => <String, dynamic>{})
      as Map<String, dynamic>;
}

Map<String, dynamic> _shift(Map<String, dynamic> shifts, String shiftId) {
  return shifts.putIfAbsent(
    shiftId,
    () => <String, dynamic>{
      'puntos': <dynamic>[],
      'sesiones': <String, dynamic>{},
    },
  ) as Map<String, dynamic>;
}

Map<String, dynamic>? _existingShift(
  Map<String, dynamic> state,
  String shiftId,
) {
  final value = _shifts(state)[shiftId];
  return value == null ? null : _jsonMap(value);
}

List<dynamic> _points(Map<String, dynamic> shift) {
  return shift.putIfAbsent('puntos', () => <dynamic>[]) as List<dynamic>;
}

Map<String, dynamic> _sessions(Map<String, dynamic> shift) {
  return shift.putIfAbsent('sesiones', () => <String, dynamic>{})
      as Map<String, dynamic>;
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const FormatException('La cola GPS local está dañada.');
}
