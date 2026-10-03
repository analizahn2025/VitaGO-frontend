import 'package:vitago_app/features/notifications/models/driver_notification.dart';

abstract interface class NotificationsRepository {
  Future<DriverNotificationFeed> getNotifications();

  Future<int> getUnreadCount();

  Future<DriverNotification> markRead(String notificationId);
}
