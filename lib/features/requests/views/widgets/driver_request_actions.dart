import 'package:flutter/material.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/cancel_request_dialog.dart';
import 'package:vitago_app/features/requests/views/driver_request_stage_presenter.dart';
import 'package:vitago_app/features/requests/views/transition_request_view.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

/// The same driver workflow, presented from the detail view or over the map.
class DriverRequestActions extends ConsumerStatefulWidget {
  const DriverRequestActions({
    required this.request,
    required this.profile,
    required this.onCompleted,
    this.useModal = false,
    this.disabled = false,
    this.stopType,
    this.flow,
    super.key,
  });

  final ServiceRequestDetail request;
  final UserProfile profile;
  final Future<void> Function(ServiceRequestDetail) onCompleted;
  final bool useModal;
  final bool disabled;
  final String? stopType;
  final DriverRouteFlow? flow;

  @override
  ConsumerState<DriverRequestActions> createState() =>
      _DriverRequestActionsState();
}

class _DriverRequestActionsState extends ConsumerState<DriverRequestActions> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final profile = widget.profile;
    final colors = Theme.of(context).colorScheme;
    final gps = profile.isDriver
        ? ref.watch(locationServiceEnabledProvider)
        : null;
    final hasGps = !profile.isDriver || (gps != null && _gpsAvailable(gps));
    final actionsEnabled = !_busy && !widget.disabled && hasGps;
    final shift = ref.watch(activeShiftControllerProvider);
    final flow = widget.flow ?? ref.watch(myRouteProvider).value?.flow;
    final isCurrent =
        flow?.isAutomatic == true &&
        flow?.requestId == request.id &&
        flow?.status == request.status &&
        (widget.stopType == null || widget.stopType == flow?.stopType);
    final canOperate =
        profile.isDriver &&
        profile.can(AppPermissions.updateRequestStatus) &&
        shift.value?.isOperational == true &&
        isCurrent;
    final exceptions = canOperate
        ? (requestTransitionMatrix[request.status] ?? const <String>[])
              .where(
                (target) =>
                    const {'PICKUP_FAILED', 'DELIVERY_FAILED'}.contains(target),
              )
              .toList(growable: false)
        : const <String>[];
    final photoTarget = canOperate ? flow?.photoTargetStatus : null;
    final finishSpecial =
        canOperate && request.isSpecial && flow?.canFinishSpecial == true;
    final primary = photoTarget ?? (finishSpecial ? 'AT_DESTINATION' : null);
    final primaryEnabled =
        actionsEnabled &&
        (photoTarget == null || profile.can(AppPermissions.createEvidence));
    final canCancel =
        profile.can(AppPermissions.cancelRequests) &&
        requestIsCancellable(request.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cantidad de tubos: ${request.summary.tubeCount ?? 'Sin declarar'}',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (profile.isDriver && (shift.isLoading || gps?.isLoading == true))
          const LinearProgressIndicator(),
        if (profile.isDriver && gps?.value == false)
          Text(
            'GPS apagado. Actívalo para continuar.',
            style: TextStyle(color: colors.error),
          ),
        if (profile.isDriver && gps?.hasError == true)
          Text(
            'No fue posible verificar el GPS. Revisa la ubicación del teléfono.',
            style: TextStyle(color: colors.error),
          ),
        if (profile.isDriver &&
            !shift.isLoading &&
            shift.value == null &&
            !request.isTerminal)
          const Text('Inicia tu jornada para continuar con el servicio.'),
        if (canOperate && flow?.screen == 'MAPA')
          const Text(
            'Sigue el mapa y mantén el GPS encendido. La foto se habilitará al llegar.',
          ),
        if (!isCurrent && !request.isTerminal) ...[
          const Text(
            'Este envío está en espera o necesita actualizarse. El servicio actual lo indica tu ruta.',
          ),
          TextButton(
            onPressed: () => ref.invalidate(myRouteProvider),
            child: const Text('Actualizar servicio actual'),
          ),
        ],
        if (primary != null || exceptions.isNotEmpty || canCancel)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (primary != null)
                FilledButton.icon(
                  onPressed: primaryEnabled
                      ? () => _run(
                          () => _openPrimary(primary, photoTarget != null),
                        )
                      : null,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          photoTarget != null
                              ? Icons.photo_camera_outlined
                              : Icons.task_alt,
                        ),
                  label: Text(
                    finishSpecial
                        ? 'Finalizar encargo'
                        : photoTarget == 'PICKED_UP'
                        ? 'Tomar foto de recolección'
                        : 'Tomar foto de entrega',
                  ),
                ),
              if (exceptions.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: actionsEnabled
                      ? () => _run(
                          () => _openForm(
                            TransitionRequestView(
                              request: request,
                              allowedStatuses: exceptions,
                              gpsRequired: true,
                            ),
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.report_problem_outlined),
                  label: Text(
                    exceptions.length == 1
                        ? requestTransitionActionLabel(exceptions.single)
                        : 'Reportar problema',
                  ),
                ),
              if (canCancel)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                  ),
                  onPressed: actionsEnabled
                      ? () => _run(
                          () => showDialog<ServiceRequestDetail>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                CancelRequestDialog(request: request),
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar envío'),
                ),
            ],
          ),
        if (_error case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: TextStyle(color: colors.error)),
        ],
      ],
    );
  }

  Future<ServiceRequestDetail?> _openPrimary(String target, bool needsPhoto) {
    return presentDriverRequestStage(
      context,
      request: widget.request,
      targetStatus: target,
      needsPhoto: needsPhoto,
      useModal: widget.useModal,
    );
  }

  Future<ServiceRequestDetail?> _openForm(Widget form) {
    if (!widget.useModal) {
      return Navigator.of(context).push<ServiceRequestDetail>(
        MaterialPageRoute<ServiceRequestDetail>(builder: (_) => form),
      );
    }
    return showModalBottomSheet<ServiceRequestDetail>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: form),
    );
  }

  Future<void> _run(Future<ServiceRequestDetail?> Function() action) async {
    if (_busy || widget.disabled) return;
    if (widget.profile.isDriver &&
        !_gpsAvailable(ref.read(locationServiceEnabledProvider))) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action();
      if (updated == null || !mounted) return;
      ref.invalidate(ownDriverProfileControllerProvider);
      ref.invalidate(
        requestEvidenceControllerProvider((ownerId: updated.id, page: 1)),
      );
      ref.invalidate(requestControllerProvider(updated.id));
      ref.invalidate(myRouteProvider);
      await widget.onCompleted(updated);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

bool _gpsAvailable(AsyncValue<bool> gps) =>
    !gps.isLoading && !gps.hasError && gps.value == true;
