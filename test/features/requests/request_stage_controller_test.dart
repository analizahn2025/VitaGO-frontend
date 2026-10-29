import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';
import 'package:vitago_app/features/requests/controllers/request_stage_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

void main() {
  final location = DeviceLocation(
    latitude: 14.0723,
    longitude: -87.1921,
    recordedAt: _recordedAt,
  );
  final pickupInput = EvidenceUploadInput(
    temperatureC: '4.50',
    filePath: 'foto.jpg',
    fileName: 'foto.jpg',
    latitude: '14.072300',
    longitude: '-87.192100',
    type: 'FOTO_RECOLECCION',
  );

  test(
    'relaciona cada foto con la etapa operativa, no con un POST de transición',
    () {
      expect(requestRequiredEvidenceType('PICKED_UP'), 'FOTO_RECOLECCION');
      expect(requestRequiredEvidenceType('DELIVERED'), 'FOTO_ENTREGA');
      expect(requestRequiredEvidenceType('IN_TRANSIT'), isNull);
      expect(requestPhotoStageCompleted('PICKED_UP', 'PICKED_UP'), isTrue);
      expect(requestPhotoStageCompleted('IN_TRANSIT', 'PICKED_UP'), isTrue);
      expect(requestPhotoStageCompleted('DELIVERED', 'DELIVERED'), isTrue);
      expect(requestPhotoStageCompleted('CANCELLED', 'PICKED_UP'), isFalse);
    },
  );

  test('bloquea inicios y confirmaciones normales del cliente', () async {
    final repository = _RequestsRepository();
    final controller = RequestStageActionsController(
      _EvidenceRepository(response: _evidence('FOTO_RECOLECCION')),
      repository,
      _trackingCoordinator(),
    );
    for (final (status, target) in [
      ('ASSIGNED', 'GOING_TO_PICKUP'),
      ('GOING_TO_PICKUP', 'AT_PICKUP'),
      ('AT_PICKUP', 'PICKED_UP'),
      ('PICKED_UP', 'IN_TRANSIT'),
      ('IN_TRANSIT', 'AT_DESTINATION'),
      ('AT_DESTINATION', 'DELIVERED'),
    ]) {
      await expectLater(
        controller.completeTransition(
          request: _request(status),
          targetStatus: target,
          location: location,
        ),
        throwsA(isA<AppFailure>()),
      );
    }
    expect(repository.transitionCalls, 0);
  });

  for (final status in ['PICKED_UP', 'IN_TRANSIT']) {
    test(
      'foto de recolección reconoce $status sin transición adicional',
      () async {
        final evidence = _EvidenceRepository(
          response: _evidence('FOTO_RECOLECCION', status: status),
        );
        final repository = _RequestsRepository();
        final controller = RequestStageActionsController(
          evidence,
          repository,
          _trackingCoordinator(),
        );
        final result = await controller.uploadRequiredEvidence(
          request: _request('AT_PICKUP'),
          targetStatus: 'PICKED_UP',
          input: pickupInput,
        );
        expect(result.requestStatus, status);
        expect(evidence.uploadCalls, 1);
        expect(repository.transitionCalls, 0);
      },
    );
  }

  test('FOTO_INCIDENCIA nunca confirma una etapa', () async {
    final evidence = _EvidenceRepository(
      response: _evidence('FOTO_INCIDENCIA'),
    );
    final controller = RequestStageActionsController(
      evidence,
      _RequestsRepository(),
      _trackingCoordinator(),
    );
    await expectLater(
      controller.uploadRequiredEvidence(
        request: _request('AT_PICKUP'),
        targetStatus: 'PICKED_UP',
        input: EvidenceUploadInput(
          filePath: 'foto.jpg',
          fileName: 'foto.jpg',
          latitude: '14',
          longitude: '-87',
          type: 'FOTO_INCIDENCIA',
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(evidence.uploadCalls, 0);
  });

  test(
    'no presenta como confirmada una respuesta de foto sin estado actualizado',
    () async {
      final evidence = _EvidenceRepository(
        response: OperationalEvidence.fromJson({
          'id': 'photo',
          'solicitud_id': 'request-id',
          'tipo': 'FOTO_RECOLECCION',
          'tipo_contenido': 'image/jpeg',
          'tamano_bytes': 3,
          'latitud': '14',
          'longitud': '-87',
          'capturada_en': _recordedAt.toIso8601String(),
          'creado_en': _recordedAt.toIso8601String(),
          'archivo_disponible': true,
          'estado_solicitud': 'AT_PICKUP',
        }),
      );
      final repository = _RequestsRepository();
      final controller = RequestStageActionsController(
        evidence,
        repository,
        _trackingCoordinator(),
      );
      await expectLater(
        controller.uploadRequiredEvidence(
          request: _request('AT_PICKUP'),
          targetStatus: 'PICKED_UP',
          input: pickupInput,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(repository.transitionCalls, 0);
    },
  );

  for (final status in ['PICKED_UP', 'IN_TRANSIT']) {
    test(
      'recupera foto ya aplicada en $status con lecturas, sin reenviar',
      () async {
        final evidence = _EvidenceRepository(
          response: _evidence('FOTO_RECOLECCION'),
        );
        final repository = _RequestsRepository(response: _request(status));
        final controller = RequestStageActionsController(
          evidence,
          repository,
          _trackingCoordinator(),
        );
        final result = await controller.recoverEvidenceStage(
          request: _request('AT_PICKUP'),
          targetStatus: 'PICKED_UP',
        );
        expect(result.status, status);
        expect(evidence.uploadCalls, 0);
        expect(evidence.readCalls, 1);
        expect(repository.transitionCalls, 0);
      },
    );
  }

  test(
    'finalizar especial envía GPS/manifiesto y conserva el lote offline',
    () async {
      final repository = _RequestsRepository();
      final store = _RecordingTrackingQueueStore();
      final controller = RequestStageActionsController(
        _EvidenceRepository(response: _evidence('FOTO_ENTREGA')),
        repository,
        TrackingQueueCoordinator(
          store,
          _FailingTrackingRepository(),
          _serverTimeClock(),
        ),
      );
      final result = await controller.completeTransition(
        request: _request('IN_TRANSIT', special: true),
        targetStatus: 'AT_DESTINATION',
        location: location,
      );
      expect(result.status, 'AT_DESTINATION');
      expect(repository.lastInput!.gpsSessions!.single.lastSequence, 1);
      expect(await store.pendingCount('shift-id'), 1);
    },
  );

  test('solo admite la transición excepcional cuando devuelve el estado solicitado', () async {
    final repository = _RequestsRepository(response: _request('AT_PICKUP'));
    final controller = RequestStageActionsController(
      _EvidenceRepository(response: _evidence('FOTO_RECOLECCION')),
      repository,
      _trackingCoordinator(),
    );
    await expectLater(
      controller.completeTransition(
        request: _request('AT_PICKUP'),
        targetStatus: 'PICKUP_FAILED',
        location: location,
        reason: 'No se pudo recolectar.',
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(repository.transitionCalls, 1);
  });
}

final _recordedAt = DateTime.utc(2026, 9, 30, 15);

ServiceRequestDetail _request(String status, {bool special = false}) {
  return ServiceRequestDetail(
    summary: ServiceRequestSummary(
      id: 'request-id',
      number: 'SOL-20260930-5F4FA466',
      companyId: 'company-id',
      requestedById: 'requester-id',
      assignedDriverId: 'driver-id',
      priority: 'NORMAL',
      modality: special
          ? RequestModalities.special
          : RequestModalities.betweenBranches,
      serviceType: const RequestServiceType(
        id: 'service-id',
        code: 'MEDICAMENTOS',
        name: 'Medicamentos',
      ),
      origin: const RequestPoint(
        id: 'origin-id',
        name: 'Origen',
        address: 'Tegucigalpa',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Destino',
        address: 'Comayagüela',
      ),
      routePresentation: 'MAPA',
      status: status,
      createdAt: _recordedAt,
    ),
    items: const [],
    events: const [],
    assignments: const [],
    specialMovement: special
        ? SpecialRequestMovement(
            id: 'movement-id',
            driverId: 'driver-id',
            shiftId: 'shift-id',
            status: 'ACTIVO',
            startedAt: _recordedAt,
            recordsConsidered: 0,
            recordsDiscarded: 0,
          )
        : null,
    updatedAt: _recordedAt,
  );
}

OperationalEvidence _evidence(String type, {String? status}) {
  return OperationalEvidence(
    id: 'evidence-id',
    requestId: 'request-id',
    type: type,
    requestStatus:
        status ?? (type == 'FOTO_RECOLECCION' ? 'IN_TRANSIT' : 'DELIVERED'),
    contentType: 'image/jpeg',
    sizeBytes: 1024,
    latitude: '14.072300',
    longitude: '-87.192100',
    capturedAt: _recordedAt,
    fileAvailable: true,
    createdAt: _recordedAt,
  );
}

class _EvidenceRepository implements EvidenceRepository {
  _EvidenceRepository({required this.response});

  final OperationalEvidence response;
  int uploadCalls = 0;
  int readCalls = 0;
  String? lastRequestId;
  EvidenceUploadInput? lastInput;
  @override
  Future<PaginatedResult<OperationalEvidence>> getRequestEvidence({
    required String requestId,
    required int page,
  }) async {
    readCalls++;
    return const PaginatedResult(
      count: 0,
      items: [],
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<OperationalEvidence> uploadRequestEvidence(
    String requestId,
    EvidenceUploadInput input,
  ) async {
    uploadCalls += 1;
    lastRequestId = requestId;
    lastInput = input;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RequestsRepository implements RequestsRepository {
  _RequestsRepository({this.response});

  final ServiceRequestDetail? response;
  int transitionCalls = 0;
  RequestTransitionInput? lastInput;
  @override
  Future<ServiceRequestDetail> getRequest(String id) async =>
      response ?? _request('AT_PICKUP');

  @override
  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  ) async {
    transitionCalls += 1;
    lastInput = input;
    return response ?? _request(input.targetStatus);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingRepository implements TrackingRepository {
  @override
  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input) async {
    return const TrackingBatchResult(
      received: 1,
      created: 1,
      repeated: 0,
      points: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TrackingQueueCoordinator _trackingCoordinator() => TrackingQueueCoordinator(
  _TrackingQueueStore(),
  _TrackingRepository(),
  _serverTimeClock(),
);

ServerTimeClock _serverTimeClock() {
  final clock = ServerTimeClock.withElapsedReader(() => Duration.zero);
  clock.synchronize(
    serverTime: _recordedAt,
    operationalTimeZone: 'America/Tegucigalpa',
  );
  return clock;
}

class _TrackingQueueStore implements TrackingQueueStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingTrackingRepository extends _TrackingRepository {
  @override
  Future<TrackingBatchResult> registerPoints(TrackingBatchInput input) {
    throw const AppFailure(message: 'Sin conexión temporal.');
  }
}

class _RecordingTrackingQueueStore implements TrackingQueueStore {
  final _points = <String, List<TrackingPointInput>>{};

  @override
  Future<TrackingPointInput> enqueue(
    String shiftId,
    TrackingPointInput point,
  ) async {
    final queued = TrackingPointInput(
      clientId: point.clientId,
      latitude: point.latitude,
      longitude: point.longitude,
      recordedAt: point.recordedAt,
      gpsSession: 'session-1',
      sequence: 1,
    );
    _points.putIfAbsent(shiftId, () => []).add(queued);
    return queued;
  }

  @override
  Future<List<TrackingPointInput>> pendingPoints(
    String shiftId,
    int limit,
  ) async {
    return (_points[shiftId] ?? const []).take(limit).toList();
  }

  @override
  Future<void> acknowledge(String shiftId, Iterable<String> clientIds) async {
    _points[shiftId]?.removeWhere(
      (point) => clientIds.contains(point.clientId),
    );
  }

  @override
  Future<List<GpsSessionManifest>> manifest(String shiftId) async => const [
    GpsSessionManifest(gpsSession: 'session-1', lastSequence: 1),
  ];

  @override
  Future<int> pendingCount(String shiftId) async =>
      _points[shiftId]?.length ?? 0;

  @override
  Future<List<String>> shiftsWithPendingPoints() async => _points.keys.toList();

  @override
  Future<void> clearShift(String shiftId) async {
    _points.remove(shiftId);
  }
}
