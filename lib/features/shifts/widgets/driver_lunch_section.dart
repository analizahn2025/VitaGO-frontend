import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';

class DriverLunchSection extends ConsumerStatefulWidget {
  const DriverLunchSection({
    required this.canUpdate,
    this.isActive = true,
    super.key,
  });

  final bool canUpdate;
  final bool isActive;

  @override
  ConsumerState<DriverLunchSection> createState() => _DriverLunchSectionState();
}

class _DriverLunchSectionState extends ConsumerState<DriverLunchSection>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _error;
  String? _notice;
  Timer? _cutRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refresh();
    }
  }

  @override
  void didUpdateWidget(covariant DriverLunchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) {
      _cutRefreshTimer?.cancel();
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
    final dayState = ref.watch(activeShiftDayControllerProvider);
    final currentDay = dayState.value;
    if (widget.isActive && currentDay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          _scheduleCutRefresh(currentDay);
        }
      });
    }
    if (dayState.isLoading && !dayState.hasValue) {
      return const _LunchSectionFrame(child: LinearProgressIndicator());
    }
    if (dayState.hasError && !dayState.hasValue) {
      final error = dayState.error;
      return _LunchSectionFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              error is AppFailure
                  ? error.message
                  : 'No pudimos consultar tu jornada.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final day = dayState.value;
    final shift = day?.shift;
    if (day == null || !day.supportsDailySchedule || shift == null) {
      return const SizedBox.shrink();
    }

    final driver = ref.watch(ownDriverProfileControllerProvider);
    final board = shift.onLunch
        ? null
        : ref.watch(driverDeliveryControllerProvider);
    final canStart =
        widget.canUpdate &&
        shift.isOperational &&
        !shift.onLunch &&
        !day.closurePending &&
        !day.isAfterCut &&
        driver.value?.operationalStatus == 'AVAILABLE' &&
        board?.hasValue == true &&
        board?.value?.hasActiveAssignments == false;
    final canReturn =
        widget.canUpdate &&
        shift.isActive &&
        shift.onLunch &&
        !day.closurePending &&
        !day.isAfterCut;
    final lunchStartedAt =
        driver.value?.lunchStartedAt ??
        shift.lunchIntervals
            .where((item) => item.finishedAt == null)
            .firstOrNull
            ?.startedAt;
    final colors = Theme.of(context).colorScheme;

    return _LunchSectionFrame(
      onRefresh: _refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                shift.onLunch ? Icons.pause_circle_outline : Icons.schedule,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  shift.onLunch ? 'En almuerzo' : 'Pausa de almuerzo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _description(
              day,
              shift,
              canStart: canStart,
              boardLoading: board?.isLoading == true,
              boardError: board?.hasError == true,
              lunchStartedAt: lunchStartedAt,
            ),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error, style: TextStyle(color: colors.error)),
          ],
          if (_notice case final notice?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(notice),
          ],
          if (canStart || canReturn) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              key: Key(
                canReturn ? 'finish-lunch-account' : 'start-lunch-account',
              ),
              onPressed: _busy
                  ? null
                  : () => _confirmAndChange(shift.id, finish: canReturn),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      canReturn
                          ? Icons.play_arrow
                          : Icons.lunch_dining_outlined,
                    ),
              label: Text(
                canReturn ? 'Regresé del almuerzo' : 'Iniciar almuerzo',
              ),
            ),
          ],
          if (board?.hasError == true && !shift.onLunch) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a revisar servicios'),
            ),
          ],
        ],
      ),
    );
  }

  String _description(
    ActiveShiftDay day,
    DriverShift shift, {
    required bool canStart,
    required bool boardLoading,
    required bool boardError,
    required DateTime? lunchStartedAt,
  }) {
    if (day.closurePending || day.isAfterCut || !shift.isActive) {
      return 'La jornada de hoy ya no permite iniciar ni terminar un almuerzo.';
    }
    if (shift.onLunch) {
      final since = lunchStartedAt == null
          ? ''
          : ' desde ${AppDateFormat.dateTime(lunchStartedAt)}';
      return 'Pausado$since. Al regresar podrás recibir nuevos servicios.';
    }
    if (canStart) {
      return 'Dejarás de recibir asignaciones hasta que marques tu regreso.';
    }
    if (boardLoading) {
      return 'Revisando tus servicios antes de habilitar el almuerzo.';
    }
    if (boardError) {
      return 'No pudimos comprobar si tienes servicios pendientes.';
    }
    return 'Podrás iniciar cuando estés disponible y sin servicios asignados.';
  }

  Future<void> _confirmAndChange(String shiftId, {required bool finish}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          finish ? Icons.play_circle_outline : Icons.lunch_dining_outlined,
        ),
        title: Text(finish ? 'Regresar del almuerzo' : 'Iniciar almuerzo'),
        content: Text(
          finish
              ? 'Volverás a estar disponible y podrías recibir un servicio de inmediato.'
              : 'Tu jornada quedará en pausa y no recibirás servicios hasta que marques tu regreso desde Cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(finish ? 'Confirmar regreso' : 'Confirmar almuerzo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final actions = ref.read(shiftActionsControllerProvider);
      if (finish) {
        await actions.finishLunch(shiftId);
      } else {
        await actions.startLunch(shiftId);
      }
      _refresh();
      try {
        await Future.wait([
          ref.read(activeShiftDayControllerProvider.future),
          ref.read(ownDriverProfileControllerProvider.future),
          ref.read(driverDeliveryControllerProvider.future),
        ]);
      } on Object {
        if (mounted) {
          setState(
            () => _notice = 'El almuerzo se actualizó. Actualiza la jornada para ver el estado más reciente.',
          );
        }
      }
      try {
        await ref.read(myRouteProvider.future);
      } on Object {
        // Una ruta en pausa puede no estar disponible; el POST ya se completó.
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

  void _refresh() {
    ref.invalidate(activeShiftDayControllerProvider);
    ref.invalidate(activeShiftControllerProvider);
    ref.invalidate(ownDriverProfileControllerProvider);
    ref.invalidate(driverDeliveryControllerProvider);
    ref.invalidate(myRouteProvider);
    ref.invalidate(driverNotificationsControllerProvider);
    ref.invalidate(unreadNotificationCountControllerProvider);
  }

  void _scheduleCutRefresh(ActiveShiftDay day) {
    _cutRefreshTimer?.cancel();
    final now = day.currentServerTime;
    final cut = day.scheduledCloseAt;
    if (now == null || cut == null || !now.isBefore(cut)) {
      return;
    }
    _cutRefreshTimer = Timer(cut.difference(now), () {
      if (mounted && widget.isActive) {
        _refresh();
      }
    });
  }
}

class _LunchSectionFrame extends StatelessWidget {
  const _LunchSectionFrame({required this.child, this.onRefresh});

  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Icon(Icons.lunch_dining_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Mi jornada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Actualizar jornada',
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.surface),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ],
    );
  }
}
