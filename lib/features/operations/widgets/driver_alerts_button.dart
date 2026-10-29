import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/notifications/controllers/notification_seen_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';

class DriverAlertsButton extends ConsumerStatefulWidget {
  const DriverAlertsButton({required this.ownerKey, super.key});
  final String ownerKey;
  @override
  ConsumerState<DriverAlertsButton> createState() => _DriverAlertsButtonState();
}

class _DriverAlertsButtonState extends ConsumerState<DriverAlertsButton>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isResumed = true;
  bool _sheetOpen = false;
  bool _recoverAfterSync = false;

  @override
  void initState() {
    super.initState();
    _isResumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _scheduleRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasResumed = _isResumed;
    _isResumed = state == AppLifecycleState.resumed;
    _scheduleRefresh();
    if (!wasResumed && _isResumed) _refresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = _isResumed
        ? Timer.periodic(const Duration(minutes: 1), (_) => _refresh())
        : null;
  }

  void _refresh() {
    if (!mounted || !_isResumed) return;
    // The server decides daily validity, never the phone's date/time zone.
    if (!ref.read(driverNotificationsControllerProvider).isLoading) {
      ref.invalidate(driverNotificationsControllerProvider);
    }
    if (!ref.read(unreadNotificationCountControllerProvider).isLoading) {
      ref.invalidate(unreadNotificationCountControllerProvider);
    }
    if (!ref.read(driverDeliveryControllerProvider).isLoading) {
      ref.invalidate(driverDeliveryControllerProvider);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverNotificationsControllerProvider, (_, next) {
      if (_sheetOpen && !next.isLoading && !next.hasError && next.hasValue) {
        unawaited(
          ref
              .read(
                notificationSeenControllerProvider(widget.ownerKey).notifier,
              )
              .acknowledge(next.value!.items),
        );
      }
    });
    ref.listen(driverTrackingStatusProvider, (previous, next) {
      if (next.error != null) _recoverAfterSync = true;
      if (_recoverAfterSync &&
          next.lastSyncedAt != null &&
          next.lastSyncedAt != previous?.lastSyncedAt) {
        _recoverAfterSync = false;
        _refresh();
      }
    });
    final snapshot = _watchAlerts(ref);
    final seen = ref.watch(notificationSeenControllerProvider(widget.ownerKey));
    final freshCount = seen.value == null || _sheetOpen
        ? 0
        : seen.value!.opened
        ? snapshot.notifications.where(seen.value!.isNew).length
        : snapshot.unreadCount;
    final label = snapshot.loading || seen.isLoading
        ? 'Avisos, actualizando'
        : snapshot.loadError
        ? 'Avisos, no se pudieron actualizar'
        : freshCount == 0
        ? 'Avisos, ninguno nuevo'
        : freshCount > 9
        ? 'Avisos, más de 9 nuevos'
        : 'Avisos, $freshCount nuevos';
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: _sheetOpen ? null : _showAlerts,
          tooltip: label,
          icon: Badge(
            isLabelVisible: freshCount > 0,
            label: Text(freshCount > 9 ? '9+' : '$freshCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ),
    );
  }

  Future<void> _showAlerts() async {
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);
    final current = ref.read(driverNotificationsControllerProvider);
    if (current.hasValue && !current.hasError) {
      unawaited(
        ref
            .read(notificationSeenControllerProvider(widget.ownerKey).notifier)
            .acknowledge(current.value!.items),
      );
    }
    _refresh();
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) =>
            _DriverAlertsSheet(onRefresh: _refresh, onOpen: _openAlert),
      );
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  Future<String?> _openAlert(
    BuildContext sheetContext,
    _DriverAlert alert,
  ) async {
    if (alert.notificationId case final id?) {
      // Validate before navigation: a saved ID may have expired at midnight.
      try {
        await ref.read(notificationActionsControllerProvider).markRead(id);
      } on AppFailure catch (failure) {
        if (!mounted) return null;
        return failure.statusCode == 404
            ? 'Este aviso ya no está disponible.'
            : failure.message;
      } finally {
        if (mounted) {
          ref.invalidate(driverNotificationsControllerProvider);
          ref.invalidate(unreadNotificationCountControllerProvider);
        }
      }
    }
    if (!mounted || !sheetContext.mounted) return null;
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return null;
    if (alert.requestId case final requestId?) {
      await context.pushNamed<void>(
        'request-detail',
        pathParameters: {'requestId': requestId},
      );
    }
    if (!mounted) return null;
    _refresh();
    ref.invalidate(myRouteProvider);
    return null;
  }
}

class _DriverAlertsSheet extends ConsumerStatefulWidget {
  const _DriverAlertsSheet({required this.onRefresh, required this.onOpen});
  final VoidCallback onRefresh;
  final Future<String?> Function(BuildContext, _DriverAlert) onOpen;
  @override
  ConsumerState<_DriverAlertsSheet> createState() => _DriverAlertsSheetState();
}

class _DriverAlertsSheetState extends ConsumerState<_DriverAlertsSheet> {
  bool _opening = false;
  String? _actionMessage;
  Future<void> _open(_DriverAlert alert) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _actionMessage = null;
    });
    try {
      final message = await widget.onOpen(context, alert);
      if (mounted) setState(() => _actionMessage = message);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _watchAlerts(ref);
    return SafeArea(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Avisos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar avisos',
                  onPressed: snapshot.loading || _opening
                      ? null
                      : widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (snapshot.loading || _opening) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(
                semanticsLabel: 'Actualizando avisos',
              ),
            ],
            if (_actionMessage case final message?) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(liveRegion: true, child: Text(message)),
            ],
            if (snapshot.loadError) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: const Text(
                  'No fue posible actualizar los avisos. Revisa tu conexión e inténtalo nuevamente.',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: snapshot.loading || _opening
                      ? null
                      : widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (snapshot.alerts.isEmpty &&
                !snapshot.loading &&
                !snapshot.loadError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_outlined, size: 42),
                    SizedBox(height: AppSpacing.sm),
                    Text('No tienes avisos.'),
                  ],
                ),
              ),
            if (snapshot.alerts.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: snapshot.alerts.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final alert = snapshot.alerts[index];
                    final colors = Theme.of(context).colorScheme;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap:
                          !snapshot.loading && !_opening && alert.isActionable
                          ? () => unawaited(_open(alert))
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
    );
  }
}

_AlertsSnapshot _watchAlerts(WidgetRef ref) {
  final boardState = ref.watch(driverDeliveryControllerProvider);
  final board = !boardState.isLoading && !boardState.hasError
      ? boardState.value
      : null;
  final shift = ref.watch(activeShiftControllerProvider).value;
  final driver = ref.watch(ownDriverProfileControllerProvider).value;
  final notifications = ref.watch(driverNotificationsControllerProvider);
  final unreadCount = ref.watch(unreadNotificationCountControllerProvider);
  final unavailable = ref.watch(unavailableNotificationIdsProvider);
  final remote = !notifications.isLoading && !notifications.hasError
      ? notifications.value?.items
                .where((item) => !unavailable.contains(item.id))
                .toList() ??
            const <DriverNotification>[]
      : const <DriverNotification>[];
  final notifiedRequests = remote.map((item) => item.requestId).toSet();
  final local = <_DriverAlert>[
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
        if (!notifiedRequests.contains(request.id))
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
  final count = !unreadCount.isLoading && !unreadCount.hasError
      ? unreadCount.value ?? remote.where((item) => !item.isRead).length
      : 0;
  return _AlertsSnapshot(
    alerts: [
      for (final notification in remote)
        _DriverAlert(
          icon: _notificationIcon(notification.type),
          title: notification.title,
          message: notification.message,
          important: notification.isImportant,
          notificationId: notification.id,
          requestId: notification.requestId,
        ),
      ...local,
    ],
    notifications: remote,
    unreadCount: count,
    loading: notifications.isLoading || unreadCount.isLoading,
    loadError: notifications.hasError || unreadCount.hasError,
  );
}

IconData _notificationIcon(String type) {
  final normalized = type.toUpperCase();
  if (normalized.contains('PRIORIT')) return Icons.priority_high;
  if (normalized.contains('NO_ENTREGADO')) return Icons.inventory_2_outlined;
  if (normalized.contains('PENDIENTE')) return Icons.person_search_outlined;
  if (normalized.contains('ASIGN')) return Icons.assignment_turned_in_outlined;
  if (normalized.contains('CANCEL')) return Icons.cancel_outlined;
  return Icons.notifications_active_outlined;
}

class _AlertsSnapshot {
  const _AlertsSnapshot({
    required this.alerts,
    required this.notifications,
    required this.unreadCount,
    required this.loading,
    required this.loadError,
  });
  final List<_DriverAlert> alerts;
  final List<DriverNotification> notifications;
  final int unreadCount;
  final bool loading;
  final bool loadError;
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
