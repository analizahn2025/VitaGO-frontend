import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/controllers/tracking_controller.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
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
  final _uuid = const Uuid();
  Timer? _timer;
  TrackingPointInput? _pendingPoint;
  String? _shiftId;
  bool _sending = false;
  bool? _lastGpsEnabled;
  bool _gpsDialogOpen = false;

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
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
      if (!mounted) return;
      _synchronize(shift?.id, gpsEnabled);
    });
    return widget.child;
  }

  void _synchronize(String? shiftId, bool gpsEnabled) {
    if (widget.enabled && shiftId != null && gpsEnabled) {
      if (_timer == null || _shiftId != shiftId) _start(shiftId);
      return;
    }
    _stop();
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

  void _start(String shiftId) {
    _timer?.cancel();
    if (_shiftId != shiftId) _pendingPoint = null;
    _shiftId = shiftId;
    ref.read(driverTrackingStatusProvider.notifier).setActive(true);
    unawaited(_send(shiftId));
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_send(shiftId));
    });
  }

  void _stop() {
    if (_timer == null && _shiftId == null) return;
    _timer?.cancel();
    _timer = null;
    _shiftId = null;
    _pendingPoint = null;
    ref.read(driverTrackingStatusProvider.notifier).setActive(false);
  }

  Future<void> _send(String shiftId) async {
    if (_sending) return;
    _sending = true;
    ref.read(driverTrackingStatusProvider.notifier).setSending(true);
    try {
      var point = _pendingPoint;
      if (point == null) {
        final location = await ref
            .read(deviceLocationServiceProvider)
            .getCurrentLocation();
        point = TrackingPointInput(
          clientId: _uuid.v4(),
          latitude: location.latitudeText,
          longitude: location.longitudeText,
          accuracyMeters: location.accuracyMeters?.toStringAsFixed(2),
          speedMetersPerSecond: location.speedMetersPerSecond?.toStringAsFixed(
            3,
          ),
          headingDegrees: location.headingDegrees
              ?.clamp(0, 359.99)
              .toStringAsFixed(2),
          recordedAt: location.recordedAt,
        );
        _pendingPoint = point;
      }
      await ref
          .read(trackingActionsControllerProvider)
          .register(TrackingBatchInput(shiftId: shiftId, points: [point]));
      _pendingPoint = null;
      if (_shiftId != shiftId) return;
      ref
          .read(driverTrackingStatusProvider.notifier)
          .markSynced(DateTime.now());
    } on AppFailure catch (failure) {
      ref
          .read(driverTrackingStatusProvider.notifier)
          .reportError(failure.message);
    } finally {
      _sending = false;
      ref.read(driverTrackingStatusProvider.notifier).setSending(false);
    }
  }
}
