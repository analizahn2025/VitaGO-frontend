import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository_impl.dart';
import 'package:vitago_app/features/tracking/services/tracking_api_service.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';
import 'package:vitago_app/features/tracking/services/tracking_queue_coordinator.dart';
import 'package:vitago_app/features/tracking/storage/tracking_queue_store.dart';

final deviceLocationServiceProvider = Provider<DeviceLocationService>((ref) {
  return const DeviceLocationService();
});

final locationServiceEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(deviceLocationServiceProvider).watchServiceEnabled();
});

final trackingApiServiceProvider = Provider<TrackingApiService>((ref) {
  return TrackingApiService(ref.watch(apiClientProvider));
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(ref.watch(trackingApiServiceProvider));
});

final trackingConfigurationProvider =
    FutureProvider.autoDispose<TrackingConfiguration>((ref) async {
      return ref.watch(trackingRepositoryProvider).getConfiguration();
    });

final trackingQueueStoreProvider = Provider<TrackingQueueStore>((ref) {
  return FileTrackingQueueStore();
});

final trackingQueueCoordinatorProvider = Provider<TrackingQueueCoordinator>((
  ref,
) {
  return TrackingQueueCoordinator(
    ref.watch(trackingQueueStoreProvider),
    ref.watch(trackingRepositoryProvider),
  );
});
