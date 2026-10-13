import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

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
  bool? _lastGpsEnabled;
  bool _gpsDialogOpen = false;
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
      if (_shiftId case final shiftId?) unawaited(_flush(shiftId));
    }
    // No detener el stream al abrir Maps, bloquear la pantalla o pasar a
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
      try {
        _configuration = await ref.read(trackingConfigurationProvider.future);
      } on Object {
        _configuration = TrackingConfiguration.defaults;
      }
      await ref.read(deviceLocationServiceProvider).ensurePermission();
      if (!mounted || generation != _generation || _shiftId != shiftId) return;

      await ref
          .read(trackingQueueCoordinatorProvider)
          .flushAll(maximumBatchSize: _configuration.maximumBatchSize);
      final firstLocation = await ref
          .read(deviceLocationServiceProvider)
          .getCurrentLocation();
      await _capture(shiftId, firstLocation, force: true);

      _locationSubscription = ref
          .read(deviceLocationServiceProvider)
          .watchLocations(
            interval: Duration(seconds: _configuration.movingCaptureSeconds),
          )
          .listen(
            (location) => unawaited(_capture(shiftId, location)),
            onError: (Object error) {
              status.reportError(
                error is AppFailure
                    ? error.message
                    : 'No fue posible continuar el seguimiento GPS.',
              );
            },
          );
      _sendTimer = Timer.periodic(
        Duration(seconds: _configuration.sendIntervalSeconds),
        (_) => unawaited(_flush(shiftId)),
      );
    } on AppFailure catch (failure) {
      status.reportError(failure.message);
    } finally {
      _starting = false;
    }
  }

  Future<void> _capture(
    String shiftId,
    DeviceLocation location, {
    bool force = false,
  }) async {
    if (_shiftId != shiftId) return;
    final moving = (location.speedMetersPerSecond ?? 0) >= 0.7;
    final cadence = Duration(
      seconds: moving
          ? _configuration.movingCaptureSeconds
          : _configuration.stoppedCaptureSeconds,
    );
    if (!force &&
        _lastCapturedAt != null &&
        location.recordedAt.difference(_lastCapturedAt!).abs() < cadence) {
      return;
    }
    await ref.read(trackingQueueCoordinatorProvider).capture(shiftId, location);
    _lastCapturedAt = location.recordedAt;
    final pending = await ref
        .read(trackingQueueCoordinatorProvider)
        .pendingCount(shiftId);
    ref.read(driverTrackingStatusProvider.notifier).setPendingPoints(pending);
    if (force) await _flush(shiftId);
  }

  Future<void> _flush(String shiftId) async {
    if (_sending || _shiftId != shiftId) return;
    _sending = true;
    final status = ref.read(driverTrackingStatusProvider.notifier);
    status.setSending(true);
    try {
      await ref
          .read(trackingQueueCoordinatorProvider)
          .flush(shiftId, maximumBatchSize: _configuration.maximumBatchSize);
      final pending = await ref
          .read(trackingQueueCoordinatorProvider)
          .pendingCount(shiftId);
      status.markSynced(DateTime.now(), pendingPoints: pending);
    } on AppFailure catch (failure) {
      final pending = await ref
          .read(trackingQueueCoordinatorProvider)
          .pendingCount(shiftId);
      status.setPendingPoints(pending);
      status.reportError(
        '$pending punto${pending == 1 ? '' : 's'} guardado${pending == 1 ? '' : 's'} para reenviar. ${failure.message}',
      );
    } finally {
      _sending = false;
      status.setSending(false);
    }
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
