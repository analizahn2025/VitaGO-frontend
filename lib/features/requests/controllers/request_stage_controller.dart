import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/validation/operational_values.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/evidence/repositories/evidence_repository.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/tracking/services/special_measurement_sync.dart';

final requestStageActionsControllerProvider =
    Provider<RequestStageActionsController>((ref) {
      return RequestStageActionsController(
        ref.watch(evidenceRepositoryProvider),
        ref.watch(requestsRepositoryProvider),
        ref.watch(trackingQueueCoordinatorProvider),
        routeReader: () => ref.read(routesRepositoryProvider).getMyRoute(),
        queueSpecialMeasurement: (request, sessions) => ref
            .read(specialMeasurementSyncProvider)
            .enqueue(
              driverId: request.assignedDriverId!,
              requestId: request.id,
              movementId: request.specialMovement!.id,
              sessions: sessions,
            ),
        flushSpecialMeasurements: (driverId) =>
            ref.read(specialMeasurementSyncProvider).flush(driverId),
        configurationReader: () async {
          try {
            return await ref.read(trackingConfigurationProvider.future);
          } on Object {
            return TrackingConfiguration.defaults;
          }
        },
      );
    });

class RequestStageActionsController {
  RequestStageActionsController(
    this._evidenceRepository,
    this._requestsRepository,
    this._trackingCoordinator, {
    Future<TrackingConfiguration> Function()? configurationReader,
    this.routeReader,
    this.queueSpecialMeasurement,
    this.flushSpecialMeasurements,
  }) : _configurationReader =
           configurationReader ?? _defaultTrackingConfiguration;

  final EvidenceRepository _evidenceRepository;
  final RequestsRepository _requestsRepository;
  final TrackingQueueCoordinator _trackingCoordinator;
  final Future<TrackingConfiguration> Function() _configurationReader;
  final Future<DriverRoute> Function()? routeReader;
  final Future<void> Function(ServiceRequestDetail, List<GpsSessionManifest>)?
  queueSpecialMeasurement;
  final Future<void> Function(String)? flushSpecialMeasurements;

  Future<ServiceRequestDetail> refreshRequest(String id) =>
      _requestsRepository.getRequest(id);

  /// Read-only recovery after any ambiguous upload; never retry the POST here.
  Future<ServiceRequestDetail> recoverEvidenceStage({
    required ServiceRequestDetail request,
    required String targetStatus,
  }) async {
    final current = await _requestsRepository.getRequest(request.id);
    final route = await routeReader?.call();
    final evidence = await _evidenceRepository.getRequestEvidence(
      requestId: request.id,
      page: 1,
    );
    if (requestPhotoStageCompleted(current.status, targetStatus)) {
      return current;
    }
    final flow = route?.flow;
    if (flow?.isAutomatic != true ||
        flow?.requestId != current.id ||
        flow?.photoTargetStatus != targetStatus ||
        current.status != request.status ||
        current.assignedDriverId != request.assignedDriverId ||
        evidence.hasNext ||
        evidence.items.any(
          (item) =>
              item.type == requestRequiredEvidenceType(targetStatus) &&
              item.driverId == request.assignedDriverId,
        )) {
      throw const AppFailure(
        message: 'El servicio cambió o ya tiene una foto registrada. Actualiza la ruta antes de continuar.',
      );
    }
    return current;
  }

  Future<void> prepareSpecialPhoto(
    ServiceRequestDetail request,
    DeviceLocation location,
  ) async {
    final movement = request.specialMovement;
    if (!request.isSpecial || movement == null) return;
    final configuration = await _configurationReader();
    await _trackingCoordinator.capture(movement.shiftId, location);
    try {
      await _trackingCoordinator.flush(
        movement.shiftId,
        maximumBatchSize: configuration.maximumBatchSize,
      );
    } on AppFailure {
      // Preserve the exact offline queue; measurement can remain pending.
    }
    if (queueSpecialMeasurement != null && request.assignedDriverId != null) {
      try {
        await queueSpecialMeasurement!(
          request,
          await _trackingCoordinator.manifest(movement.shiftId),
        );
      } on Object {
        throw const AppFailure(
          message: 'No fue posible guardar la confirmación GPS del encargo. Inténtalo nuevamente antes de enviar la foto.',
        );
      }
    }
  }

  Future<void> confirmSpecialPhotoMeasurement(
    ServiceRequestDetail request,
  ) async {
    final movement = request.specialMovement;
    if (!request.isSpecial || movement == null) return;
    if (flushSpecialMeasurements != null && request.assignedDriverId != null) {
      await flushSpecialMeasurements!(request.assignedDriverId!);
      return;
    }
    final sessions = await _trackingCoordinator.manifest(movement.shiftId);
    if (sessions.isEmpty) return;
    await _requestsRepository.confirmGpsSynchronization(
      request.id,
      GpsSynchronizationInput(sessions, movementId: movement.id),
    );
  }

  Future<OperationalEvidence> uploadRequiredEvidence({
    required ServiceRequestDetail request,
    required String targetStatus,
    required EvidenceUploadInput input,
  }) async {
    final requiredType = requestRequiredEvidenceType(targetStatus);
    final allowed = requestTransitionMatrix[request.status] ?? const <String>[];
    if (requiredType == null || !allowed.contains(targetStatus)) {
      throw const AppFailure(
        message: 'Esta solicitud no admite una confirmación con fotografía.',
      );
    }
    if (input.type?.toUpperCase() != requiredType) {
      throw AppFailure(
        message: 'La evidencia requerida para esta acción es $requiredType.',
      );
    }

    final temperatureError = containerTemperatureError(input.temperatureC);
    if (requiredType == 'FOTO_RECOLECCION' && temperatureError != null) {
      throw AppFailure(
        message: temperatureError,
        fieldErrors: {
          'temperatura_contenedor_c': [temperatureError],
        },
      );
    }
    final evidence = await _evidenceRepository.uploadRequestEvidence(
      request.id,
      input,
    );
    if (evidence.requestId != request.id ||
        evidence.type?.toUpperCase() != requiredType ||
        !requestPhotoStageCompleted(evidence.requestStatus, targetStatus)) {
      throw AppFailure(
        message: 'No fue posible verificar la etapa confirmada por la foto. Consulta el estado antes de reenviar.',
      );
    }
    return evidence;
  }

  Future<ServiceRequestDetail> completeTransition({
    required ServiceRequestDetail request,
    required String targetStatus,
    required DeviceLocation location,
    String? reason,
  }) async {
    if (const {
      'GOING_TO_PICKUP',
      'PICKED_UP',
      'IN_TRANSIT',
      'DELIVERED',
    }.contains(targetStatus)) {
      throw const AppFailure(
        message: 'Esta etapa es automática. Usa la foto indicada en tu servicio actual.',
      );
    }
    if (!requestAllowsManualTransition(request, targetStatus)) {
      throw const AppFailure(
        message: 'La llegada se confirma automáticamente con GPS válido. Mantén la ubicación encendida y la conexión activa.',
      );
    }
    final allowed = requestTransitionMatrix[request.status] ?? const <String>[];
    if (!allowed.contains(targetStatus)) {
      throw AppFailure(
        message:
            'No se puede pasar de ${request.status} a $targetStatus. Actualiza la solicitud.',
      );
    }

    if (request.isSpecial &&
        const {'AT_DESTINATION', 'DELIVERY_FAILED'}.contains(targetStatus)) {
      final movement = request.specialMovement;
      if (movement == null) {
        throw const AppFailure(
          message: 'No se encontró el recorrido especial activo. Actualiza la solicitud e inténtalo de nuevo.',
        );
      }
      final configuration = await _configurationReader();
      await _trackingCoordinator.capture(movement.shiftId, location);
      try {
        await _trackingCoordinator.flush(
          movement.shiftId,
          maximumBatchSize: configuration.maximumBatchSize,
        );
      } on AppFailure {
        // La solicitud puede cerrar con calidad pendiente; el manifiesto
        // permite que Django la consolide cuando llegue la cola local.
      }
      final sessions = await _trackingCoordinator.manifest(movement.shiftId);
      final updated = await _transition(
        request: request,
        targetStatus: targetStatus,
        location: location,
        gpsSessions: sessions,
        reason: reason,
      );
      return updated;
    }

    return _transition(
      request: request,
      targetStatus: targetStatus,
      location: location,
      reason: reason,
    );
  }

  Future<ServiceRequestDetail> _transition({
    required ServiceRequestDetail request,
    required String targetStatus,
    required DeviceLocation location,
    List<GpsSessionManifest>? gpsSessions,
    String? reason,
  }) async {
    final updated = await _requestsRepository.transitionRequest(
      request.id,
      RequestTransitionInput(
        targetStatus: targetStatus,
        latitude: location.latitudeText,
        longitude: location.longitudeText,
        reason: reason,
        gpsSessions: gpsSessions,
      ),
    );
    if (updated.status.toUpperCase() != targetStatus.toUpperCase()) {
      throw AppFailure(
        message:
            'El servidor respondió con estado ${updated.status}; se esperaba $targetStatus.',
      );
    }
    return updated;
  }
}

Future<TrackingConfiguration> _defaultTrackingConfiguration() async =>
    TrackingConfiguration.defaults;

String? requestRequiredEvidenceType(String targetStatus) =>
    switch (targetStatus.toUpperCase()) {
      'PICKED_UP' => 'FOTO_RECOLECCION',
      'DELIVERED' => 'FOTO_ENTREGA',
      _ => null,
    };

bool requestPhotoStageCompleted(String? status, String targetStatus) =>
    targetStatus == 'PICKED_UP'
    ? const {
        'PICKED_UP',
        'IN_TRANSIT',
        'AT_DESTINATION',
        'DELIVERED',
      }.contains(status)
    : targetStatus == 'DELIVERED' && status == 'DELIVERED';
