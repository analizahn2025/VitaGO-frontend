import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';

class DriverAlertsButton extends ConsumerWidget {
  const DriverAlertsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(driverDeliveryControllerProvider).value;
    final shift = ref.watch(activeShiftControllerProvider).value;
    final driver = ref.watch(ownDriverProfileControllerProvider).value;
    final notifications = ref.watch(driverNotificationsControllerProvider);
    final unreadCount = ref.watch(unreadNotificationCountControllerProvider);
    final remoteNotifications =
        notifications.value?.items
            .where((notification) => !notification.isRead)
            .toList(growable: false) ??
        const <DriverNotification>[];
    final remotelyNotifiedRequests = remoteNotifications
        .map((notification) => notification.requestId)
        .whereType<String>()
        .toSet();
    final remoteAlerts = <_DriverAlert>[
      for (final notification in remoteNotifications)
        _DriverAlert(
          icon: _notificationIcon(notification.type),
          title: notification.title,
          message: notification.message,
          important: notification.isImportant,
          notificationId: notification.id,
          requestId: notification.requestId,
        ),
    ];
    final localAlerts = <_DriverAlert>[
      if (board != null && shift == null && board.inProgress.isNotEmpty)
        const _DriverAlert(
          icon: Icons.play_circle_outline,
          title: 'Inicia tu jornada',
          message: 'Tienes servicios asignados para atender.',
        ),
      if (driver != null && driver.vehicle?.status != 'ACTIVO')
        const _DriverAlert(
          icon: Icons.two_wheeler_outlined,
          title: 'Motocicleta no disponible',
          message: 'Solicita que revisen la motocicleta asignada.',
          important: true,
        ),
      if (board != null)
        for (final request in board.inProgress)
          if (!remotelyNotifiedRequests.contains(request.id))
            _DriverAlert(
              icon: request.isPriority
                  ? Icons.priority_high
                  : Icons.inventory_2_outlined,
              title: request.isPriority
                  ? 'Servicio prioritario'
                  : 'Servicio asignado',
              message:
                  '${request.number}: ${request.origin.name} hacia ${request.destinationName}',
              important: request.isPriority,
              requestId: request.id,
            ),
    ];
    final alerts = [...remoteAlerts, ...localAlerts];
    final officialUnreadCount = unreadCount.value ?? remoteNotifications.length;
    final badgeCount = officialUnreadCount + localAlerts.length;

    final semanticLabel = badgeCount == 0
        ? 'Avisos, ninguno pendiente'
        : 'Avisos, $badgeCount pendientes';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: () => _showAlerts(
            context,
            ref,
            alerts,
            loading: notifications.isLoading || unreadCount.isLoading,
            loadError: notifications.hasError || unreadCount.hasError,
          ),
          tooltip: semanticLabel,
          icon: Badge(
            isLabelVisible: badgeCount > 0,
            label: Text(badgeCount > 9 ? '9+' : badgeCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains('PRIORIT')) return Icons.priority_high;
    if (normalized.contains('ASIGN')) {
      return Icons.assignment_turned_in_outlined;
    }
    if (normalized.contains('CANCEL')) return Icons.cancel_outlined;
    return Icons.notifications_active_outlined;
  }

  Future<void> _showAlerts(
    BuildContext parentContext,
    WidgetRef ref,
    List<_DriverAlert> alerts, {
    required bool loading,
    required bool loadError,
  }) {
    return showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Avisos', style: Theme.of(context).textTheme.titleLarge),
              if (loading) ...[
                const SizedBox(height: AppSpacing.sm),
                const LinearProgressIndicator(),
              ] else if (loadError) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No fue posible actualizar los avisos del servidor.',
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_outlined, size: 42),
                      SizedBox(height: AppSpacing.sm),
                      Text('No tienes avisos pendientes.'),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final colors = Theme.of(context).colorScheme;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: alert.isActionable
                            ? () => unawaited(
                                _openAlert(parentContext, context, ref, alert),
                              )
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: alert.important
                              ? colors.errorContainer
                              : colors.primaryContainer,
                          foregroundColor: alert.important
                              ? colors.onErrorContainer
                              : colors.onPrimaryContainer,
                          child: Icon(alert.icon),
                        ),
                        title: Text(alert.title),
                        subtitle: Text(alert.message),
                        trailing: alert.requestId == null
                            ? null
                            : const Icon(Icons.chevron_right),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAlert(
    BuildContext parentContext,
    BuildContext sheetContext,
    WidgetRef ref,
    _DriverAlert alert,
  ) async {
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(Duration.zero);
    if (!parentContext.mounted) return;

    final navigation = alert.requestId == null
        ? null
        : parentContext.pushNamed<void>(
            'request-detail',
            pathParameters: {'requestId': alert.requestId!},
          );

    if (alert.notificationId != null) {
      try {
        await ref
            .read(notificationActionsControllerProvider)
            .markRead(alert.notificationId!);
      } on AppFailure catch (failure) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext)
              .showSnackBar(SnackBar(content: Text(failure.message)));
        }
      } finally {
        ref.invalidate(driverNotificationsControllerProvider);
        ref.invalidate(unreadNotificationCountControllerProvider);
      }
    }

    if (navigation != null) await navigation;
  }
}

class _DriverAlert {
  const _DriverAlert({
    required this.icon,
    required this.title,
    required this.message,
    this.important = false,
    this.notificationId,
    this.requestId,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool important;
  final String? notificationId;
  final String? requestId;

  bool get isActionable => notificationId != null || requestId != null;
}
