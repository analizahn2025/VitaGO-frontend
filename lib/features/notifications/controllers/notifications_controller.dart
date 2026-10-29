import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/providers/notifications_providers.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';
import 'package:vitago_app/core/errors/app_failure.dart';

final driverNotificationsControllerProvider =
    FutureProvider.autoDispose<DriverNotificationFeed>(
      (ref) => ref.watch(notificationsRepositoryProvider).getNotifications(),
      retry: (_, _) => null,
    );

final unreadNotificationCountControllerProvider =
    FutureProvider.autoDispose<int>(
      (ref) => ref.watch(notificationsRepositoryProvider).getUnreadCount(),
      retry: (_, _) => null,
    );

final unavailableNotificationIdsProvider =
    NotifierProvider<UnavailableNotificationIds, Set<String>>(
      UnavailableNotificationIds.new,
    );

class UnavailableNotificationIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void removeFromCache(String id) {
    final ids = {...state, id};
    state = Set.unmodifiable(ids.skip(ids.length > 512 ? ids.length - 512 : 0));
  }
}

final notificationActionsControllerProvider =
    Provider<NotificationActionsController>((ref) {
      return NotificationActionsController(
        ref.watch(notificationsRepositoryProvider),
        onUnavailable: (id) {
          if (ref.mounted) {
            ref
                .read(unavailableNotificationIdsProvider.notifier)
                .removeFromCache(id);
          }
        },
      );
    });

class NotificationActionsController {
  const NotificationActionsController(this._repository, {this.onUnavailable});

  final NotificationsRepository _repository;
  final void Function(String)? onUnavailable;

  Future<DriverNotification> markRead(String notificationId) async {
    try {
      return await _repository.markRead(notificationId);
    } on AppFailure catch (failure) {
      if (failure.statusCode == 404) onUnavailable?.call(notificationId);
      rethrow;
    }
  }
}
