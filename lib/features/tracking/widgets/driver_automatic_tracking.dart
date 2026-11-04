import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/models/nearby_capture_policy.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/controllers/driver_arrivals_controller.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';

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
  bool _flushRequested = false;
  bool _retryBlockedByValidation = false;
  bool? _lastGpsEnabled;
  bool _gpsDialogOpen = false;
  bool _refreshClockAfterReconnect = false;
  bool _captureAllowed = true;
  DateTime? _scheduledCloseAt;
  int _generation = 0;
  NearbyCapturePolicy? _nearbyPolicy;
  String? _objectiveKey;
  DeviceLocation? _lastLocation;
  bool _nearby = false;
  bool _receivedStreamLocation = false;
  int? _streamCaptureSeconds;
  int _streamRestartToken = 0;

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
    final route =
        widget.enabled &&
            shift?.isActive == true &&
            _configuration.nearbyCapture?.enabled == true
        ? ref.watch(myRouteProvider).value
        : null;
    // Un cierre pendiente puede conservar la jornada ACTIVA. La cola anterior
    // continúa enviándose, pero no se agregan posiciones posteriores al corte.
    final policy = _configuration.shiftTracking;
    _captureAllowed =
        shift?.isActive == true &&
        (policy == null || policy.permitsCaptureFor(shift!.id));
    _scheduledCloseAt = policy?.scheduledCloseAt ?? shift?.scheduledCloseAt;
    final gpsEnabled = ref.watch(locationServiceEnabledProvider).value == true;
    _handleGpsState(gpsEnabled);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateNearbyPolicy(
          route?.shiftId == shift?.id ? route?.nearbyCapture : null,
        );
        _synchronize(shift?.isActive == true ? shift?.id : null, gpsEnabled);
      }
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
      final policy = _configuration.shiftTracking;
      if (policy != null) {
        _captureAllowed = policy.permitsCaptureFor(shiftId);
        _scheduledCloseAt = policy.scheduledCloseAt;
        if (!_captureAllowed) {
          await ref
              .read(trackingQueueCoordinatorProvider)
              .flushAll(maximumBatchSize: _configuration.maximumBatchSize);
          if (mounted && generation == _generation) _stop();
          return;
        }
      }
      await ref.read(deviceLocationServiceProvider).ensurePermission();
      if (!mounted || generation != _generation || _shiftId != shiftId) return;

      // El mapa usa este mismo stream: no esperar al reenvío de la cola ni a
      // una lectura puntual del GPS para empezar a mostrar el movimiento.
      _receivedStreamLocation = false;
      _subscribeLocations(shiftId, generation);
      await ref
          .read(trackingQueueCoordinatorProvider)
          .flushAll(maximumBatchSize: _configuration.maximumBatchSize);
      if (!mounted || generation != _generation || _shiftId != shiftId) return;
      _restartSendTimer(shiftId);
      if (!_receivedStreamLocation) {
        final firstLocation = await ref
            .read(deviceLocationServiceProvider)
            .getCurrentLocation();
        if (!mounted || generation != _generation || _shiftId != shiftId) {
          return;
        }
        // Una lectura puntual tardía no debe mover el marcador hacia atrás.
        if (!_receivedStreamLocation) {
          await _processLocation(shiftId, firstLocation, force: true);
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
      _captureAllowed = false;
      unawaited(_locationSubscription?.cancel());
      _locationSubscription = null;
      return;
    }
    ref
        .read(driverTrackingStatusProvider.notifier)
        .setCurrentLocation(location);
    final moving = (location.speedMetersPerSecond ?? 0) >= 0.7;
    final cadence = Duration(
      seconds: _nearby && (_nearbyPolicy?.appliesStopped == true || moving)
          ? _effectiveCaptureSeconds
          : moving
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

  int get _effectiveCaptureSeconds => _nearby && _nearbyPolicy != null
      ? _configuration.movingCaptureSeconds < _nearbyPolicy!.captureSeconds
            ? _configuration.movingCaptureSeconds
            : _nearbyPolicy!.captureSeconds
      : _configuration.movingCaptureSeconds;

  int get _effectiveSendSeconds => _nearby && _nearbyPolicy != null
      ? _configuration.sendIntervalSeconds < _nearbyPolicy!.sendSeconds
            ? _configuration.sendIntervalSeconds
            : _nearbyPolicy!.sendSeconds
      : _configuration.sendIntervalSeconds;

  void _subscribeLocations(String shiftId, int generation) {
    final seconds = _effectiveCaptureSeconds;
    _streamCaptureSeconds = seconds;
    _locationSubscription = ref
        .read(deviceLocationServiceProvider)
        .watchLocations(interval: Duration(seconds: seconds))
        .listen(
          (location) {
            if (!mounted || generation != _generation) return;
            _receivedStreamLocation = true;
            unawaited(_processLocation(shiftId, location));
          },
          onError: (Object error) {
            if (!mounted || generation != _generation) return;
            ref
                .read(driverTrackingStatusProvider.notifier)
                .reportError(
                  error is AppFailure
                      ? error.message
                      : 'No fue posible continuar el seguimiento GPS.',
                );
          },
        );
  }

  Future<void> _processLocation(
    String shiftId,
    DeviceLocation location, {
    bool force = false,
  }) async {
    _lastLocation = location;
    final entered = _evaluateNearby(location);
    await _capture(shiftId, location, force: force || entered);
    if (!mounted || _shiftId != shiftId || !entered) return;
    if (_nearbyPolicy?.sendOnEntry == true) {
      unawaited(_captureFreshNearby(shiftId, _generation));
    }
  }

  Future<void> _captureFreshNearby(String shiftId, int generation) async {
    try {
      final fresh = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      if (!mounted ||
          generation != _generation ||
          !_nearby ||
          _shiftId != shiftId) {
        return;
      }
      _lastLocation = fresh;
      _evaluateNearby(fresh);
      if (_nearby) await _capture(shiftId, fresh, force: true);
    } on Object {
      // The location stream and queued points remain active if a single fix fails.
    }
  }

  void _updateNearbyPolicy(NearbyCapturePolicy? policy) {
    final nextKey = policy?.isUsable == true ? policy!.target!.key : null;
    if (_objectiveKey == nextKey && identical(_nearbyPolicy, policy)) return;
    final changedObjective = _objectiveKey != nextKey;
    _objectiveKey = nextKey;
    _nearbyPolicy = nextKey == null ? null : policy;
    if (changedObjective) _setNearby(false);
    if (_lastLocation case final location?) {
      final entered = _evaluateNearby(location);
      final shiftId = _shiftId;
      if (entered && shiftId != null) {
        unawaited(_captureFreshNearby(shiftId, _generation));
      }
    }
  }

  bool _evaluateNearby(DeviceLocation location) {
    final policy = _nearbyPolicy;
    final next =
        policy?.shouldBeNearby(
          location.latitude,
          location.longitude,
          wasNearby: _nearby,
        ) ??
        false;
    if (next == _nearby) return false;
    _setNearby(next);
    return next;
  }

  void _setNearby(bool value) {
    if (_nearby == value) return;
    _nearby = value;
    final shiftId = _shiftId;
    if (shiftId == null || !_captureAllowed) return;
    _restartSendTimer(shiftId);
    if (_locationSubscription != null &&
        _streamCaptureSeconds != _effectiveCaptureSeconds) {
      final generation = _generation;
      final token = ++_streamRestartToken;
      unawaited(_restartLocationStream(shiftId, generation, token));
    }
    if (value && _nearbyPolicy?.sendOnEntry == true) {
      unawaited(_flush(shiftId));
    }
  }

  Future<void> _restartLocationStream(
    String shiftId,
    int generation,
    int token,
  ) async {
    await _locationSubscription?.cancel();
    if (!mounted ||
        generation != _generation ||
        token != _streamRestartToken ||
        _shiftId != shiftId ||
        !_captureAllowed) {
      return;
    }
    _subscribeLocations(shiftId, generation);
  }

  void _restartSendTimer(String shiftId) {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(
      Duration(seconds: _effectiveSendSeconds),
      (_) => unawaited(_flush(shiftId)),
    );
  }

  Future<void> _flush(String shiftId) async {
    if (_sending) {
      _flushRequested = true;
      return;
    }
    if (_retryBlockedByValidation || _shiftId != shiftId) return;
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
      final flushAgain = _flushRequested;
      _flushRequested = false;
      if (flushAgain &&
          mounted &&
          _shiftId == shiftId &&
          !_retryBlockedByValidation) {
        unawaited(_flush(shiftId));
      }
    }
  }

  Future<bool> _refreshConfiguration() async {
    ref.invalidate(trackingConfigurationProvider);
    try {
      final previouslyEnabled = _configuration.nearbyCapture?.enabled == true;
      _configuration = await ref.read(trackingConfigurationProvider.future);
      if (mounted &&
          previouslyEnabled !=
              (_configuration.nearbyCapture?.enabled == true)) {
        setState(() {});
      }
      if (_shiftId case final shiftId?) {
        final policy = _configuration.shiftTracking;
        if (policy != null) {
          _captureAllowed = policy.permitsCaptureFor(shiftId);
          _scheduledCloseAt = policy.scheduledCloseAt;
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _refreshReferenceAndFlush(String shiftId) async {
    await _refreshConfiguration();
    if (!mounted || _shiftId != shiftId) return;
    if (!_captureAllowed) {
      unawaited(_locationSubscription?.cancel());
      _locationSubscription = null;
    }
    await _flush(shiftId);
    if (!_captureAllowed && mounted && _shiftId == shiftId) _stop();
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
    _flushRequested = false;
    _nearby = false;
    _nearbyPolicy = null;
    _objectiveKey = null;
    _lastLocation = null;
    _streamCaptureSeconds = null;
    _streamRestartToken++;
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
