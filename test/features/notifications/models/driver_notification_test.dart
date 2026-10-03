import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/providers/notifications_providers.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';

void main() {
  test('interpreta notificaciones paginadas del motorista', () {
    final feed = DriverNotificationFeed.fromJson({
      'conteo': 1,
      'pagina_siguiente': null,
      'pagina_anterior': null,
      'resultados': [
        {
          'id': 'notification-id',
          'tipo': 'SOLICITUD_ASIGNADA',
          'titulo': 'Nuevo servicio',
          'mensaje': 'Se te asignó SOL-0001.',
          'solicitud_id': 'request-id',
          'ruta': '/solicitudes/request-id',
          'enlace_profundo': 'vitago-corporate:///solicitudes/request-id',
          'leida': false,
          'leida_en': null,
          'creado_en': '2026-10-01T08:00:00-06:00',
        },
      ],
    });

    expect(feed.count, 1);
    expect(feed.items.single.requestId, 'request-id');
    expect(feed.items.single.isRead, isFalse);
    expect(feed.items.single.title, 'Nuevo servicio');
    expect(feed.items.single.route, '/solicitudes/request-id');
    expect(feed.items.single.deepLink, contains('vitago-corporate'));
    expect(feed.items.single.readAt, isNull);
  });

  test('admite una lista directa y nombres alternativos seguros', () {
    final feed = DriverNotificationFeed.fromJson([
      {
        'id': 'notification-id',
        'tipo': 'SOLICITUD_PRIORITARIA',
        'descripcion': 'Atender primero.',
        'solicitud': {'id': 'request-id'},
        'leido': 1,
      },
    ]);

    expect(feed.items.single.title, 'Servicio prioritario');
    expect(feed.items.single.message, 'Atender primero.');
    expect(feed.items.single.isRead, isTrue);
    expect(feed.items.single.isImportant, isTrue);
  });

  test('consulta el conteo y marca una notificación como leída', () async {
    final repository = _FakeNotificationsRepository();
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(unreadNotificationCountControllerProvider.future),
      3,
    );
    final updated = await container
        .read(notificationActionsControllerProvider)
        .markRead('notification-id');

    expect(repository.markedId, 'notification-id');
    expect(updated.isRead, isTrue);
  });
}

class _FakeNotificationsRepository implements NotificationsRepository {
  String? markedId;

  @override
  Future<DriverNotificationFeed> getNotifications() async {
    return const DriverNotificationFeed(count: 0, items: []);
  }

  @override
  Future<int> getUnreadCount() async => 3;

  @override
  Future<DriverNotification> markRead(String notificationId) async {
    markedId = notificationId;
    return DriverNotification(
      id: notificationId,
      type: 'SOLICITUD_ASIGNADA',
      title: 'Servicio asignado',
      message: 'Actualización registrada.',
      isRead: true,
      isImportant: false,
      readAt: DateTime.utc(2026, 10, 2),
    );
  }
}
