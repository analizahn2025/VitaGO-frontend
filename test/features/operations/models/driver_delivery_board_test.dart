import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

void main() {
  ServiceRequestSummary request({
    required String id,
    required String status,
    required DateTime createdAt,
  }) {
    return ServiceRequestSummary(
      id: id,
      number: 'SOL-$id',
      companyId: 'company-id',
      requestedById: 'user-id',
      priority: 'NORMAL',
      modality: RequestModalities.betweenBranches,
      serviceType: const RequestServiceType(
        id: 'service-id',
        code: 'PAQUETE',
        name: 'Paquete',
      ),
      origin: const RequestPoint(
        id: 'origin-id',
        name: 'Origen',
        address: 'Dirección de origen',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Destino',
        address: 'Dirección de destino',
      ),
      routePresentation: 'MAPA',
      status: status,
      createdAt: createdAt,
    );
  }

  test('separa servicios en curso e historial visible', () {
    final board = DriverDeliveryBoard.fromRequests([
      request(
        id: 'old-active',
        status: 'ASSIGNED',
        createdAt: DateTime.utc(2026, 9, 28),
      ),
      request(
        id: 'delivered',
        status: 'DELIVERED',
        createdAt: DateTime.utc(2026, 9, 29),
      ),
      request(
        id: 'new-active',
        status: 'IN_TRANSIT',
        createdAt: DateTime.utc(2026, 9, 30),
      ),
      request(
        id: 'failed',
        status: 'DELIVERY_FAILED',
        createdAt: DateTime.utc(2026, 9, 27),
      ),
    ]);

    expect(board.inProgress.map((item) => item.id), [
      'new-active',
      'old-active',
    ]);
    expect(board.history.map((item) => item.id), ['delivered', 'failed']);
    expect(board.hasActiveAssignments, isTrue);
  });

  test('define la siguiente acción operativa sin inventar estados', () {
    expect(requestNextOperationalStatus('ASSIGNED'), 'GOING_TO_PICKUP');
    expect(
      requestTransitionActionLabelForStatus('AT_DESTINATION'),
      'Confirmar entrega',
    );
    expect(requestNextOperationalStatus('DELIVERED'), isNull);
  });
}
