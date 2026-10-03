import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/operations/widgets/driver_profile_card.dart';

void main() {
  DriverProfile driver({Vehicle? vehicle}) => DriverProfile(
    id: 'driver-id',
    user: const DriverUser(
      id: 'user-id',
      email: 'motorista@vitago.test',
      firstNames: 'Carlos',
      lastNames: 'Mendoza',
      status: 'ACTIVO',
    ),
    companyId: 'company-id',
    vehicle: vehicle,
    operationalStatus: 'AVAILABLE',
    capacity: 'AVAILABLE_SPACE',
    active: true,
    createdAt: DateTime.utc(2026, 9, 29),
    updatedAt: DateTime.utc(2026, 9, 29),
  );

  final vehicle = Vehicle(
    id: 'vehicle-id',
    companyId: 'company-id',
    plate: 'HBA-1234',
    type: 'MOTOCICLETA',
    brand: 'Honda',
    model: 'XR150',
    status: 'ACTIVO',
    createdAt: DateTime.utc(2026, 9, 29),
    updatedAt: DateTime.utc(2026, 9, 29),
  );

  testWidgets('muestra la unidad y sus indicadores sin desbordarse', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DriverProfileCard(
              driver: driver(vehicle: vehicle),
              canUpdate: true,
              onUpdate: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('HBA-1234'), findsOneWidget);
    expect(find.textContaining('Honda XR150'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Con espacio'), findsNothing);
    expect(find.text('Cambiar estado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explica cuando no existe un vehículo asignado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverProfileCard(
            driver: driver(),
            canUpdate: false,
            onUpdate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sin vehículo asignado'), findsOneWidget);
    expect(
      find.text('Necesitas un vehículo activo para iniciar la jornada.'),
      findsOneWidget,
    );
    expect(find.text('Cambiar estado'), findsNothing);
  });
}
