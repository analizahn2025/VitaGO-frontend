import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/incidents/views/create_incident_view.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/operations/widgets/driver_requests_section.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/views/shift_detail_view.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';

class OperationsView extends ConsumerStatefulWidget {
  const OperationsView({
    required this.profile,
    this.activationToken = 0,
    super.key,
  });

  final UserProfile profile;
  final int activationToken;

  @override
  ConsumerState<OperationsView> createState() => _OperationsViewState();
}

class _OperationsViewState extends ConsumerState<OperationsView>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant OperationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activationToken != widget.activationToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshDelivery());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDelivery());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.can(AppPermissions.viewShifts)) {
      return const AppEmptyView(
        icon: Icons.route_outlined,
        title: 'Operación no disponible',
        message: 'Tu perfil no puede consultar jornadas operativas.',
      );
    }

    final activeShift = ref.watch(activeShiftControllerProvider);
    final deliveryBoard = ref.watch(driverDeliveryControllerProvider);
    final driverProfile = ref.watch(ownDriverProfileControllerProvider);
    final content = activeShift.when(
      loading: () => const AppLoadingView(label: 'Consultando jornada…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeShiftControllerProvider),
      ),
      data: (shift) => _buildContent(shift, deliveryBoard, driverProfile),
    );
    return RequiredGpsBody(
      onReportProblem: widget.profile.can(AppPermissions.createIncidents)
          ? _openCreateIncident
          : null,
      child: content,
    );
  }

  Widget _buildContent(
    DriverShift? shift,
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
    AsyncValue<DriverProfile> driverProfile,
  ) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _refreshDelivery,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Container(
            color: shift == null
                ? colors.surfaceContainerHighest
                : colors.primary,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${widget.profile.user.firstNames.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: shift == null ? null : colors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  shift == null
                      ? 'Todo listo para comenzar tu jornada.'
                      : 'Jornada activa desde ${AppDateFormat.dateTime(shift.startedAt)}',
                  style: TextStyle(
                    color: shift == null
                        ? colors.onSurfaceVariant
                        : colors.onPrimary.withValues(alpha: 0.88),
                  ),
                ),
                if (shift != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  StatusBadge(status: shift.status),
                ],
              ],
            ),
          ),
          if (_error case final error?)
            _MessageBand(message: error, isError: true),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shift == null)
                  _buildInactiveActions(deliveryBoard, driverProfile)
                else
                  _buildActiveActions(shift, deliveryBoard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveActions(
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
    AsyncValue<DriverProfile> driverProfile,
  ) {
    final vehicle = driverProfile.value?.vehicle;
    final canStart = driverProfile.hasValue && vehicle?.status == 'ACTIVO';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canStart) ...[
          _MotorcycleReadiness(
            loading: driverProfile.isLoading,
            message: driverProfile.hasError
                ? 'No fue posible verificar tu motocicleta.'
                : 'Necesitas una motocicleta activa para iniciar.',
            onRetry: driverProfile.hasError
                ? () => ref.invalidate(ownDriverProfileControllerProvider)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (widget.profile.can(AppPermissions.startShift))
          FilledButton.icon(
            onPressed: _busy || !canStart ? null : _startShift,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Iniciar jornada'),
          ),
        const SizedBox(height: AppSpacing.xl),
        _buildDriverRequests(deliveryBoard),
        if (widget.profile.can(AppPermissions.createIncidents)) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _openCreateIncident,
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Reportar un problema'),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveActions(
    DriverShift shift,
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
  ) {
    final board = deliveryBoard.value;
    final canFinishFromBoard =
        deliveryBoard.hasValue && !(board?.hasActiveAssignments ?? true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDriverRequests(deliveryBoard),
        if (widget.profile.can(AppPermissions.registerDriverLocation)) ...[
          const SizedBox(height: AppSpacing.lg),
          _AutomaticTrackingStatus(
            status: ref.watch(driverTrackingStatusProvider),
          ),
        ],
        if (widget.profile.can(AppPermissions.createIncidents)) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _busy ? null : _openCreateIncident,
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Reportar un problema'),
          ),
        ],
        if (widget.profile.can(AppPermissions.finishShift)) ...[
          const SizedBox(height: AppSpacing.xl),
          if (!canFinishFromBoard) ...[
            _FinishShiftNotice(
              hasActiveAssignments: board?.hasActiveAssignments ?? false,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          FilledButton.icon(
            onPressed: _busy || !canFinishFromBoard
                ? null
                : () => _confirmFinish(shift.id),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Finalizar jornada'),
          ),
        ],
      ],
    );
  }

  Widget _buildDriverRequests(AsyncValue<DriverDeliveryBoard> deliveryBoard) {
    return DriverRequestsSection(
      board: deliveryBoard,
      onRetry: () => ref.invalidate(driverDeliveryControllerProvider),
      onOpenRequest: _openRequest,
    );
  }

  Future<void> _refreshDelivery() async {
    if (_refreshing) return;
    _refreshing = true;
    ref.invalidate(activeShiftControllerProvider);
    ref.invalidate(driverDeliveryControllerProvider);
    ref.invalidate(ownDriverProfileControllerProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
    try {
      await Future.wait([
        ref.read(activeShiftControllerProvider.future),
        ref.read(driverDeliveryControllerProvider.future),
        ref.read(ownDriverProfileControllerProvider.future),
      ]);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _openRequest(String requestId) async {
    await context.pushNamed<void>(
      'request-detail',
      pathParameters: {'requestId': requestId},
    );
    ref.invalidate(driverDeliveryControllerProvider);
    ref.invalidate(activeShiftControllerProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
  }

  Future<ShiftCoordinatesInput> _currentCoordinates() async {
    final location = await ref
        .read(deviceLocationServiceProvider)
        .getCurrentLocation();
    return ShiftCoordinatesInput(
      latitude: location.latitudeText,
      longitude: location.longitudeText,
    );
  }

  Future<void> _startShift() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final input = await _currentCoordinates();
      await ref.read(shiftActionsControllerProvider).start(input);
      ref.invalidate(activeShiftControllerProvider);
      ref.invalidate(driverDeliveryControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmFinish(String shiftId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar jornada'),
        content: const Text(
          'Solo puedes finalizar si no conservas asignaciones activas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _finishShift(shiftId);
  }

  Future<void> _finishShift(String shiftId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final input = await _currentCoordinates();
      final finished = await ref
          .read(shiftActionsControllerProvider)
          .finish(shiftId, input);
      ref.invalidate(activeShiftControllerProvider);
      ref.invalidate(driverDeliveryControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => ShiftDetailView(shift: finished),
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCreateIncident() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const CreateIncidentView()),
    );
    ref.invalidate(activeShiftControllerProvider);
  }
}

class _AutomaticTrackingStatus extends StatelessWidget {
  const _AutomaticTrackingStatus({required this.status});

  final DriverTrackingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            status.sending
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.gps_fixed, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS conectado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    status.error != null
                        ? status.error!
                        : status.lastSyncedAt == null
                        ? 'El seguimiento comienza automáticamente.'
                        : 'Último envío: ${AppDateFormat.dateTime(status.lastSyncedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBand extends StatelessWidget {
  const _MessageBand({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: isError ? colors.errorContainer : colors.tertiaryContainer,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? colors.onErrorContainer : colors.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _FinishShiftNotice extends StatelessWidget {
  const _FinishShiftNotice({required this.hasActiveAssignments});

  final bool hasActiveAssignments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasActiveAssignments
                  ? 'Completa tus servicios en curso antes de finalizar la jornada.'
                  : 'Se está verificando que no queden servicios en curso.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MotorcycleReadiness extends StatelessWidget {
  const _MotorcycleReadiness({
    required this.loading,
    required this.message,
    this.onRetry,
  });

  final bool loading;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.two_wheeler_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(loading ? 'Verificando motocicleta…' : message)),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              tooltip: 'Reintentar',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
