import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/operations/widgets/driver_alerts_button.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';

void main() {
  testWidgets('muestra los avisos operativos del motorista', (tester) async {
    final request = ServiceRequestSummary(
      id: 'request-id',
      number: 'SOL-0001',
      companyId: 'company-id',
      requestedById: 'user-id',
      priority: 'PRIORITY',
      modality: RequestModalities.betweenBranches,
      serviceType: const RequestServiceType(
        id: 'service-id',
        code: 'PAQUETE',
        name: 'Paquete',
      ),
      origin: const RequestPoint(
        id: 'origin-id',
        name: 'Sucursal A',
        address: 'Origen',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Sucursal B',
        address: 'Destino',
      ),
      routePresentation: 'MAPA',
      status: 'ASSIGNED',
      createdAt: DateTime.utc(2026, 9, 30),
    );
    final driver = DriverProfile(
      id: 'driver-id',
      user: const DriverUser(
        id: 'user-id',
        email: 'motorista@vitago.test',
        firstNames: 'Carlos',
        lastNames: 'Mendoza',
        status: 'ACTIVO',
      ),
      vehicle: Vehicle(
        id: 'vehicle-id',
        plate: 'HBA-1234',
        type: 'MOTOCICLETA',
        status: 'ACTIVO',
        createdAt: DateTime.utc(2026, 9, 30),
        updatedAt: DateTime.utc(2026, 9, 30),
      ),
      operationalStatus: 'AVAILABLE',
      capacity: 'AVAILABLE_SPACE',
      active: true,
      createdAt: DateTime.utc(2026, 9, 30),
      updatedAt: DateTime.utc(2026, 9, 30),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverDeliveryControllerProvider.overrideWith(
            (ref) async =>
                DriverDeliveryBoard(inProgress: [request], history: const []),
          ),
          activeShiftControllerProvider.overrideWith((ref) async => null),
          ownDriverProfileControllerProvider.overrideWith(
            (ref) async => driver,
          ),
          driverNotificationsControllerProvider.overrideWith(
            (ref) async => const DriverNotificationFeed(count: 0, items: []),
          ),
          unreadNotificationCountControllerProvider.overrideWith(
            (ref) async => 0,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(actions: const [DriverAlertsButton()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Avisos'), findsOneWidget);
    expect(find.text('Inicia tu jornada'), findsOneWidget);
    expect(find.text('Servicio prioritario'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mantiene los avisos legibles con texto grande y en paisaje', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 667));

    final notifications = List.generate(
      12,
      (index) => DriverNotification(
        id: 'notification-$index',
        type: 'SOLICITUD_ASIGNADA',
        title: 'Servicio asignado',
        message: 'Tienes una nueva solicitud disponible para atender.',
        requestId: 'request-$index',
        isRead: false,
        isImportant: false,
      ),
    );
    final driver = DriverProfile(
      id: 'driver-id',
      user: const DriverUser(
        id: 'user-id',
        email: 'motorista@vitago.test',
        firstNames: 'Carlos',
        lastNames: 'Mendoza',
        status: 'ACTIVO',
      ),
      vehicle: Vehicle(
        id: 'vehicle-id',
        plate: 'HBA-1234',
        type: 'MOTOCICLETA',
        status: 'ACTIVO',
        createdAt: DateTime.utc(2026, 10, 2),
        updatedAt: DateTime.utc(2026, 10, 2),
      ),
      operationalStatus: 'AVAILABLE',
      capacity: 'EMPTY',
      active: true,
      createdAt: DateTime.utc(2026, 10, 2),
      updatedAt: DateTime.utc(2026, 10, 2),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverDeliveryControllerProvider.overrideWith(
            (ref) async =>
                const DriverDeliveryBoard(inProgress: [], history: []),
          ),
          activeShiftControllerProvider.overrideWith((ref) async => null),
          ownDriverProfileControllerProvider.overrideWith(
            (ref) async => driver,
          ),
          driverNotificationsControllerProvider.overrideWith(
            (ref) async => DriverNotificationFeed(
              count: notifications.length,
              items: notifications,
            ),
          ),
          unreadNotificationCountControllerProvider.overrideWith(
            (ref) async => notifications.length,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(appBar: AppBar(actions: const [DriverAlertsButton()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Avisos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.text('Avisos'))).pop();
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(667, 375));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Avisos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
