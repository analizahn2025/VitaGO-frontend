import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitago_app/features/fleet/widgets/driver_tube_load.dart';
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
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/widgets/driver_route_section.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/shifts/views/shift_detail_view.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/widgets/required_gps_body.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';

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
  Timer? _cutRefreshTimer;

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
    _cutRefreshTimer?.cancel();
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

    ref.listen(activeShiftDayControllerProvider, (previous, next) {
      if (next.value case final day?) _scheduleCutRefresh(day);
    });
    final activeDay = ref.watch(activeShiftDayControllerProvider);
    final deliveryBoard = ref.watch(driverDeliveryControllerProvider);
    final driverProfile = ref.watch(ownDriverProfileControllerProvider);
    final content = activeDay.when(
      loading: () => const AppLoadingView(label: 'Consultando jornada…'),
      error: (error, stackTrace) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeShiftDayControllerProvider),
      ),
      data: (day) => _buildContent(day, deliveryBoard, driverProfile),
    );
    return RequiredGpsBody(
      onReportProblem: widget.profile.can(AppPermissions.createIncidents)
          ? _openCreateIncident
          : null,
      child: content,
    );
  }

  Widget _buildContent(
    ActiveShiftDay day,
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
    AsyncValue<DriverProfile> driverProfile,
  ) {
    final shift = day.shift;
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
                  day.closurePending || day.isAfterCut
                      ? 'La operación de hoy terminó a las 22:00.'
                      : shift?.onLunch == true
                      ? 'Estás en almuerzo. Regresa desde esta jornada cuando estés listo.'
                      : shift == null
                      ? day.shiftStartedToday == true
                            ? 'Tu jornada de hoy ya finalizó.'
                            : 'Todo listo para comenzar tu jornada.'
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
                if (day.supportsDailySchedule && !day.isAfterCut) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Horario de hoy: hasta las 22:00${day.operationalTimeZone == null ? '' : ' · ${day.operationalTimeZone}'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: shift == null
                          ? colors.onSurfaceVariant
                          : colors.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error case final error?)
            _MessageBand(message: error, isError: true),
          if (day.supportsDailySchedule &&
              (day.closurePending ||
                  day.isAfterCut ||
                  (shift == null && day.shiftStartedToday == true)))
            _MessageBand(
              message: day.closurePending
                  ? 'El cierre de hoy está pendiente en el servidor. No puedes operar nuevos servicios.'
                  : day.isAfterCut
                  ? 'El horario operativo terminó. Vuelve mañana para iniciar una nueva jornada.'
                  : 'Ya completaste una jornada hoy. Podrás iniciar otra mañana.',
            ),
          if (shift == null &&
              day.canStartShift == false &&
              day.shiftStartedToday != true &&
              !day.isAfterCut)
            const _MessageBand(
              message: 'No puedes iniciar una jornada en este momento. Revisa tu disponibilidad y motocicleta.',
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (driverProfile.value case final driver?) ...[
                  DriverTubeLoad(driver: driver),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (shift == null)
                  _buildInactiveActions(day, deliveryBoard, driverProfile)
                else
                  _buildActiveActions(day, shift, deliveryBoard, driverProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveActions(
    ActiveShiftDay day,
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
    AsyncValue<DriverProfile> driverProfile,
  ) {
    final vehicle = driverProfile.value?.vehicle;
    final canStart =
        driverProfile.hasValue &&
        vehicle?.status == 'ACTIVO' &&
        day.canStartShift != false &&
        !day.isAfterCut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (driverProfile.hasError || vehicle?.status != 'ACTIVO') ...[
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
    ActiveShiftDay day,
    DriverShift shift,
    AsyncValue<DriverDeliveryBoard> deliveryBoard,
    AsyncValue<DriverProfile> driverProfile,
  ) {
    final board = deliveryBoard.value;
    final canFinishFromBoard =
        deliveryBoard.hasValue && !(board?.hasActiveAssignments ?? true);
    final canOperate =
        shift.isOperational && !day.closurePending && !day.isAfterCut;
    final canStartLunch =
        day.supportsDailySchedule &&
        canOperate &&
        !shift.onLunch &&
        driverProfile.value?.operationalStatus == 'AVAILABLE' &&
        canFinishFromBoard &&
        widget.profile.can(AppPermissions.updateOwnDriverStatus);
    final canFinishLunch =
        day.supportsDailySchedule &&
        shift.onLunch &&
        !day.closurePending &&
        !day.isAfterCut &&
        widget.profile.can(AppPermissions.updateOwnDriverStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shift.onLunch && day.supportsDailySchedule) ...[
          _MessageBand(
            message: 'En almuerzo. No recibirás nuevas asignaciones hasta que regreses.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canStartLunch || canFinishLunch) ...[
          FilledButton.tonalIcon(
            onPressed: _busy
                ? null
                : () => _changeLunch(shift.id, finish: canFinishLunch),
            icon: Icon(
              canFinishLunch ? Icons.play_arrow : Icons.lunch_dining_outlined,
            ),
            label: Text(
              canFinishLunch ? 'Regresé del almuerzo' : 'Iniciar almuerzo',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canOperate)
          DriverRouteSection(
            profile: widget.profile,
            canCalculate: widget.profile.can(AppPermissions.calculateRoute),
            onOpenRequest: _openRequest,
          ),
        const SizedBox(height: AppSpacing.lg),
        _buildDriverRequests(deliveryBoard),
        if (widget.profile.can(AppPermissions.registerDriverLocation)) ...[
          const SizedBox(height: AppSpacing.lg),
          _AutomaticTrackingStatus(
            status: ref.watch(driverTrackingStatusProvider),
            captureEnabled: !day.closurePending && !day.isAfterCut,
          ),
        ],
        if (canOperate &&
            widget.profile.can(AppPermissions.createIncidents)) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _busy ? null : _openCreateIncident,
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Reportar un problema'),
          ),
        ],
        if (!day.closurePending &&
            !day.isAfterCut &&
            widget.profile.can(AppPermissions.finishShift)) ...[
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

  void _scheduleCutRefresh(ActiveShiftDay day) {
    _cutRefreshTimer?.cancel();
    final serverNow = day.currentServerTime;
    final cut = day.scheduledCloseAt;
    if (serverNow == null || cut == null || !serverNow.isBefore(cut)) return;
    _cutRefreshTimer = Timer(cut.difference(serverNow), () {
      if (mounted) unawaited(_refreshDelivery());
    });
  }

  Future<void> _changeLunch(String shiftId, {required bool finish}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actions = ref.read(shiftActionsControllerProvider);
      if (finish) {
        await actions.finishLunch(shiftId);
      } else {
        await actions.startLunch(shiftId);
      }
      ref.invalidate(activeShiftDayControllerProvider);
      ref.invalidate(activeShiftControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
      ref.invalidate(driverDeliveryControllerProvider);
      ref.invalidate(myRouteProvider);
      await ref.read(activeShiftDayControllerProvider.future);
      try {
        await Future.wait([
          ref.read(ownDriverProfileControllerProvider.future),
          ref.read(driverDeliveryControllerProvider.future),
        ]);
      } on Object {
        if (mounted) {
          setState(
            () => _error = 'El almuerzo se actualizó. Desliza hacia abajo para volver a cargar tus servicios.',
          );
        }
      }
      try {
        await ref.read(myRouteProvider.future);
      } on Object {
        // La jornada se actualizó; la ruta puede estar temporalmente inactiva.
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(
          () => _error =
              failure.fieldMessage('almuerzo', 'jornada') ??
              failure.fieldMessage('estado_operativo') ??
              failure.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshDelivery() async {
    if (_refreshing) return;
    _refreshing = true;
    ref.invalidate(activeShiftControllerProvider);
    ref.invalidate(activeShiftDayControllerProvider);
    ref.invalidate(driverDeliveryControllerProvider);
    ref.invalidate(ownDriverProfileControllerProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
    ref.invalidate(myRouteProvider);
    try {
      await Future.wait([
        ref.read(activeShiftControllerProvider.future),
        ref.read(activeShiftDayControllerProvider.future),
        ref.read(driverDeliveryControllerProvider.future),
        ref.read(ownDriverProfileControllerProvider.future),
      ]);
    } on Object {
      // Los providers muestran el error y conservan su opción de reintento.
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
    ref.invalidate(activeShiftDayControllerProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
    ref.invalidate(myRouteProvider);
  }

  Future<void> _startShift() async {
    final accepted = await _confirmBackgroundTracking();
    if (!accepted || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final configuration = await _trackingConfiguration(
        requireOfficialTime: true,
      );
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      final started = await ref
          .read(shiftActionsControllerProvider)
          .start(
            ShiftCoordinatesInput(
              latitude: location.latitudeText,
              longitude: location.longitudeText,
            ),
          );
      final coordinator = ref.read(trackingQueueCoordinatorProvider);
      await coordinator.capture(started.id, location);
      try {
        await coordinator.flush(
          started.id,
          maximumBatchSize: configuration.maximumBatchSize,
        );
      } on AppFailure catch (failure) {
        if (mounted) {
          setState(() {
            _error =
                'La jornada inició. El GPS quedó guardado y se reenviará automáticamente. ${failure.message}';
          });
        }
      }
      ref.invalidate(activeShiftControllerProvider);
      ref.invalidate(activeShiftDayControllerProvider);
      ref.invalidate(driverDeliveryControllerProvider);
      ref.invalidate(ownDriverProfileControllerProvider);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmBackgroundTracking() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            icon: const Icon(Icons.my_location_outlined),
            title: const Text('Ubicación durante la jornada'),
            content: const Text(
              'VitaGo registrará tu ubicación mientras la jornada esté activa, incluso al usar el mapa integrado o apagar la pantalla. El mapa integrado usa Google Maps y, al abrirlo, Google procesa las coordenadas necesarias para mostrarlo. Si no hay internet, los puntos se guardarán de forma privada en el teléfono para enviarlos después. Puedes revocar el permiso desde los ajustes del dispositivo, pero no podrás continuar la operación con el GPS apagado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Aceptar e iniciar'),
              ),
            ],
          ),
        ) ??
        false;
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
      final location = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      final configuration = await _trackingConfiguration();
      final coordinator = ref.read(trackingQueueCoordinatorProvider);
      await coordinator.capture(shiftId, location);
      try {
        await coordinator.flush(
          shiftId,
          maximumBatchSize: configuration.maximumBatchSize,
        );
      } on AppFailure {
        // El cierre operativo no depende de que la cola alcance al servidor
        // en este instante. El manifiesto declara también esos puntos.
      }
      final manifest = await coordinator.manifest(shiftId);
      final finished = await ref
          .read(shiftActionsControllerProvider)
          .finish(
            shiftId,
            ShiftCoordinatesInput(
              latitude: location.latitudeText,
              longitude: location.longitudeText,
              gpsSessions: manifest,
            ),
          );
      if (finished.mileageQuality?.synchronizationVerified == true) {
        await coordinator.clearShift(shiftId);
      }
      ref.invalidate(activeShiftControllerProvider);
      ref.invalidate(activeShiftDayControllerProvider);
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

  Future<TrackingConfiguration> _trackingConfiguration({
    bool requireOfficialTime = false,
  }) async {
    try {
      final configuration = await (requireOfficialTime
          ? ref.refresh(trackingConfigurationProvider.future)
          : ref.read(trackingConfigurationProvider.future));
      if (requireOfficialTime &&
          !ref.read(serverTimeClockProvider).isSynchronized) {
        throw const AppFailure(
          message: 'No fue posible sincronizar la hora oficial del GPS.',
        );
      }
      return configuration;
    } on AppFailure {
      if (requireOfficialTime ||
          !ref.read(serverTimeClockProvider).isSynchronized) {
        rethrow;
      }
      return TrackingConfiguration.defaults;
    } on Object {
      if (requireOfficialTime ||
          !ref.read(serverTimeClockProvider).isSynchronized) {
        throw const AppFailure(
          message: 'Conecta el teléfono para sincronizar la hora oficial antes de iniciar la jornada.',
        );
      }
      return TrackingConfiguration.defaults;
    }
  }

  Future<void> _openCreateIncident() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const CreateIncidentView()),
    );
    ref.invalidate(activeShiftControllerProvider);
    ref.invalidate(activeShiftDayControllerProvider);
  }
}

class _AutomaticTrackingStatus extends StatelessWidget {
  const _AutomaticTrackingStatus({
    required this.status,
    required this.captureEnabled,
  });

  final DriverTrackingStatus status;
  final bool captureEnabled;

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
                    captureEnabled
                        ? 'GPS conectado'
                        : 'GPS pendiente de sincronizar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    status.error != null
                        ? status.error!
                        : !captureEnabled && status.pendingPoints == 0
                        ? 'No se registran nuevos puntos después del cierre.'
                        : status.pendingPoints > 0
                        ? '${status.pendingPoints} punto${status.pendingPoints == 1 ? '' : 's'} pendiente${status.pendingPoints == 1 ? '' : 's'} de envío.'
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
