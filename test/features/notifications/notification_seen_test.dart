import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/storage/secure_store.dart';
import 'package:vitago_app/features/notifications/controllers/notification_seen_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/models/notification_seen_state.dart';
import 'package:vitago_app/features/notifications/storage/notification_seen_store.dart';

void main() {
  test(
    'vistos no son leídos: conserva IDs y detecta otro evento con misma fecha',
    () {
      final item = _item('first');
      final seen = const NotificationSeenState().acknowledge([item]);
      expect(item.isRead, isFalse);
      expect(seen.opened, isTrue);
      expect(seen.isNew(item), isFalse);
      expect(seen.isNew(_item('second')), isTrue);
      expect(seen.isNew(_item('old', offset: -1)), isFalse);
      expect(seen.isNew(_item('read', read: true, offset: 1)), isFalse);
      expect(
        seen.acknowledge([_item('old', offset: -1)]).through,
        seen.through,
      );
    },
  );

  test('avisos sin fecha usan ID, nunca la hora del teléfono', () {
    const item = DriverNotification(
      id: 'no-date',
      type: 'INFO',
      title: 'Aviso',
      message: '',
      isRead: false,
      isImportant: false,
    );
    final seen = const NotificationSeenState().acknowledge([item]);
    expect(seen.through, isNull);
    expect(seen.isNew(item), isFalse);
    expect(
      NotificationSeenState.fromJson(seen.toJson()).ids,
      contains('no-date'),
    );
  });

  test(
    'persistencia separa cuenta y servidor y sobrevive recreación del store',
    () async {
      final disk = _SecureMemory();
      await SecureNotificationSeenStore(disk).save(
        'corporate|user-1',
        const NotificationSeenState().acknowledge([_item('first')]),
      );
      final restored = SecureNotificationSeenStore(disk);
      expect(
        (await restored.load('corporate|user-1')).isNew(_item('first')),
        isFalse,
      );
      expect(
        (await restored.load('corporate|user-2')).isNew(_item('first')),
        isTrue,
      );
      expect(
        (await restored.load('network|user-1')).isNew(_item('first')),
        isTrue,
      );
    },
  );

  test(
    'abrir antes de restaurar combina historial sin sobrescribir otros vistos',
    () async {
      final store = _DelayedStore();
      final container = ProviderContainer(
        overrides: [notificationSeenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final provider = notificationSeenControllerProvider('owner');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final ack = container.read(provider.notifier).acknowledge([
        _item('second'),
      ]);
      store.restored.complete(
        const NotificationSeenState().acknowledge([_item('first')]),
      );
      await ack;
      expect(
        container.read(provider).value!.ids,
        containsAll(['first', 'second']),
      );
      expect(store.saved!.ids, containsAll(['first', 'second']));
    },
  );
}

DriverNotification _item(String id, {int offset = 0, bool read = false}) =>
    DriverNotification(
      id: id,
      type: 'INFO',
      title: 'Aviso',
      message: '',
      isRead: read,
      isImportant: false,
      createdAt: DateTime.utc(2026, 10, 23, 18).add(Duration(seconds: offset)),
    );

class _SecureMemory implements SecureStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _DelayedStore implements NotificationSeenStore {
  final restored = Completer<NotificationSeenState>();
  NotificationSeenState? saved;
  @override
  Future<NotificationSeenState> load(String ownerKey) => restored.future;
  @override
  Future<void> save(String ownerKey, NotificationSeenState value) async {
    saved = value;
  }
}
