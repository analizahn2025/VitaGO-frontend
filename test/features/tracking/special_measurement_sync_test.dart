import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/services/special_measurement_sync.dart';

void main() {
  test(
    'conserva UUID/secuencia tras fallo y reinicio sin reenviar fotos',
    () async {
      final store = _MemoryStore();
      final requests = _Requests()..fail = true;
      final first = SpecialMeasurementSync(store, requests, 'corporate');
      await first.enqueue(
        driverId: 'driver',
        requestId: 'request',
        movementId: 'movement',
        sessions: const [
          GpsSessionManifest(gpsSession: 'gps-uuid', lastSequence: 8),
        ],
      );
      final saved = store.data.values.single;
      await first.flush('driver');
      expect(store.data.values.single, saved);
      requests.fail = false;
      final restored = SpecialMeasurementSync(store, requests, 'corporate');
      await restored.flush('driver');
      expect(requests.manifests.last.toJson(), {
        'movimiento_id': 'movement',
        'sesiones_gps': [
          {'sesion_gps': 'gps-uuid', 'ultima_secuencia': 8},
        ],
      });
      expect(store.data.values.single, '{}');
    },
  );
  test('no confirma un movimiento todavía activo', () async {
    final store = _MemoryStore();
    final requests = _Requests()..status = 'AT_DESTINATION';
    final sync = SpecialMeasurementSync(store, requests, 'corporate');
    await sync.enqueue(
      driverId: 'driver',
      requestId: 'request',
      movementId: 'movement',
      sessions: const [],
    );
    await sync.flush('driver');
    expect(requests.manifests, isEmpty);
    expect(store.data.values.single, contains('movement'));
  });
  test('aísla confirmaciones por motorista y servidor', () async {
    final store = _MemoryStore();
    final requests = _Requests();
    final corporate = SpecialMeasurementSync(store, requests, 'corporate');
    await corporate.enqueue(
      driverId: 'driver',
      requestId: 'request',
      movementId: 'movement',
      sessions: const [],
    );
    await SpecialMeasurementSync(store, requests, 'network').flush('driver');
    await corporate.flush('other-driver');
    expect(requests.manifests, isEmpty);
    expect(store.data.values.single, contains('movement'));
  });
}

class _MemoryStore implements SecureStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

class _Requests implements RequestsRepository {
  bool fail = false;
  String status = 'DELIVERED';
  final manifests = <GpsSynchronizationInput>[];
  @override
  Future<ServiceRequestDetail> getRequest(String id) async =>
      ServiceRequestDetail(
        summary: ServiceRequestSummary(
          id: id,
          number: 'SOL',
          companyId: 'company',
          requestedById: 'user',
          assignedDriverId: 'driver',
          priority: 'NORMAL',
          modality: 'ESPECIAL',
          serviceType: const RequestServiceType(
            id: 'type',
            code: 'PAQUETE',
            name: 'Paquete',
          ),
          origin: const RequestPoint(
            id: 'origin',
            name: 'Origen',
            address: 'Dirección de prueba',
          ),
          routePresentation: 'SOLO_KILOMETROS',
          status: status,
          createdAt: DateTime.utc(2026, 10, 26),
        ),
        items: const [],
        events: const [],
        assignments: const [],
        updatedAt: DateTime.utc(2026, 10, 26),
        specialMovement: SpecialRequestMovement(
          id: 'movement',
          driverId: 'driver',
          shiftId: 'shift',
          status: status == 'DELIVERED' ? 'FINALIZADO' : 'ACTIVO',
          startedAt: DateTime.utc(2026, 10, 26),
          recordsConsidered: 0,
          recordsDiscarded: 0,
        ),
      );
  @override
  Future<SpecialRequestMovement> confirmGpsSynchronization(
    String id,
    GpsSynchronizationInput input,
  ) async {
    manifests.add(input);
    if (fail) throw const AppFailure(message: 'Sin conexión');
    return (await getRequest(id)).specialMovement!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
