import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
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

  test('asocia cada cierre operativo con su evidencia obligatoria', () {
    expect(requestRequiredEvidenceType('PICKED_UP'), 'FOTO_RECOLECCION');
    expect(requestRequiredEvidenceType('DELIVERED'), 'FOTO_ENTREGA');
    expect(requestRequiredEvidenceType('IN_TRANSIT'), isNull);
  });

  test('sube FOTO_RECOLECCION antes de permitir la transición', () async {
    final evidenceRepository = _EvidenceRepository(
      response: _evidence('FOTO_RECOLECCION'),
    );
    final requestsRepository = _RequestsRepository();
    final controller = RequestStageActionsController(
      evidenceRepository,
      requestsRepository,
      _trackingCoordinator(),
    );
    final input = EvidenceUploadInput(
      filePath: 'foto.jpg',
      fileName: 'foto.jpg',
      latitude: '14.072300',
      longitude: '-87.192100',
      capturedAt: _recordedAt,
      type: 'FOTO_RECOLECCION',
    );

    final evidence = await controller.uploadRequiredEvidence(
      request: _request('AT_PICKUP'),
      targetStatus: 'PICKED_UP',
      input: input,
    );

    expect(evidence.type, 'FOTO_RECOLECCION');
    expect(evidenceRepository.lastRequestId, 'request-id');
    expect(evidenceRepository.lastInput, same(input));
    expect(requestsRepository.transitionCalls, 0);
  });

  test('rechaza FOTO_INCIDENCIA como confirmación de recolección', () async {
    final evidenceRepository = _EvidenceRepository(
      response: _evidence('FOTO_INCIDENCIA'),
    );
    final controller = RequestStageActionsController(
      evidenceRepository,
      _RequestsRepository(),
      _trackingCoordinator(),
    );

    await expectLater(
      controller.uploadRequiredEvidence(
        request: _request('AT_PICKUP'),
        targetStatus: 'PICKED_UP',
        input: EvidenceUploadInput(
          filePath: 'incidencia.jpg',
          fileName: 'incidencia.jpg',
          latitude: '14.072300',
          longitude: '-87.192100',
          capturedAt: _recordedAt,
          type: 'FOTO_INCIDENCIA',
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(evidenceRepository.uploadCalls, 0);
  });

  test(
    'solo acepta la transición cuando vuelve el estado solicitado',
    () async {
      final requestsRepository = _RequestsRepository(
        response: _request('PICKED_UP'),
      );
      final controller = RequestStageActionsController(
        _EvidenceRepository(response: _evidence('FOTO_RECOLECCION')),
        requestsRepository,
        _trackingCoordinator(),
      );

      final updated = await controller.completeTransition(
        request: _request('AT_PICKUP'),
        targetStatus: 'PICKED_UP',
        location: location,
      );

      expect(updated.status, 'PICKED_UP');
      expect(requestsRepository.lastInput?.targetStatus, 'PICKED_UP');
      expect(requestsRepository.lastInput?.latitude, '14.072300');
      expect(requestsRepository.lastInput?.longitude, '-87.192100');
    },
  );

  test('no da por terminada una entrega con un estado inesperado', () async {
    final requestsRepository = _RequestsRepository(
      response: _request('AT_DESTINATION'),
    );
    final controller = RequestStageActionsController(
      _EvidenceRepository(response: _evidence('FOTO_ENTREGA')),
      requestsRepository,
      _trackingCoordinator(),
    );

    await expectLater(
      controller.completeTransition(
        request: _request('AT_DESTINATION'),
        targetStatus: 'DELIVERED',
        location: location,
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.message,
          'message',
          contains('AT_DESTINATION'),
        ),
      ),
    );
  });

  test(
    'cierra un especial con manifiesto aunque el lote quede pendiente',
    () async {
      final requestsRepository = _RequestsRepository();
      final store = _RecordingTrackingQueueStore();
      final controller = RequestStageActionsController(
        _EvidenceRepository(response: _evidence('FOTO_ENTREGA')),
        requestsRepository,
        TrackingQueueCoordinator(store, _FailingTrackingRepository()),
      );

      final updated = await controller.completeTransition(
        request: _request('AT_DESTINATION', special: true),
        targetStatus: 'DELIVERED',
        location: location,
      );

      expect(updated.status, 'DELIVERED');
      expect(requestsRepository.lastInput?.gpsSessions, hasLength(1));
      expect(requestsRepository.lastInput?.gpsSessions?.single.lastSequence, 1);
      expect(await store.pendingCount('shift-id'), 1);
    },
  );
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

OperationalEvidence _evidence(String type) {
  return OperationalEvidence(
    id: 'evidence-id',
    requestId: 'request-id',
    type: type,
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
  String? lastRequestId;
  EvidenceUploadInput? lastInput;

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

TrackingQueueCoordinator _trackingCoordinator() =>
    TrackingQueueCoordinator(_TrackingQueueStore(), _TrackingRepository());

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
