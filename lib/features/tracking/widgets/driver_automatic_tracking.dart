import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/controllers/driver_arrivals_controller.dart';

class DriverAutomaticTracking extends ConsumerStatefulWidget {
  const DriverAutomaticTracking({
    required this.enabled,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Widget child;

  @override
  ConsumerState<DriverAutomaticTracking> createState() =>
      _DriverAutomaticTrackingState();
}

class _DriverAutomaticTrackingState
    extends ConsumerState<DriverAutomaticTracking>
    with WidgetsBindingObserver {
  StreamSubscription<DeviceLocation>? _locationSubscription;
  Timer? _sendTimer;
  TrackingConfiguration _configuration = TrackingConfiguration.defaults;
  DateTime? _lastCapturedAt;
  String? _shiftId;
  bool _starting = false;
  bool _sending = false;
  bool _retryBlockedByValidation = false;
  bool? _lastGpsEnabled;
  bool _gpsDialogOpen = false;
  bool _refreshClockAfterReconnect = false;
  bool _captureAllowed = true;
  DateTime? _scheduledCloseAt;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationServiceEnabledProvider);
      ref.invalidate(activeShiftControllerProvider);
      if (_shiftId case final shiftId?) {
        unawaited(_refreshReferenceAndFlush(shiftId));
      }
    }
    // No detener el stream al abrir el mapa integrado, bloquear la pantalla o pasar a
    // segundo plano: la jornada debe conservar su cola GPS.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop(updateStatus: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stop();
      });
      return widget.child;
    }
    final shift = ref.watch(activeShiftControllerProvider).value;
    // Un cierre pendiente puede conservar la jornada ACTIVA. La cola anterior
    // continúa enviándose, pero no se agregan posiciones posteriores al corte.
    _captureAllowed = shift?.canOperate != false || shift?.onLunch == true;
    _scheduledCloseAt = shift?.scheduledCloseAt;
    final gpsEnabled = ref.watch(locationServiceEnabledProvider).value == true;
    _handleGpsState(gpsEnabled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _synchronize(shift?.id, gpsEnabled);
    });
    return widget.child;
  }

  void _synchronize(String? shiftId, bool gpsEnabled) {
    if (widget.enabled && shiftId != null && gpsEnabled) {
      if (_shiftId != shiftId && !_starting) unawaited(_start(shiftId));
      return;
    }
    _stop();
  }

  Future<void> _start(String shiftId) async {
    _starting = true;
    _stop();
    final generation = ++_generation;
    _shiftId = shiftId;
    final status = ref.read(driverTrackingStatusProvider.notifier);
    status.setActive(true);
    try {
      final refreshed = await _refreshConfiguration();
      if (!mounted || generation != _generation || _shiftId != shiftId) {
        return;
      }
      if (!refreshed) {
        _configuration = TrackingConfiguration.defaults;
        if (!ref.read(serverTimeClockProvider).isSynchronized) {
          status.reportError(
            'Conecta el teléfono para sincronizar la hora oficial del GPS.',
          );
          _scheduleStartRetry(shiftId, generation);
          return;
        }
      }
      await ref.read(deviceLocationServiceProvider).ensurePermission();
      if (!mounted || generation != _generation || _shiftId != shiftId) return;

      // El mapa usa este mismo stream: no esperar al reenvío de la cola ni a
      // una lectura puntual del GPS para empezar a mostrar el movimiento.
      var receivedStreamLocation = false;
      _locationSubscription = ref
          .read(deviceLocationServiceProvider)
          .watchLocations(
            interval: Duration(seconds: _configuration.movingCaptureSeconds),
          )
          .listen(
            (location) {
              if (!mounted || generation != _generation) return;
              receivedStreamLocation = true;
              unawaited(_capture(shiftId, location));
            },
            onError: (Object error) {
              if (!mounted || generation != _generation) return;
              status.reportError(
                error is AppFailure
                    ? error.message
                    : 'No fue posible continuar el seguimiento GPS.',
              );
            },
          );
      await ref
          .read(trackingQueueCoordinatorProvider)
          .flushAll(maximumBatchSize: _configuration.maximumBatchSize);
      if (!mounted || generation != _generation || _shiftId != shiftId) return;
      _sendTimer = Timer.periodic(
        Duration(seconds: _configuration.sendIntervalSeconds),
        (_) => unawaited(_flush(shiftId)),
      );
      if (!receivedStreamLocation) {
        final firstLocation = await ref
            .read(deviceLocationServiceProvider)
            .getCurrentLocation();
        if (!mounted || generation != _generation || _shiftId != shiftId) {
          return;
        }
        // Una lectura puntual tardía no debe mover el marcador hacia atrás.
        if (!receivedStreamLocation) {
          await _capture(shiftId, firstLocation, force: true);
          return;
        }
      }
      await _flush(shiftId);
    } on AppFailure catch (failure) {
      if (mounted && generation == _generation) {
        status.reportError(failure.message);
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _capture(
    String shiftId,
    DeviceLocation location, {
    bool force = false,
  }) async {
    if (!mounted || _shiftId != shiftId) return;
    final generation = _generation;
    ref
        .read(driverTrackingStatusProvider.notifier)
        .setCurrentLocation(location);
    if (!_captureAllowed) return;
    final recordedAt = ref.read(serverTimeClockProvider).currentUtc();
    if (recordedAt == null) {
      ref
          .read(driverTrackingStatusProvider.notifier)
          .reportError(
            'Conecta el teléfono para sincronizar la hora oficial del GPS.',
          );
      return;
    }
    if (_scheduledCloseAt case final cut? when !recordedAt.isBefore(cut)) {
      return;
    }
    final moving = (location.speedMetersPerSecond ?? 0) >= 0.7;
    final cadence = Duration(
      seconds: moving
          ? _configuration.movingCaptureSeconds
          : _configuration.stoppedCaptureSeconds,
    );
    if (!force &&
        _lastCapturedAt != null &&
        recordedAt.difference(_lastCapturedAt!).abs() < cadence) {
      return;
    }
    final captured = await ref
        .read(trackingQueueCoordinatorProvider)
        .capture(shiftId, location, recordedAt: recordedAt);
    if (!mounted || generation != _generation) return;
    _lastCapturedAt = captured.recordedAt;
    final pending = await ref
        .read(trackingQueueCoordinatorProvider)
        .pendingCount(shiftId);
    if (!mounted || generation != _generation) return;
    ref.read(driverTrackingStatusProvider.notifier).setPendingPoints(pending);
    if (force) await _flush(shiftId);
  }

  Future<void> _flush(String shiftId) async {
    if (_sending || _retryBlockedByValidation || _shiftId != shiftId) return;
    _sending = true;
    final status = ref.read(driverTrackingStatusProvider.notifier);
    status.setSending(true);
    try {
      await ref
          .read(trackingQueueCoordinatorProvider)
          .flush(shiftId, maximumBatchSize: _configuration.maximumBatchSize);
      if (_refreshClockAfterReconnect) {
        if (mounted) ref.read(driverArrivalsProvider.notifier).recover();
        if (await _refreshConfiguration()) _refreshClockAfterReconnect = false;
      }
      final pending = await ref
          .read(trackingQueueCoordinatorProvider)
          .pendingCount(shiftId);
      status.markSynced(DateTime.now(), pendingPoints: pending);
    } on AppFailure catch (failure) {
      if (failure.statusCode == null) _refreshClockAfterReconnect = true;
      if (failure.statusCode == 400) _retryBlockedByValidation = true;
      final pending = await ref
          .read(trackingQueueCoordinatorProvider)
          .pendingCount(shiftId);
      status.setPendingPoints(pending);
      status.reportError(
        failure.statusCode == 400
            ? '${failure.fieldMessage('registros') ?? failure.message} La cola original se conservó y el reenvío automático quedó pausado para revisión.'
            : '$pending punto${pending == 1 ? '' : 's'} guardado${pending == 1 ? '' : 's'} para reenviar. ${failure.message}',
      );
    } finally {
      _sending = false;
      status.setSending(false);
    }
  }

  Future<bool> _refreshConfiguration() async {
    ref.invalidate(trackingConfigurationProvider);
    try {
      _configuration = await ref.read(trackingConfigurationProvider.future);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _refreshReferenceAndFlush(String shiftId) async {
    await _refreshConfiguration();
    if (!mounted || _shiftId != shiftId) return;
    await _flush(shiftId);
  }

  void _scheduleStartRetry(String shiftId, int generation) {
    _sendTimer?.cancel();
    _sendTimer = Timer(
      Duration(seconds: TrackingConfiguration.defaults.sendIntervalSeconds),
      () {
        if (!mounted || generation != _generation || _shiftId != shiftId) {
          return;
        }
        unawaited(_start(shiftId));
      },
    );
  }

  void _stop({bool updateStatus = true}) {
    if (_locationSubscription == null &&
        _sendTimer == null &&
        _shiftId == null) {
      return;
    }
    _generation += 1;
    unawaited(_locationSubscription?.cancel());
    _locationSubscription = null;
    _sendTimer?.cancel();
    _sendTimer = null;
    _shiftId = null;
    _lastCapturedAt = null;
    _retryBlockedByValidation = false;
    if (updateStatus) {
      ref.read(driverTrackingStatusProvider.notifier).setActive(false);
    }
  }

  void _handleGpsState(bool enabled) {
    final shouldWarn = _lastGpsEnabled == true && !enabled;
    _lastGpsEnabled = enabled;
    if (!shouldWarn || _gpsDialogOpen) return;
    _gpsDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          title: const Text('GPS apagado'),
          content: const Text(
            'No puedes continuar porque tienes el GPS apagado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(deviceLocationServiceProvider)
                    .openLocationSettings();
                ref.invalidate(locationServiceEnabledProvider);
              },
              child: const Text('Abrir GPS'),
            ),
          ],
        ),
      );
      _gpsDialogOpen = false;
    });
  }
}
