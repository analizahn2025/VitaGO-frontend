import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/evidence/controllers/evidence_controller.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/views/widgets/driver_request_actions.dart';
import 'package:vitago_app/features/routes/models/driver_route_flow.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';
import 'package:vitago_app/features/shifts/models/driver_shift.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';
import 'package:vitago_app/features/tracking/models/tracking_configuration.dart';

void main() {
  for (final status in ['ASSIGNED', 'GOING_TO_PICKUP', 'IN_TRANSIT']) {
    testWidgets(
      'el servicio $status no ofrece inicios ni confirmaciones manuales',
      (tester) async {
        await _pumpActions(tester, status: status);
        expect(find.text('Ir a recolectar'), findsNothing);
        expect(find.text('Iniciar traslado'), findsNothing);
        expect(find.text('Confirmar recolección'), findsNothing);
        expect(find.text('Confirmar entrega'), findsNothing);
        expect(find.textContaining('Sigue el mapa'), findsOneWidget);
      },
    );
  }
  testWidgets('el especial conserva únicamente Finalizar encargo', (
    tester,
  ) async {
    await _pumpActions(tester, status: 'IN_TRANSIT', special: true);
    expect(find.text('Finalizar encargo'), findsOneWidget);
    expect(find.text('Llegué al destino'), findsNothing);
  });
  testWidgets('sin jornada activa no habilita la foto', (tester) async {
    await _pumpActions(tester, hasShift: false);
    expect(
      find.text('Inicia tu jornada para continuar con el servicio.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });
  testWidgets('sin permiso de transición no ofrece fotos operativas', (
    tester,
  ) async {
    await _pumpActions(tester, permissions: const []);
    expect(find.byType(FilledButton), findsNothing);
  });
  testWidgets('no permite operar una etapa que no coincide con flujo_actual', (
    tester,
  ) async {
    await _pumpActions(tester, stopType: 'ENTREGA');
    expect(find.textContaining('Este envío está en espera'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Reportar recolección fallida'), findsNothing);
  });
  testWidgets(
    'una foto ya listada no habilita una transición de confirmación',
    (tester) async {
      await _pumpActions(
        tester,
        evidenceFuture: Future.value(_evidencePage(type: 'FOTO_RECOLECCION')),
      );
      expect(find.text('Tomar foto de recolección'), findsOneWidget);
      expect(find.text('Confirmar recolección'), findsNothing);
    },
  );
  testWidgets('sin permiso de evidencia el botón de foto queda deshabilitado', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      permissions: const [AppPermissions.updateRequestStatus],
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Tomar foto de recolección'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('GPS apagado bloquea acciones y callbacks antiguos', (
    tester,
  ) async {
    final gps = StreamController<bool>()..add(true);
    addTearDown(gps.close);
    await _pumpActions(tester, gpsStream: gps.stream);
    final button = find.widgetWithText(
      FilledButton,
      'Tomar foto de recolección',
    );
    final staleCallback = tester.widget<FilledButton>(button).onPressed;
    expect(staleCallback, isNotNull);
    gps.add(false);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    staleCallback!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirmation-form')), findsNothing);
  });
  testWidgets('la acción principal soporta texto grande y paisaje', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpActions(tester, textScale: 1.5);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(640, 320);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpActions(
  WidgetTester tester, {
  bool hasShift = true,
  String status = 'AT_PICKUP',
  bool special = false,
  String? stopType,
  List<String> permissions = const [
    AppPermissions.updateRequestStatus,
    AppPermissions.viewEvidence,
    AppPermissions.createEvidence,
  ],
  Future<PaginatedResult<OperationalEvidence>>? evidenceFuture,
  Stream<bool>? gpsStream,
  bool settle = true,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trackingConfigurationProvider.overrideWith(
          (ref) async => TrackingConfiguration.defaults,
        ),
        locationServiceEnabledProvider.overrideWith(
          (ref) => gpsStream ?? Stream.value(true),
        ),
        activeShiftControllerProvider.overrideWith(
          (ref) async => hasShift ? _activeShift : null,
        ),
        requestEvidenceControllerProvider((ownerId: 'request-id', page: 1))
            .overrideWith(
              (ref) => evidenceFuture ?? Future.value(_evidencePage()),
            ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DriverRequestActions(
              request: _request(status, special: special),
              profile: _profile(permissions),
              stopType: stopType,
              flow: DriverRouteFlow(
                mode: 'AUTOMATICO',
                requestId: 'request-id',
                status: status,
                stopType: special && status == 'IN_TRANSIT'
                    ? 'ENVIO_ESPECIAL'
                    : const {'IN_TRANSIT', 'AT_DESTINATION'}.contains(status)
                    ? 'ENTREGA'
                    : 'RECOLECCION',
                screen: special && status == 'IN_TRANSIT'
                    ? 'FINALIZAR_ESPECIAL'
                    : status == 'AT_PICKUP'
                    ? 'RECOLECCION'
                    : status == 'AT_DESTINATION'
                    ? 'ENTREGA'
                    : 'MAPA',
                requiredEvidence: status == 'AT_PICKUP'
                    ? 'FOTO_RECOLECCION'
                    : status == 'AT_DESTINATION'
                    ? 'FOTO_ENTREGA'
                    : null,
                requiresSpecialCompletion: special && status == 'IN_TRANSIT',
              ),
              onCompleted: (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

UserProfile _profile(List<String> permissions) => UserProfile(
  user: const ProfileUser(
    id: 'user-id',
    email: 'driver@example.com',
    firstNames: 'Motorista',
    lastNames: 'Prueba',
    status: 'ACTIVO',
  ),
  roles: const [
    ScopedRole(
      code: 'REPARTIDOR_CORPORATIVO',
      name: 'Motorista',
      scopeType: ScopeType.company,
    ),
  ],
  permissions: permissions,
);

ServiceRequestDetail _request(String status, {bool special = false}) =>
    ServiceRequestDetail(
      summary: ServiceRequestSummary(
        id: 'request-id',
        number: 'SOL-1',
        companyId: 'company-id',
        requestedById: 'user-id',
        assignedDriverId: 'driver-id',
        priority: 'NORMAL',
        modality: special
            ? RequestModalities.special
            : RequestModalities.betweenBranches,
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
        routePresentation: 'MAPA',
        status: status,
        createdAt: DateTime.utc(2026, 10, 22),
      ),
      items: const [],
      events: const [],
      assignments: const [],
      updatedAt: DateTime.utc(2026, 10, 22),
    );

PaginatedResult<OperationalEvidence> _evidencePage({String? type}) =>
    PaginatedResult(
      count: type == null ? 0 : 1,
      items: [
        if (type != null)
          OperationalEvidence(
            id: 'evidence-id',
            type: type,
            contentType: 'image/jpeg',
            sizeBytes: 100,
            latitude: '14',
            longitude: '-87',
            capturedAt: DateTime.utc(2026, 10, 22),
            fileAvailable: true,
            createdAt: DateTime.utc(2026, 10, 22),
          ),
      ],
      hasNext: false,
      hasPrevious: false,
    );

final _activeShift = DriverShift(
  id: 'shift-id',
  driverId: 'driver-id',
  status: 'ACTIVA',
  startedAt: DateTime.utc(2026, 10, 22),
  operationalKilometers: '0',
  mileageAvailable: false,
  completedServices: 0,
  completedPickups: 0,
  completedDeliveries: 0,
  normalServices: 0,
  priorityServices: 0,
  activeMinutes: 0,
  reportedIncidents: 0,
  incidentsAvailable: false,
  createdAt: DateTime.utc(2026, 10, 22),
  updatedAt: DateTime.utc(2026, 10, 22),
);
