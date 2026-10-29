import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/notifications/providers/notifications_providers.dart';
import 'package:vitago_app/features/notifications/repositories/notifications_repository.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/operations/widgets/driver_alerts_button.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/tracking/controllers/driver_tracking_status_controller.dart';

import 'package:vitago_app/features/notifications/storage/notification_seen_store.dart';

import '../../../support/notification_seen_memory_store.dart';

void main() {
  testWidgets(
    'una respuesta tardía tras cerrar no marca como visto un aviso nuevo',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      repo.pendingFeed = Completer<void>();
      repo.pendingCount = Completer<void>();
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      Navigator.of(tester.element(find.text('Avisos'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      repo.items = [_notification(id: 'new-after-closing'), _notification()];
      repo.count = 2;
      repo.pendingFeed!.complete();
      repo.pendingCount!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
      expect(find.text('1'), findsOneWidget);
      expect(repo.markCalls, 0);
    },
  );
  testWidgets(
    'abrir campana quita número sin borrar avisos ni marcar cada uno',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(find.text('Aviso anterior'), findsOneWidget);
      expect(repo.markCalls, 0);
      Navigator.of(tester.element(find.text('Avisos'))).pop();
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(repo.markCalls, 0);
    },
  );

  testWidgets(
    'aviso nuevo tras cerrar vuelve a encender número, no el conteo de no leídas',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Avisos'))).pop();
      await tester.pumpAndSettle();
      repo.items = [_notification(id: 'notification-2'), _notification()];
      repo.count = 2;
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Aviso anterior'), findsNWidgets(2));
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(repo.markCalls, 0);
    },
  );

  testWidgets(
    'avisos recibidos con campana abierta quedan vistos sin desaparecer',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      repo.items = [_notification(id: 'notification-2'), _notification()];
      repo.count = 2;
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Aviso anterior'), findsNWidgets(2));
      Navigator.of(tester.element(find.text('Avisos'))).pop();
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(repo.markCalls, 0);
    },
  );

  testWidgets('recuerda campana vista tras recrear app y separa cuentas', (
    tester,
  ) async {
    final repo = _Repository();
    final store = MemoryNotificationSeenStore();
    await _pump(tester, repo, seenStore: store);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, repo, seenStore: store);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, repo, seenStore: store, ownerKey: 'another-account');
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
  });

  testWidgets('avisos leídos siguen visibles aunque no sean nuevos', (
    tester,
  ) async {
    final repo = _Repository()
      ..items = [_notification(read: true)]
      ..count = 0;
    await _pump(tester, repo);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Aviso anterior'), findsOneWidget);
    expect(repo.markCalls, 0);
  });
  testWidgets('fallo temporal al marcar no descarta aviso ni navega', (
    tester,
  ) async {
    final repo = _Repository();
    final router = await _pump(tester, repo);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    repo.markFailure = const AppFailure(
      message: 'El servidor no está disponible.',
      statusCode: 503,
    );
    await tester.tap(find.text('Aviso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('El servidor no está disponible.'), findsOneWidget);
    expect(find.text('Aviso anterior'), findsOneWidget);
    expect(find.text('Este aviso ya no está disponible.'), findsNothing);
    expect(repo.markCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });
  testWidgets('abrir campana reemplaza caché y conteo, sin mezclar días', (
    tester,
  ) async {
    final repo = _Repository();
    await _pump(tester, repo);
    expect(find.text('1'), findsOneWidget);
    repo.items = [];
    repo.count = 0;
    repo.pendingFeed = Completer<void>();
    repo.pendingCount = Completer<void>();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aviso anterior'), findsNothing);
    expect(find.text('No tienes avisos.'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repo.pendingFeed!.complete();
    repo.pendingCount!.complete();
    await tester.pumpAndSettle();
    expect(repo.feedReads, 2);
    expect(repo.countReads, 2);
    expect(find.text('No tienes avisos.'), findsOneWidget);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  testWidgets('campana abierta recoge el corte del servidor en primer plano', (
    tester,
  ) async {
    final repo = _Repository();
    await _pump(tester, repo);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Aviso anterior'), findsOneWidget);
    repo.items = [];
    repo.count = 0;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Avisos'), findsOneWidget);
    expect(find.text('Aviso anterior'), findsNothing);
    expect(find.text('No tienes avisos.'), findsOneWidget);
    expect(repo.feedReads, 3);
    expect(repo.countReads, 3);
  });

  testWidgets('pausa cancela consultas y reanudar refresca ambos endpoints', (
    tester,
  ) async {
    final repo = _Repository();
    await _pump(tester, repo);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 3));
    expect(repo.feedReads, 1);
    repo.items = [];
    repo.count = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.feedReads, 2);
    expect(repo.countReads, 2);
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });

  testWidgets(
    'GPS sincronizado tras fallo recupera avisos sin esperar al minuto',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DriverAlertsButton)),
      );
      container
          .read(driverTrackingStatusProvider.notifier)
          .reportError('Sin red');
      repo.items = [];
      repo.count = 0;
      container
          .read(driverTrackingStatusProvider.notifier)
          .markSynced(DateTime.utc(2026, 10, 23));
      await tester.pumpAndSettle();
      expect(repo.feedReads, 2);
      expect(repo.countReads, 2);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    },
  );

  testWidgets('404 retira aviso sin navegar ni reintentar un ID caducado', (
    tester,
  ) async {
    final repo = _Repository();
    final router = await _pump(tester, repo);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    repo.markFailure = const AppFailure(
      message: 'No encontrado',
      statusCode: 404,
    );
    await tester.tap(find.text('Aviso anterior'));
    await tester.pumpAndSettle();
    expect(repo.markCalls, 1);
    expect(find.text('Este aviso ya no está disponible.'), findsOneWidget);
    expect(find.text('Aviso anterior'), findsNothing);
    expect(find.text('No tienes avisos.'), findsOneWidget);
    expect(find.text('Pantalla de solicitud'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(repo.markCalls, 1);
  });

  testWidgets(
    'error de red no muestra avisos anteriores como actuales ni lista vacía falsa',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      repo.readFailure = const AppFailure(message: 'Sin conexión');
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Aviso anterior'), findsNothing);
      expect(find.text('No tienes avisos.'), findsNothing);
      expect(
        find.textContaining('No fue posible actualizar los avisos.'),
        findsOneWidget,
      );
      repo.readFailure = null;
      repo.items = [];
      repo.count = 0;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('No tienes avisos.'), findsOneWidget);
      expect(
        find.textContaining('No fue posible actualizar los avisos.'),
        findsNothing,
      );
    },
  );

  testWidgets('navega al servicio únicamente tras validar aviso vigente', (
    tester,
  ) async {
    final repo = _Repository();
    final router = await _pump(tester, repo);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    repo.pendingMark = Completer<void>();
    await tester.tap(find.text('Aviso anterior'));
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repo.pendingMark!.complete();
    await tester.pumpAndSettle();
    expect(repo.markCalls, 1);
    expect(find.text('Pantalla de solicitud'), findsOneWidget);
  });
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _Repository repo, {
  MemoryNotificationSeenStore? seenStore,
  String ownerKey = 'test-owner',
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          appBar: AppBar(actions: [DriverAlertsButton(ownerKey: ownerKey)]),
        ),
      ),
      GoRoute(
        path: '/solicitudes/:requestId',
        name: 'request-detail',
        builder: (_, _) => const Scaffold(body: Text('Pantalla de solicitud')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationSeenStoreProvider.overrideWithValue(
          seenStore ?? MemoryNotificationSeenStore(),
        ),
        notificationsRepositoryProvider.overrideWithValue(repo),
        driverDeliveryControllerProvider.overrideWith(
          (ref) async => const DriverDeliveryBoard(inProgress: [], history: []),
        ),
        activeShiftControllerProvider.overrideWith((ref) async => null),
        ownDriverProfileControllerProvider.overrideWith((ref) async => _driver),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _Repository implements NotificationsRepository {
  List<DriverNotification> items = [_notification()];
  int count = 1;
  int feedReads = 0;
  int countReads = 0;
  int markCalls = 0;
  AppFailure? readFailure;
  AppFailure? markFailure;
  Completer<void>? pendingFeed;
  Completer<void>? pendingCount;
  Completer<void>? pendingMark;

  @override
  Future<DriverNotificationFeed> getNotifications() async {
    feedReads++;
    await pendingFeed?.future;
    if (readFailure case final failure?) throw failure;
    return DriverNotificationFeed(count: items.length, items: [...items]);
  }

  @override
  Future<int> getUnreadCount() async {
    countReads++;
    await pendingCount?.future;
    if (readFailure case final failure?) throw failure;
    return count;
  }

  @override
  Future<DriverNotification> markRead(String notificationId) async {
    markCalls++;
    await pendingMark?.future;
    if (markFailure case final failure?) {
      if (failure.statusCode == 404) count = 0;
      // A stale response can still contain this ID: the client must exclude it.
      throw failure;
    }
    items = [];
    count = 0;
    return _notification(read: true);
  }
}

DriverNotification _notification({
  bool read = false,
  String id = 'notification-1',
}) => DriverNotification(
  id: id,
  type: 'SOLICITUD_ASIGNADA',
  title: 'Aviso anterior',
  message: 'Servicio del servidor',
  requestId: 'request-1',
  isRead: read,
  isImportant: false,
  createdAt: DateTime.utc(2099, 1, 1),
);

final _driver = DriverProfile(
  id: 'driver-id',
  user: const DriverUser(
    id: 'user-id',
    email: 'driver@example.test',
    firstNames: 'Carlos',
    lastNames: 'Prueba',
    status: 'ACTIVO',
  ),
  vehicle: Vehicle(
    id: 'vehicle-id',
    plate: 'HAA-1',
    type: 'MOTOCICLETA',
    status: 'ACTIVO',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  operationalStatus: 'AVAILABLE',
  capacity: 'AVAILABLE_SPACE',
  active: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
