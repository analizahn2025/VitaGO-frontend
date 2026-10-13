import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/requests/views/cancel_request_dialog.dart';
import 'package:vitago_app/features/requests/views/request_detail_view.dart';

void main() {
  testWidgets('exige motivo y envía la cancelación confirmada', (tester) async {
    final repository = _RequestsRepository(response: _request('CANCELLED'));

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('cancel-dialog'),
        overrides: [
          requestActionsControllerProvider.overrideWithValue(
            RequestActionsController(repository),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showDialog<ServiceRequestDetail>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      CancelRequestDialog(request: _request('ASSIGNED')),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar envío'));
    await tester.pump();

    expect(find.text('Escribe el motivo de la cancelación.'), findsOneWidget);
    expect(repository.transitionCalls, 0);

    await tester.enterText(
      find.byType(TextFormField),
      '  Solicitud duplicada por el administrador  ',
    );
    await tester.tap(find.text('Sí, cancelar envío'));
    await tester.pumpAndSettle();

    expect(repository.transitionCalls, 1);
    expect(repository.lastRequestId, 'request-id');
    expect(repository.lastInput?.targetStatus, 'CANCELLED');
    expect(
      repository.lastInput?.reason,
      'Solicitud duplicada por el administrador',
    );
    expect(repository.lastInput?.latitude, isNull);
    expect(repository.lastInput?.longitude, isNull);
  });

  testWidgets('muestra Cancelar envío solamente en estados permitidos', (
    tester,
  ) async {
    final profile = _profileWithCancelPermission();

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('cancel-allowed'),
        overrides: [
          requestControllerProvider('request-id')
              .overrideWith((ref) async => _request('AT_PICKUP')),
        ],
        child: MaterialApp(
          home: RequestDetailView(requestId: 'request-id', profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelar envío'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('cancel-blocked'),
        overrides: [
          requestControllerProvider('request-id')
              .overrideWith((ref) async => _request('PICKED_UP')),
        ],
        child: MaterialApp(
          home: RequestDetailView(requestId: 'request-id', profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelar envío'), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('cancel-without-permission'),
        overrides: [
          requestControllerProvider('request-id')
              .overrideWith((ref) async => _request('PENDING')),
        ],
        child: MaterialApp(
          home: RequestDetailView(
            requestId: 'request-id',
            profile: _profileWithoutPermissions(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelar envío'), findsNothing);
  });

  testWidgets('el diálogo se adapta a texto grande y orientación horizontal', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 667));
    final repository = _RequestsRepository(response: _request('CANCELLED'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestActionsControllerProvider.overrideWithValue(
            RequestActionsController(repository),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showDialog<ServiceRequestDetail>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      CancelRequestDialog(request: _request('AT_PICKUP')),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar envío'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(667, 375));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar envío'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('reconoce exactamente los estados cancelables', () {
    expect(requestIsCancellable('PENDING'), isTrue);
    expect(requestIsCancellable('ASSIGNED'), isTrue);
    expect(requestIsCancellable('GOING_TO_PICKUP'), isTrue);
    expect(requestIsCancellable('AT_PICKUP'), isTrue);
    expect(requestIsCancellable('PICKED_UP'), isFalse);
    expect(requestIsCancellable('DELIVERED'), isFalse);
  });
}

UserProfile _profileWithoutPermissions() {
  return UserProfile(
    user: const ProfileUser(
      id: 'user-id',
      email: 'usuario@vitago.test',
      firstNames: 'Usuario',
      lastNames: 'Prueba',
      status: 'ACTIVO',
    ),
    roles: const [],
    permissions: const [],
  );
}

UserProfile _profileWithCancelPermission() {
  return UserProfile(
    user: const ProfileUser(
      id: 'admin-id',
      email: 'admin@vitago.test',
      firstNames: 'Ana',
      lastNames: 'Administradora',
      status: 'ACTIVO',
    ),
    roles: const [],
    permissions: const [AppPermissions.cancelRequests],
  );
}

ServiceRequestDetail _request(String status) {
  final createdAt = DateTime.utc(2026, 10, 5, 14);
  return ServiceRequestDetail(
    summary: ServiceRequestSummary(
      id: 'request-id',
      number: 'SOL-20261005-0001',
      companyId: 'company-id',
      requestedById: 'requester-id',
      assignedDriverId: 'driver-id',
      priority: 'NORMAL',
      modality: RequestModalities.betweenBranches,
      serviceType: const RequestServiceType(
        id: 'service-id',
        code: 'DOCUMENTO',
        name: 'Documento',
      ),
      origin: const RequestPoint(
        id: 'origin-id',
        name: 'Sucursal Centro',
        address: 'Tegucigalpa',
      ),
      destination: const RequestPoint(
        id: 'destination-id',
        name: 'Sucursal Norte',
        address: 'Tegucigalpa',
      ),
      routePresentation: 'MAPA',
      status: status,
      createdAt: createdAt,
    ),
    items: const [],
    events: const [],
    assignments: const [],
    updatedAt: createdAt,
  );
}

class _RequestsRepository implements RequestsRepository {
  _RequestsRepository({required this.response});

  final ServiceRequestDetail response;
  int transitionCalls = 0;
  String? lastRequestId;
  RequestTransitionInput? lastInput;

  @override
  Future<ServiceRequestDetail> transitionRequest(
    String requestId,
    RequestTransitionInput input,
  ) async {
    transitionCalls++;
    lastRequestId = requestId;
    lastInput = input;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
