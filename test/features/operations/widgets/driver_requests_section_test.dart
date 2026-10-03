import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/operations/widgets/driver_requests_section.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

void main() {
  testWidgets('mantiene el tablero Delivery dentro de una pantalla angosta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        name: 'Sucursal con un nombre bastante extenso',
        address: 'Origen',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Destino con un nombre bastante extenso',
        address: 'Destino',
      ),
      routePresentation: 'MAPA',
      status: 'ASSIGNED',
      createdAt: DateTime.utc(2026, 9, 29),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DriverRequestsSection(
              board: AsyncData(
                DriverDeliveryBoard(inProgress: [request], history: const []),
              ),
              showHistory: false,
              onRetry: () {},
              onOpenRequest: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Servicios de hoy'), findsOneWidget);
    expect(find.text('Ir a recolectar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
