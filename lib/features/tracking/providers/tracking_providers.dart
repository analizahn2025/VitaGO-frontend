import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository.dart';
import 'package:vitago_app/features/tracking/repositories/tracking_repository_impl.dart';
import 'package:vitago_app/features/tracking/services/tracking_api_service.dart';

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
