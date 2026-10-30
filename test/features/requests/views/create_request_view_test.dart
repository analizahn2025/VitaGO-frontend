import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/models/request_creation_options.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';
import 'package:vitago_app/features/requests/views/create_request_view.dart';

void main() {
  testWidgets('crea un envío solo con frascos y sin artículos', (tester) async {
    final repository = _Repository(errorField: 'origen_id');
    await _open(tester, repository);
    await _select(tester, 'Modalidad del servicio', 'Entre sucursales');
    await _select(tester, 'Origen', 'Kennedy');
    await _select(tester, 'Sucursal de destino', 'El Zamorano');
    await _select(tester, 'Servicio', 'Mensajería');
    await tester.enterText(find.widgetWithText(TextFormField, 'Frascos'), '3');
    await tester.tap(find.text('Crear solicitud'));
    await tester.pumpAndSettle();
    expect(repository.created?.tubeCount, 0);
    expect(repository.created?.flaskCount, 3);
    expect(repository.created?.toJson().containsKey('articulos'), isFalse);
  });

  testWidgets(
    'cantidad de tubos no convierte fracciones o negativos en enteros',
    (tester) async {
      final repository = _Repository(errorField: 'cantidad_tubos');
      await _open(tester, repository);
      await _select(tester, 'Modalidad del servicio', 'Entre sucursales');
      await _select(tester, 'Origen', 'Kennedy');
      await _select(tester, 'Sucursal de destino', 'El Zamorano');
      await _select(tester, 'Servicio', 'Mensajería');
      final field = find.widgetWithText(TextFormField, 'Tubos');
      for (final value in ['', '-1', '1.5', '2147483648']) {
        await tester.enterText(field, value);
        await tester.tap(find.text('Crear solicitud'));
        await tester.pumpAndSettle();
        expect(repository.created, isNull);
      }
    },
  );

  testWidgets('consulta por ubicación y conserva destinos de otras ciudades', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository);
    await _select(tester, 'Modalidad del servicio', 'Entre sucursales');
    expect(repository.queries.last.originId, isNull);
    await _select(tester, 'Origen', 'Kennedy');
    expect(repository.queries.last.toQueryParameters(), {
      'empresa_id': 'company',
      'modalidad': 'ENTRE_SUCURSALES',
      'origen_id': 'location-kennedy',
    });

    await _select(tester, 'Sucursal de destino', 'El Zamorano');
    expect(_destination(tester), 'location-zamorano');
    // Cambiar el origen invalida la selección y consulta otro conjunto del API.
    await _select(tester, 'Origen', 'Choluteca');
    expect(repository.queries.last.originId, 'location-choluteca');
    expect(_destination(tester), isNull);
    await _select(tester, 'Sucursal de destino', 'San Marcos de Colón');
    expect(_destination(tester), 'location-san-marcos');
    expect(tester.takeException(), isNull);
  });

  for (final message in [
    'No hay sucursales de destino disponibles en el mismo departamento.',
    'La sucursal de origen no tiene departamento registrado. Solicite su actualización al administrador.',
  ]) {
    testWidgets('muestra disponibilidad del servidor: $message', (
      tester,
    ) async {
      await _open(tester, _Repository(message: message));
      await _select(tester, 'Modalidad del servicio', 'Entre sucursales');
      await _select(tester, 'Origen', 'Kennedy');
      expect(find.text(message), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Crear solicitud'),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  for (final field in ['origen_id', 'destino_id']) {
    testWidgets('conserva error 400 de $field junto al campo', (tester) async {
      final repository = _Repository(errorField: field);
      await _open(tester, repository);
      await _select(tester, 'Modalidad del servicio', 'Entre sucursales');
      await _select(tester, 'Origen', 'Kennedy');
      await _select(tester, 'Sucursal de destino', 'El Zamorano');
      await _select(tester, 'Servicio', 'Mensajería');
      await tester.enterText(find.widgetWithText(TextFormField, 'Tubos'), '3');
      await tester.tap(find.text('Crear solicitud'));
      await tester.pumpAndSettle();
      expect(repository.created?.destinationId, 'location-zamorano');
      expect(repository.created?.tubeCount, 3);
      expect(find.text('Revisa los campos marcados.'), findsOneWidget);
      final fieldLabel = field == 'origen_id'
          ? 'Origen'
          : 'Sucursal de destino';
      expect(
        find.descendant(
          of: _dropdown(fieldLabel),
          matching: find.text(
            'El departamento de esta ubicación no es válido.',
          ),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('Network mantiene bloqueada la creación pública', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, mode: AppMode.external);
    expect(find.text('Creación no disponible'), findsOneWidget);
    expect(repository.queries, isEmpty);
  });
}

Finder _dropdown(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(DropdownButtonFormField<String>),
);

Future<void> _select(WidgetTester tester, String label, String value) async {
  await tester.tap(_dropdown(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

String? _destination(WidgetTester tester) => tester
    .state<FormFieldState<String>>(_dropdown('Sucursal de destino'))
    .value;

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  AppMode mode = AppMode.corporate,
}) async {
  tester.view.physicalSize = const Size(430, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            mode: mode,
            apiBaseUri: Uri.parse('http://localhost/api/v1/'),
          ),
        ),
        requestsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: CreateRequestView(
          profile: UserProfile(
            user: const ProfileUser(
              id: 'requester',
              email: 'requester@example.com',
              firstNames: 'Solicitante',
              lastNames: 'Prueba',
              status: 'ACTIVO',
            ),
            roles: const [],
            permissions: const [],
            company: const ProfileOrganization(id: 'company', name: 'Empresa'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Repository implements RequestsRepository {
  _Repository({this.message, this.errorField});
  final String? message;
  final String? errorField;
  final queries = <RequestCreationOptionsQuery>[];
  CreateServiceRequestInput? created;

  @override
  Future<List<RequestServiceType>> getServiceTypes() async => const [
    RequestServiceType(id: 'service', code: 'MENSAJERIA', name: 'Mensajería'),
  ];

  @override
  Future<RequestCreationOptions> getCreationOptions(
    RequestCreationOptionsQuery query,
  ) async {
    queries.add(query);
    return RequestCreationOptions(
      companyId: 'company',
      canCreateSpecial: false,
      modalities: const [
        RequestCreationModality(
          code: 'ENTRE_SUCURSALES',
          name: 'Entre sucursales',
          requiresRegisteredDestination: true,
          routePresentation: 'MAPA',
        ),
      ],
      origins: [
        _location('kennedy', 'Kennedy', 'Tegucigalpa', 'Francisco Morazán'),
        _location('choluteca', 'Choluteca', 'Choluteca', 'Choluteca'),
      ],
      destinations: query.originId == null || message != null
          ? []
          : query.originId == 'location-kennedy'
          ? [
              _location(
                'zamorano',
                'El Zamorano',
                'El Zamorano',
                'Francisco Morazán',
              ),
              _location(
                'comayaguela',
                'Comayagüela',
                'Comayagüela',
                'Francisco Morazán',
              ),
            ]
          : [
              _location(
                'san-marcos',
                'San Marcos de Colón',
                'San Marcos de Colón',
                'Choluteca',
              ),
            ],
      availabilityMessage: query.originId == null ? null : message,
    );
  }

  @override
  Future<ServiceRequestDetail> createRequest(
    CreateServiceRequestInput input,
  ) async {
    created = input;
    throw AppFailure(
      message: 'Datos inválidos.',
      statusCode: 400,
      fieldErrors: {
        errorField!: ['El departamento de esta ubicación no es válido.'],
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RequestCreationLocationOption _location(
  String id,
  String name,
  String city,
  String department,
) => RequestCreationLocationOption(
  branchId: 'branch-$id',
  branchName: name,
  location: RequestCreationLocation(
    id: 'location-$id',
    name: name,
    typeCode: 'SUCURSAL',
    address: 'Dirección de prueba',
    city: city,
    municipality: city,
    department: department,
  ),
);
