import 'package:vitago_app/core/models/json_readers.dart';

/// The server selects the active stop and screen (contracts 0.36.0/0.38.0).
class DriverRouteFlow {
  const DriverRouteFlow({
    required this.mode,
    required this.screen,
    this.requiresAcceptance = false,
    this.allowsStageSelection = false,
    this.requestId,
    this.stopType,
    this.status,
    this.segmentId,
    this.requiredEvidence,
    this.requiresSpecialCompletion = false,
  });

  factory DriverRouteFlow.fromJson(Map<String, dynamic> json) =>
      DriverRouteFlow(
        mode: requireString(json, 'modo'),
        screen: requireString(json, 'pantalla'),
        requiresAcceptance: optionalBool(json, 'requiere_aceptacion'),
        allowsStageSelection: optionalBool(json, 'permite_elegir_etapa'),
        requestId: optionalString(json, 'solicitud_id'),
        stopType: optionalString(json, 'tipo_parada'),
        status: optionalString(json, 'estado'),
        segmentId: optionalString(json, 'tramo_id'),
        requiredEvidence: optionalString(json, 'evidencia_requerida'),
        requiresSpecialCompletion: optionalBool(
          json,
          'requiere_finalizacion_especial',
        ),
      );

  final String mode;
  final String screen;
  final bool requiresAcceptance;
  final bool allowsStageSelection;
  final String? requestId;
  final String? stopType;
  final String? status;
  final String? segmentId;
  final String? requiredEvidence;
  final bool requiresSpecialCompletion;

  bool get isAutomatic =>
      mode == 'AUTOMATICO' && !requiresAcceptance && !allowsStageSelection;
  bool get hasNoServices =>
      isAutomatic && screen == 'SIN_SERVICIOS' && requestId == null;
  String? get photoTargetStatus => !isAutomatic
      ? null
      : switch (screen) {
          'RECOLECCION'
              when status == 'AT_PICKUP' &&
                  stopType == 'RECOLECCION' &&
                  requiredEvidence == 'FOTO_RECOLECCION' =>
            'PICKED_UP',
          'ENTREGA'
              when status == 'AT_DESTINATION' &&
                  (stopType == 'ENTREGA' || stopType == 'ENVIO_ESPECIAL') &&
                  requiredEvidence == 'FOTO_ENTREGA' =>
            'DELIVERED',
          _ => null,
        };
  bool get canFinishSpecial =>
      isAutomatic &&
      screen == 'FINALIZAR_ESPECIAL' &&
      status == 'IN_TRANSIT' &&
      stopType == 'ENVIO_ESPECIAL' &&
      requiresSpecialCompletion;
}
