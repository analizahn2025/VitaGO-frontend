import 'package:vitago_app/features/notifications/models/notification_seen_state.dart';
import 'package:vitago_app/features/notifications/storage/notification_seen_store.dart';

class MemoryNotificationSeenStore implements NotificationSeenStore {
  final values = <String, NotificationSeenState>{};

  @override
  Future<NotificationSeenState> load(String ownerKey) async =>
      values[ownerKey] ?? const NotificationSeenState();

  @override
  Future<void> save(String ownerKey, NotificationSeenState value) async {
    values[ownerKey] = NotificationSeenState.fromJson(value.toJson());
  }
}
