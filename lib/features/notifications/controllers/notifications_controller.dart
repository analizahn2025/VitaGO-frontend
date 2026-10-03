import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/providers/notifications_providers.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';

final driverNotificationsControllerProvider =
    FutureProvider.autoDispose<DriverNotificationFeed>((ref) {
      return ref.watch(notificationsRepositoryProvider).getNotifications();
    });

final unreadNotificationCountControllerProvider =
    FutureProvider.autoDispose<int>((ref) {
      return ref.watch(notificationsRepositoryProvider).getUnreadCount();
    });

final notificationActionsControllerProvider =
    Provider<NotificationActionsController>((ref) {
      return NotificationActionsController(
        ref.watch(notificationsRepositoryProvider),
      );
    });

class NotificationActionsController {
  const NotificationActionsController(this._repository);

  final NotificationsRepository _repository;

  Future<DriverNotification> markRead(String notificationId) {
    return _repository.markRead(notificationId);
  }
}
