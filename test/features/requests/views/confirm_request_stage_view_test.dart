import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitago_app/core/device/device_location_service.dart';
import 'package:vitago_app/features/evidence/providers/evidence_providers.dart';
import 'package:vitago_app/features/evidence/services/evidence_capture_service.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/confirm_request_stage_view.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

void main() {
  testWidgets('la confirmación con foto no se desborda con texto grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evidenceCaptureServiceProvider.overrideWithValue(
            _FakeEvidenceCaptureService(),
          ),
          deviceLocationServiceProvider.overrideWithValue(
            const _FakeDeviceLocationService(),
          ),
          locationServiceEnabledProvider.overrideWith(
            (ref) => Stream.value(true),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: ConfirmRequestStageView(
            request: _request(),
            targetStatus: 'PICKED_UP',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Toma una foto del paquete'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('confirmation-form')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toma una foto del paquete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ServiceRequestDetail _request() {
  return ServiceRequestDetail(
    summary: ServiceRequestSummary(
      id: 'request-id',
      number: 'SOL-1',
      companyId: 'company-id',
      requestedById: 'user-id',
      assignedDriverId: 'driver-id',
      priority: 'NORMAL',
      modality: RequestModalities.betweenBranches,
      serviceType: const RequestServiceType(
        id: 'service-id',
        code: 'PAQUETE',
        name: 'Paquete',
      ),
      origin: const RequestPoint(
        id: 'origin-id',
        name: 'Sucursal origen',
        address: 'Dirección de origen',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Sucursal destino',
        address: 'Dirección de destino',
      ),
      routePresentation: 'MAPA',
      status: 'AT_PICKUP',
      createdAt: DateTime(2026, 10, 16),
    ),
    items: const [],
    events: const [],
    assignments: const [],
    updatedAt: DateTime(2026, 10, 16),
  );
}

class _FakeEvidenceCaptureService extends EvidenceCaptureService {
  @override
  Future<XFile?> recoverLostPhoto() async => null;
}

class _FakeDeviceLocationService extends DeviceLocationService {
  const _FakeDeviceLocationService();

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    return DeviceLocation(
      latitude: 14.0723,
      longitude: -87.1921,
      recordedAt: DateTime(2026, 10, 16),
    );
  }
}
