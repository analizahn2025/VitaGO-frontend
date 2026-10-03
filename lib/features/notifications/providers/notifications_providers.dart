import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/providers/auth_providers.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository_impl.dart';
import 'package:vitago_app/features/notifications/services/notifications_api_service.dart';

final notificationsApiServiceProvider = Provider<NotificationsApiService>((
  ref,
) {
  return NotificationsApiService(ref.watch(apiClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(
    ref.watch(notificationsApiServiceProvider),
  );
});
