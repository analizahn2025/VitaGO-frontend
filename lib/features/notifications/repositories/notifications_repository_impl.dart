import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';
import 'package:vitago_app/features/notifications/services/notifications_api_service.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._apiService);

  final NotificationsApiService _apiService;

  @override
  Future<DriverNotificationFeed> getNotifications() {
    return _apiService.getNotifications();
  }

  @override
  Future<int> getUnreadCount() => _apiService.getUnreadCount();

  @override
  Future<DriverNotification> markRead(String notificationId) {
    return _apiService.markRead(notificationId);
  }
}
