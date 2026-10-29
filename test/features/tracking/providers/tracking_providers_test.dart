import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/time/server_time_clock.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';

void main() {
  test(
    'conserva y ancla la configuración horaria obtenida del servidor',
    () async {
      var elapsed = const Duration(seconds: 10);
      final clock = ServerTimeClock.withElapsedReader(() => elapsed);
      final container = ProviderContainer(
        overrides: [
          serverTimeClockProvider.overrideWithValue(clock),
          trackingRepositoryProvider.overrideWithValue(
            _TrackingRepository(_configuration),
          ),
        ],
      );
      addTearDown(container.dispose);

      final configuration = await container.read(
        trackingConfigurationProvider.future,
      );
      elapsed = const Duration(seconds: 17);

      expect(configuration.serverTime, DateTime.parse('2026-10-21T20:00:00Z'));
      expect(clock.isSynchronized, isTrue);
      expect(clock.currentUtc(), DateTime.parse('2026-10-21T20:00:07Z'));
      expect(clock.operationalTimeZone, 'America/Tegucigalpa');
    },
  );
}

const _configuration = TrackingConfiguration(
  serverTime: null,
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

class _TrackingRepository implements TrackingRepository {
  const _TrackingRepository(this.configuration);

  final TrackingConfiguration configuration;

  @override
  Future<TrackingConfiguration> getConfiguration() async {
    await Future<void>.delayed(Duration.zero);
    return TrackingConfiguration(
      serverTime: DateTime.parse('2026-10-21T20:00:00Z'),
      operationalTimeZone: configuration.operationalTimeZone,
      movingCaptureSeconds: configuration.movingCaptureSeconds,
      stoppedCaptureSeconds: configuration.stoppedCaptureSeconds,
      sendIntervalSeconds: configuration.sendIntervalSeconds,
      maximumBatchSize: configuration.maximumBatchSize,
      maximumAssignmentAgeSeconds: configuration.maximumAssignmentAgeSeconds,
      maximumAssignmentAccuracyMeters:
          configuration.maximumAssignmentAccuracyMeters,
      assignmentRequiresCurrentGps: configuration.assignmentRequiresCurrentGps,
      maximumMeasurementIntervalSeconds:
          configuration.maximumMeasurementIntervalSeconds,
      minimumCoveragePercentage: configuration.minimumCoveragePercentage,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
