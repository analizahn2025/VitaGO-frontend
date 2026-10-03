import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/requests/controllers/request_stage_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

class ConfirmRequestStageView extends ConsumerStatefulWidget {
  const ConfirmRequestStageView({
    required this.request,
    required this.targetStatus,
    super.key,
  });

  final ServiceRequestDetail request;
  final String targetStatus;

  @override
  ConsumerState<ConfirmRequestStageView> createState() =>
      _ConfirmRequestStageViewState();
}

class _ConfirmRequestStageViewState
    extends ConsumerState<ConfirmRequestStageView> {
  final _trackingClientId = const Uuid().v4();
  XFile? _photo;
  DateTime? _capturedAt;
  DeviceLocation? _location;
  bool _evidenceUploaded = false;
  bool _pickingPhoto = false;
  bool _locating = false;
  bool _submitting = false;
  String? _progressMessage;
  String? _error;

  String get _requiredType => requestRequiredEvidenceType(widget.targetStatus)!;

  bool get _isPickup => widget.targetStatus == 'PICKED_UP';

  bool get _controlsLocked => _pickingPhoto || _submitting;

  String get _actionName => _isPickup ? 'recolección' : 'entrega';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_recoverLostPhoto);
    Future<void>.microtask(_captureLocation);
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = requestTransitionActionLabel(widget.targetStatus);
    return Scaffold(
      appBar: AppBar(title: Text(actionLabel)),
      body: SafeArea(
        child: RequiredGpsBody(
          child: ListView(
            key: const ValueKey('confirmation-form'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _StageProgress(
                hasPhoto: _photo != null || _evidenceUploaded,
                hasLocation: _location != null,
                isCompleting: _submitting,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Confirma la $_actionName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isPickup
                    ? 'Toma una foto del paquete. VitaGo guardará la ubicación y actualizará el servicio por ti.'
                    : 'Toma una foto al entregar el paquete. VitaGo guardará la ubicación y finalizará el servicio por ti.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_evidenceUploaded)
                _CapturePanel(
                  photo: _photo,
                  isPickup: _isPickup,
                  enabled: !_controlsLocked,
                  onTap: () => _selectPhoto(camera: true),
                )
              else
                _SavedEvidenceNotice(actionName: _actionName),
              const SizedBox(height: AppSpacing.md),
              _LocationStatus(
                isLocating: _locating,
                isReady: _location != null,
                onRetry: _controlsLocked || _locating ? null : _captureLocation,
              ),
              if (_progressMessage case final message?) ...[
                const SizedBox(height: AppSpacing.md),
                _ProgressNotice(message: message),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                _InlineError(message: error),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _controlsLocked
                  ? null
                  : _photo == null && !_evidenceUploaded
                  ? () => _selectPhoto(camera: true)
                  : _confirm,
              icon: _pickingPhoto || _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _photo == null && !_evidenceUploaded
                          ? Icons.photo_camera_outlined
                          : Icons.check_circle_outline,
                    ),
              label: Text(_primaryActionLabel),
            ),
            if (!_evidenceUploaded && !_submitting) ...[
              const SizedBox(height: AppSpacing.xxs),
              TextButton.icon(
                onPressed: _controlsLocked
                    ? null
                    : () => _selectPhoto(camera: _photo != null),
                icon: Icon(
                  _photo == null ? Icons.photo_library_outlined : Icons.replay,
                ),
                label: Text(
                  _photo == null
                      ? 'Elegir una foto de la galería'
                      : 'Tomar otra foto',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _primaryActionLabel {
    if (_progressMessage != null) return _progressMessage!;
    if (_evidenceUploaded) return 'Completar $_actionName';
    if (_photo == null) return 'Tomar foto';
    return 'Confirmar $_actionName';
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final photo = await ref
          .read(evidenceCaptureServiceProvider)
          .recoverLostPhoto();
      if (photo != null && mounted) {
        setState(() {
          _photo = photo;
          _capturedAt = DateTime.now();
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'No fue posible recuperar la imagen anterior.');
      }
    }
  }

  Future<void> _selectPhoto({required bool camera}) async {
    setState(() {
      _pickingPhoto = true;
      _error = null;
    });
    try {
      final service = ref.read(evidenceCaptureServiceProvider);
      final photo = camera
          ? await service.takePhoto()
          : await service.selectPhoto();
      if (photo == null || !mounted) return;
      if (await photo.length() > 10 * 1024 * 1024) {
        setState(() => _error = 'La imagen no puede superar 10 MB.');
        return;
      }
      setState(() {
        _photo = photo;
        _capturedAt = DateTime.now();
      });
    } on Object {
      if (mounted) setState(() => _error = 'No fue posible obtener la imagen.');
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _captureLocation() async {
    if (mounted) {
      setState(() {
        _locating = true;
        _error = null;
      });
    }
    try {
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (mounted) setState(() => _location = location);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = _failureMessage(failure));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    if (!_evidenceUploaded && _photo == null) {
      setState(() => _error = 'Toma o selecciona la fotografía requerida.');
      return;
    }
    if (_location == null) await _captureLocation();
    final location = _location;
    if (location == null) {
      if (mounted) {
        setState(() => _error = 'Obtén la ubicación actual para continuar.');
      }
      return;
    }

    setState(() {
      _submitting = true;
      _progressMessage = _evidenceUploaded
          ? 'Completando $_actionName…'
          : 'Guardando la foto…';
      _error = null;
    });
    try {
      final actions = ref.read(requestStageActionsControllerProvider);
      if (!_evidenceUploaded) {
        await actions.uploadRequiredEvidence(
          request: widget.request,
          targetStatus: widget.targetStatus,
          input: EvidenceUploadInput(
            filePath: _photo!.path,
            fileName: _photo!.name,
            latitude: location.latitudeText,
            longitude: location.longitudeText,
            capturedAt: _capturedAt ?? DateTime.now(),
            type: _requiredType,
          ),
        );
        if (!mounted) return;
        ref.invalidate(
          requestEvidenceControllerProvider((
            ownerId: widget.request.id,
            page: 1,
          )),
        );
        setState(() {
          _evidenceUploaded = true;
          _progressMessage = 'Completando $_actionName…';
        });
      }

      final updated = await actions.completeTransition(
        request: widget.request,
        targetStatus: widget.targetStatus,
        location: location,
        trackingClientId: _trackingClientId,
      );
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_actionName[0].toUpperCase()}${_actionName.substring(1)} confirmada.',
          ),
        ),
      );
      Navigator.of(context).pop(updated);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = _failureMessage(failure);
          _progressMessage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _progressMessage = null;
        });
      }
    }
  }

  String _failureMessage(AppFailure failure) {
    final code = failure.statusCode;
    return code == null ? failure.message : '${failure.message} (HTTP $code)';
  }
}

class _SavedEvidenceNotice extends StatelessWidget {
  const _SavedEvidenceNotice({required this.actionName});

  final String actionName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_done_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'La foto ya está guardada. Toca el botón para completar la $actionName.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress({
    required this.hasPhoto,
    required this.hasLocation,
    required this.isCompleting,
  });

  final bool hasPhoto;
  final bool hasLocation;
  final bool isCompleting;

  @override
  Widget build(BuildContext context) {
    return AdaptiveFormRow(
      minimumChildWidth: 88,
      spacing: AppSpacing.xs,
      children: [
        _ProgressStep(
          icon: Icons.photo_camera_outlined,
          label: 'Foto',
          done: hasPhoto,
          active: !hasPhoto,
        ),
        _ProgressStep(
          icon: Icons.my_location,
          label: 'Ubicación',
          done: hasLocation,
          active: hasPhoto && !hasLocation,
        ),
        _ProgressStep(
          icon: Icons.check,
          label: 'Confirmar',
          active: (hasPhoto && hasLocation) || isCompleting,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    this.done = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emphasized = done || active;
    return Semantics(
      label:
          '$label: ${done
              ? 'listo'
              : active
              ? 'actual'
              : 'pendiente'}',
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done
                  ? colors.primary
                  : active
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : icon,
              size: 20,
              color: done
                  ? colors.onPrimary
                  : emphasized
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: emphasized ? colors.primary : colors.onSurfaceVariant,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  const _CapturePanel({
    required this.photo,
    required this.isPickup,
    required this.enabled,
    required this.onTap,
  });

  final XFile? photo;
  final bool isPickup;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: photo == null
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.surface),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 250,
          child: photo == null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 36,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isPickup
                            ? 'Toma una foto del paquete'
                            : 'Toma una foto de la entrega',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Toca aquí para abrir la cámara',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(photo!.path),
                      fit: BoxFit.cover,
                      semanticLabel: isPickup
                          ? 'Vista previa de la foto de recolección'
                          : 'Vista previa de la foto de entrega',
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 54,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        color: Colors.black.withValues(alpha: 0.62),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Foto lista',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({
    required this.isLocating,
    required this.isReady,
    required this.onRetry,
  });

  final bool isLocating;
  final bool isReady;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = isReady
        ? 'Ubicación lista'
        : isLocating
        ? 'Obteniendo tu ubicación…'
        : 'Falta obtener la ubicación';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isReady
            ? colors.primaryContainer.withValues(alpha: 0.5)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          if (isLocating)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isReady ? Icons.location_on : Icons.location_searching,
              color: isReady ? colors.primary : colors.onSurfaceVariant,
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!isReady && !isLocating)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ProgressNotice extends StatelessWidget {
  const _ProgressNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
