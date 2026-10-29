import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/models/notification_seen_state.dart';
import 'package:vitago_app/features/notifications/storage/notification_seen_store.dart';

final notificationSeenControllerProvider = AsyncNotifierProvider.autoDispose
    .family<NotificationSeenController, NotificationSeenState, String>(
      NotificationSeenController.new,
    );

class NotificationSeenController extends AsyncNotifier<NotificationSeenState> {
  NotificationSeenController(this.ownerKey);
  final String ownerKey;
  Future<void> _tail = Future.value();

  @override
  Future<NotificationSeenState> build() async {
    try {
      return await ref.watch(notificationSeenStoreProvider).load(ownerKey);
    } on Object {
      debugPrint('[VitaGo] notifications: unable to restore seen state');
      return const NotificationSeenState();
    }
  }

  Future<void> acknowledge(Iterable<DriverNotification> items) {
    final snapshot = List<DriverNotification>.of(items);
    _tail = _tail.then((_) async {
      if (!ref.mounted) return;
      late final NotificationSeenState previous;
      try {
        previous = await future;
      } on Object {
        if (!ref.mounted) return;
        rethrow;
      }
      if (!ref.mounted) return;
      final updated = previous.acknowledge(snapshot);
      state = AsyncData(updated);
      try {
        await ref.read(notificationSeenStoreProvider).save(ownerKey, updated);
      } on Object {
        // Keep the immediate, in-session acknowledgement if storage is unavailable.
        debugPrint('[VitaGo] notifications: unable to persist seen state');
      }
    });
    return _tail;
  }
}
