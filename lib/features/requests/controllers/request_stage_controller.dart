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
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';

final requestStageActionsControllerProvider =
    Provider<RequestStageActionsController>((ref) {
      return RequestStageActionsController(
        ref.watch(evidenceRepositoryProvider),
        ref.watch(requestsRepositoryProvider),
        ref.watch(trackingRepositoryProvider),
      );
    });

class RequestStageActionsController {
  const RequestStageActionsController(
    this._evidenceRepository,
    this._requestsRepository,
    this._trackingRepository,
  );

  final EvidenceRepository _evidenceRepository;
  final RequestsRepository _requestsRepository;
  final TrackingRepository _trackingRepository;

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
    required String trackingClientId,
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
      await _sendFinalTrackingPoint(
        request: request,
        location: location,
        trackingClientId: trackingClientId,
      );
    }

    final updated = await _requestsRepository.transitionRequest(
      request.id,
      RequestTransitionInput(
        targetStatus: targetStatus,
        latitude: location.latitudeText,
        longitude: location.longitudeText,
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

  Future<void> _sendFinalTrackingPoint({
    required ServiceRequestDetail request,
    required DeviceLocation location,
    required String trackingClientId,
  }) async {
    final movement = request.specialMovement;
    if (movement == null) {
      throw const AppFailure(
        message: 'No se encontró el recorrido especial activo. Actualiza la solicitud e inténtalo de nuevo.',
      );
    }

    await _trackingRepository.registerPoints(
      TrackingBatchInput(
        shiftId: movement.shiftId,
        points: [
          TrackingPointInput(
            clientId: trackingClientId,
            latitude: location.latitudeText,
            longitude: location.longitudeText,
            accuracyMeters: location.accuracyMeters?.toStringAsFixed(2),
            speedMetersPerSecond: location.speedMetersPerSecond
                ?.toStringAsFixed(2),
            headingDegrees: location.headingDegrees?.toStringAsFixed(2),
            recordedAt: location.recordedAt,
          ),
        ],
      ),
    );
  }
}

String? requestRequiredEvidenceType(String targetStatus) =>
    switch (targetStatus.toUpperCase()) {
      'PICKED_UP' => 'FOTO_RECOLECCION',
      'DELIVERED' => 'FOTO_ENTREGA',
      _ => null,
    };
