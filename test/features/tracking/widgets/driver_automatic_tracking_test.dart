import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/models/tracking_point.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';
import 'package:vitago_app/features/tracking/widgets/driver_automatic_tracking.dart';

void main() {
  testWidgets('después del corte no captura nuevos puntos y conserva la cola', (
    tester,
  ) async {
    var elapsed = Duration.zero;
    final clock = ServerTimeClock.withElapsedReader(() => elapsed);
    final service = _LocationService();
    final queue = _QueueCoordinator();
    addTearDown(service.locations.close);
    final shift = DriverShift.fromJson({
      'id': 'shift-id',
      'repartidor_id': 'driver-id',
      'estado': 'ACTIVA',
      'iniciada_en': _serverTime.toIso8601String(),
      'cierre_programado_en': _serverTime
          .add(const Duration(seconds: 5))
          .toIso8601String(),
      'puede_operar': true,
      'creado_en': _serverTime.toIso8601String(),
      'actualizado_en': _serverTime.toIso8601String(),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeShiftControllerProvider.overrideWith((ref) async => shift),
          locationServiceEnabledProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
          deviceLocationServiceProvider.overrideWithValue(service),
          serverTimeClockProvider.overrideWithValue(clock),
          trackingRepositoryProvider.overrideWithValue(_TrackingRepository()),
          trackingQueueCoordinatorProvider.overrideWithValue(queue),
        ],
        child: const MaterialApp(
          home: DriverAutomaticTracking(enabled: true, child: SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(queue.captured.length, 1);
    elapsed = const Duration(seconds: 6);
    final afterCut = _location(2, latitude: 14.0733);
    service.locations.add(afterCut);
    await tester.pump();
    expect(queue.captured.length, 1);
    expect(service.locations.hasListener, isTrue);
    expect(queue.flushCalls, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'captura cada 5/15 segundos y conserva el stream en segundo plano',
    (tester) async {
      var elapsed = Duration.zero;
      final clock = ServerTimeClock.withElapsedReader(() => elapsed);
      final locationService = _LocationService();
      final queue = _QueueCoordinator();
      addTearDown(locationService.locations.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeShiftControllerProvider.overrideWith((ref) async => _shift),
            locationServiceEnabledProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            deviceLocationServiceProvider.overrideWithValue(locationService),
            serverTimeClockProvider.overrideWithValue(clock),
            trackingRepositoryProvider.overrideWithValue(_TrackingRepository()),
            trackingQueueCoordinatorProvider.overrideWithValue(queue),
          ],
          child: const MaterialApp(
            home: DriverAutomaticTracking(enabled: true, child: SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DriverAutomaticTracking)),
      );
      expect(locationService.interval, const Duration(seconds: 5));
      expect(queue.captured.length, 1);

      Future<void> emitAt(int seconds, {double speed = 0}) async {
        elapsed = Duration(seconds: seconds);
        final location = _location(speed, latitude: 14.0723 + seconds / 10000);
        locationService.locations.add(location);
        await tester.pump();
        // El marcador recibe también posiciones que no se encolan por cadencia.
        expect(
          container.read(driverTrackingStatusProvider).lastLocation,
          location,
        );
      }

      await emitAt(5);
      await emitAt(10);
      expect(queue.captured.length, 1);
      await emitAt(15);
      expect(queue.captured.length, 2);
      await emitAt(19, speed: 2);
      expect(queue.captured.length, 2);
      await emitAt(20, speed: 2);
      expect(queue.captured.length, 3);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await emitAt(25, speed: 2);
      await emitAt(30);
      expect(queue.captured.length, 4);
      await emitAt(40);

      expect(
        queue.captured.map(
          (point) => point.recordedAt.difference(_serverTime).inSeconds,
        ),
        [0, 15, 20, 25, 40],
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets('actualiza la posición mientras espera reenviar la cola', (
    tester,
  ) async {
    final restore = Completer<void>();
    final service = _LocationService();
    final queue = _QueueCoordinator(restore: restore.future);
    addTearDown(service.locations.close);
    final container = await _mountTracking(tester, service, queue);

    expect(service.interval, const Duration(seconds: 5));
    final live = _location(2, latitude: 14.0733);
    service.locations.add(live);
    await tester.pump();
    expect(container.read(driverTrackingStatusProvider).lastLocation, live);
    expect(queue.captured.single.latitude, live.latitudeText);
    expect(queue.flushCalls, 0);

    restore.complete();
    await tester.pumpAndSettle();
    expect(queue.flushCalls, 1);
    expect(service.currentLocationCalls, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('una lectura inicial tardía no reemplaza la posición en vivo', (
    tester,
  ) async {
    final initial = Completer<DeviceLocation>();
    final service = _LocationService(firstLocation: initial.future);
    final queue = _QueueCoordinator();
    addTearDown(service.locations.close);
    final container = await _mountTracking(tester, service, queue);
    expect(service.currentLocationCalls, 1);

    final live = _location(2, latitude: 14.0733);
    service.locations.add(live);
    await tester.pump();
    initial.complete(_location(0));
    await tester.pumpAndSettle();

    expect(container.read(driverTrackingStatusProvider).lastLocation, live);
    expect(queue.captured.single.latitude, live.latitudeText);
    expect(queue.flushCalls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el stream y el envío continúan si falla la lectura puntual', (
    tester,
  ) async {
    final initial = Completer<DeviceLocation>();
    final service = _LocationService(firstLocation: initial.future);
    final queue = _QueueCoordinator();
    addTearDown(service.locations.close);
    final container = await _mountTracking(tester, service, queue);
    initial.completeError(
      const AppFailure(message: 'La ubicación tardó demasiado.'),
    );
    await tester.pumpAndSettle();

    final live = _location(2, latitude: 14.0733);
    service.locations.add(live);
    await tester.pump();
    expect(container.read(driverTrackingStatusProvider).lastLocation, live);
    expect(queue.captured.single.latitude, live.latitudeText);
    await tester.pump(const Duration(seconds: 20));
    expect(queue.flushCalls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no reinicia la captura al terminar un reenvío ya desmontado', (
    tester,
  ) async {
    final restore = Completer<void>();
    final service = _LocationService();
    final queue = _QueueCoordinator(restore: restore.future);
    addTearDown(service.locations.close);
    await _mountTracking(tester, service, queue);
    expect(service.locations.hasListener, isTrue);

    await tester.pumpWidget(const SizedBox());
    restore.complete();
    await tester.pumpAndSettle();
    expect(service.locations.hasListener, isFalse);
    expect(service.currentLocationCalls, 0);
    expect(queue.flushCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<ProviderContainer> _mountTracking(
  WidgetTester tester,
  _LocationService service,
  _QueueCoordinator queue,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeShiftControllerProvider.overrideWith((ref) async => _shift),
        locationServiceEnabledProvider.overrideWith(
          (ref) => Stream.value(true),
        ),
        deviceLocationServiceProvider.overrideWithValue(service),
        serverTimeClockProvider.overrideWithValue(
          ServerTimeClock.withElapsedReader(() => Duration.zero),
        ),
        trackingRepositoryProvider.overrideWithValue(_TrackingRepository()),
        trackingQueueCoordinatorProvider.overrideWithValue(queue),
      ],
      child: const MaterialApp(
        home: DriverAutomaticTracking(enabled: true, child: SizedBox()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(DriverAutomaticTracking)),
  );
}

final _serverTime = DateTime.utc(2026, 10, 22, 18);
final _shift = DriverShift.fromJson({
  'id': 'shift-id',
  'repartidor_id': 'driver-id',
  'estado': 'ACTIVA',
  'iniciada_en': _serverTime.toIso8601String(),
  'creado_en': _serverTime.toIso8601String(),
  'actualizado_en': _serverTime.toIso8601String(),
});

DeviceLocation _location(double speed, {double latitude = 14.0723}) =>
    DeviceLocation(
      latitude: latitude,
      longitude: -87.1921,
      recordedAt: DateTime.utc(2000),
      speedMetersPerSecond: speed,
      accuracyMeters: 5,
    );

class _LocationService extends DeviceLocationService {
  _LocationService({this.firstLocation});

  final Future<DeviceLocation>? firstLocation;
  final locations = StreamController<DeviceLocation>();
  Duration? interval;
  int currentLocationCalls = 0;

  @override
  Future<void> ensurePermission() async {}

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    currentLocationCalls++;
    return firstLocation ?? _location(0);
  }

  @override
  Stream<DeviceLocation> watchLocations({required Duration interval}) {
    this.interval = interval;
    return locations.stream;
  }
}

class _TrackingRepository implements TrackingRepository {
  @override
  Future<TrackingConfiguration> getConfiguration() async =>
      TrackingConfiguration(
        serverTime: _serverTime,
        operationalTimeZone: 'America/Tegucigalpa',
        movingCaptureSeconds: 5,
        stoppedCaptureSeconds: 15,
        sendIntervalSeconds: 20,
        maximumBatchSize: 200,
        maximumAssignmentAgeSeconds: 120,
        maximumAssignmentAccuracyMeters: 50,
        assignmentRequiresCurrentGps: true,
        maximumMeasurementIntervalSeconds: 30,
        minimumCoveragePercentage: 90,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueueCoordinator implements TrackingQueueCoordinator {
  _QueueCoordinator({this.restore});

  final Future<void>? restore;
  final captured = <TrackingPointInput>[];
  int flushCalls = 0;

  @override
  Future<TrackingPointInput> capture(
    String shiftId,
    DeviceLocation location, {
    DateTime? recordedAt,
  }) async {
    final point = TrackingPointInput(
      clientId: 'point-${captured.length + 1}',
      latitude: location.latitudeText,
      longitude: location.longitudeText,
      recordedAt: recordedAt!,
    );
    captured.add(point);
    return point;
  }

  @override
  Future<void> flushAll({required int maximumBatchSize}) async {
    await restore;
  }

  @override
  Future<int> flush(String shiftId, {required int maximumBatchSize}) async {
    flushCalls++;
    return 0;
  }

  @override
  Future<int> pendingCount(String shiftId) async => captured.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
