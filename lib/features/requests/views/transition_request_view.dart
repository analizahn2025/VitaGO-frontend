import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/tracking/controllers/tracking_controller.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

class TransitionRequestView extends ConsumerStatefulWidget {
  const TransitionRequestView({
    required this.request,
    required this.allowedStatuses,
    this.gpsRequired = false,
    super.key,
  });

  final ServiceRequestDetail request;
  final List<String> allowedStatuses;
  final bool gpsRequired;

  @override
  ConsumerState<TransitionRequestView> createState() =>
      _TransitionRequestViewState();
}

class _TransitionRequestViewState extends ConsumerState<TransitionRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _targetStatus;
  DeviceLocation? _location;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  bool get _requiresReason => const {
    'CANCELLED',
    'PICKUP_FAILED',
    'DELIVERY_FAILED',
  }.contains(_targetStatus);

  bool get _requiresLocation =>
      widget.gpsRequired ||
      (widget.request.isSpecial &&
          const {
            'PICKED_UP',
            'DELIVERED',
            'DELIVERY_FAILED',
          }.contains(_targetStatus));

  bool get _closesSpecialMovement =>
      widget.request.isSpecial &&
      const {'DELIVERED', 'DELIVERY_FAILED'}.contains(_targetStatus);

  @override
  void initState() {
    super.initState();
    if (widget.allowedStatuses.length == 1) {
      _targetStatus = widget.allowedStatuses.single;
    }
    if (widget.gpsRequired) {
      Future<void>.microtask(_captureLocation);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.allowedStatuses.length == 1
              ? 'Continuar servicio'
              : 'Actualizar solicitud',
        ),
      ),
      body: SafeArea(
        child: RequiredGpsBody(
          enabled: widget.gpsRequired,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  widget.request.number,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Estado actual: ${requestStatusLabel(widget.request.status)}',
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (widget.allowedStatuses.length == 1)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Siguiente paso',
                    ),
                    child: Text(
                      requestTransitionActionLabel(_targetStatus!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _targetStatus,
                    decoration: const InputDecoration(labelText: 'Resultado'),
                    items: widget.allowedStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(requestTransitionActionLabel(status)),
                          ),
                        )
                        .toList(growable: false),
                    validator: (value) =>
                        value == null ? 'Selecciona el resultado.' : null,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _targetStatus = value),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reason,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: _requiresReason
                        ? 'Motivo obligatorio'
                        : 'Motivo (opcional)',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      _requiresReason && (value == null || value.trim().isEmpty)
                      ? 'Explica el motivo de este resultado.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.my_location),
                  title: Text(
                    _location == null
                        ? _requiresLocation
                              ? 'Ubicación obligatoria'
                              : 'Ubicación opcional'
                        : '${_location!.latitudeText}, ${_location!.longitudeText}',
                  ),
                  subtitle: Text(
                    _requiresLocation
                        ? 'Este estado necesita el punto GPS real para calcular y cerrar el recorrido.'
                        : 'Adjunta el punto real donde ocurre el cambio.',
                  ),
                  trailing: IconButton(
                    onPressed: _locating || _saving ? null : _captureLocation,
                    tooltip: 'Obtener ubicación',
                    icon: _locating
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update),
                  label: Text(
                    _targetStatus == null
                        ? 'Guardar cambio'
                        : requestTransitionActionLabel(_targetStatus!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (mounted) setState(() => _location = location);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_requiresLocation && _location == null) {
      await _captureLocation();
    }
    if (_requiresLocation && _location == null) {
      setState(() {
        _error = 'Obtén la ubicación actual antes de guardar este estado.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_closesSpecialMovement) {
        await _sendFinalTrackingPoint();
      }
      final updated = await ref
          .read(requestActionsControllerProvider)
          .transition(
            widget.request.id,
            RequestTransitionInput(
              targetStatus: _targetStatus!,
              latitude: _location?.latitudeText,
              longitude: _location?.longitudeText,
              reason: _reason.text,
            ),
          );
      if (updated.status.toUpperCase() != _targetStatus!.toUpperCase()) {
        throw AppFailure(
          message:
              'El servidor respondió con estado ${updated.status}; se esperaba $_targetStatus.',
        );
      }
      if (mounted) Navigator.of(context).pop(updated);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = _failureMessage(failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _failureMessage(AppFailure failure) {
    final code = failure.statusCode;
    return code == null ? failure.message : '${failure.message} (HTTP $code)';
  }

  Future<void> _sendFinalTrackingPoint() async {
    final movement = widget.request.specialMovement;
    final location = _location;
    if (movement == null || location == null) {
      throw const AppFailure(
        message: 'No se encontró el recorrido especial activo. Actualiza la solicitud e inténtalo de nuevo.',
      );
    }
    await ref
        .read(trackingActionsControllerProvider)
        .register(
          TrackingBatchInput(
            shiftId: movement.shiftId,
            points: [
              TrackingPointInput(
                clientId: const Uuid().v4(),
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
