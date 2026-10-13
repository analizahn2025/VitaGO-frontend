import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
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

final requestStageActionsControllerProvider =
    Provider<RequestStageActionsController>((ref) {
      return RequestStageActionsController(
        ref.watch(evidenceRepositoryProvider),
        ref.watch(requestsRepositoryProvider),
        ref.watch(trackingQueueCoordinatorProvider),
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
  }) : _configurationReader =
           configurationReader ?? _defaultTrackingConfiguration;

  final EvidenceRepository _evidenceRepository;
  final RequestsRepository _requestsRepository;
  final TrackingQueueCoordinator _trackingCoordinator;
  final Future<TrackingConfiguration> Function() _configurationReader;

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

    final evidence = await _evidenceRepository.uploadRequestEvidence(
      request.id,
      input,
    );
    if (evidence.type?.toUpperCase() != requiredType) {
      throw AppFailure(
        message:
            'El servidor no confirmó la evidencia $requiredType. No se cambió el estado.',
      );
    }
    return evidence;
  }

  Future<ServiceRequestDetail> completeTransition({
    required ServiceRequestDetail request,
    required String targetStatus,
    required DeviceLocation location,
  }) async {
    final allowed = requestTransitionMatrix[request.status] ?? const <String>[];
    if (!allowed.contains(targetStatus)) {
      throw AppFailure(
        message:
            'No se puede pasar de ${request.status} a $targetStatus. Actualiza la solicitud.',
      );
    }

    if (request.isSpecial &&
        const {'DELIVERED', 'DELIVERY_FAILED'}.contains(targetStatus)) {
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
      );
      return updated;
    }

    return _transition(
      request: request,
      targetStatus: targetStatus,
      location: location,
    );
  }

  Future<ServiceRequestDetail> _transition({
    required ServiceRequestDetail request,
    required String targetStatus,
    required DeviceLocation location,
    List<GpsSessionManifest>? gpsSessions,
  }) async {
    final updated = await _requestsRepository.transitionRequest(
      request.id,
      RequestTransitionInput(
        targetStatus: targetStatus,
        latitude: location.latitudeText,
        longitude: location.longitudeText,
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
