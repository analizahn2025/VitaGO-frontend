import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/validation/operational_values.dart';
import 'package:vitago_app/core/widgets/edit_operational_count_view.dart';
import 'package:vitago_app/features/evidence/models/operational_evidence.dart';
import 'package:vitago_app/features/evidence/services/evidence_api_service.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/providers/fleet_providers.dart';
import 'package:vitago_app/features/fleet/repositories/fleet_repository_impl.dart';
import 'package:vitago_app/features/fleet/services/fleet_api_service.dart';
import 'package:vitago_app/features/organizations/views/driver_limits_view.dart';
import 'package:vitago_app/features/organizations/models/driver_limits.dart';
import 'package:vitago_app/features/organizations/services/organizations_api_service.dart';
import 'package:vitago_app/features/fleet/widgets/driver_tube_load.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository_impl.dart';
import 'package:vitago_app/features/requests/views/assign_request_view.dart';
import 'package:vitago_app/features/requests/views/update_request_load_view.dart';
import 'package:vitago_app/features/requests/services/requests_api_service.dart';

void main() {
  for (final mode in AppMode.values) {
    testWidgets(
      'asignación $mode acepta pedido de2 con2 libres y muestra409 real',
      (tester) async {
        final calls = <RequestOptions>[];
        var reads = 0;
        final client = _client((options) {
          calls.add(options);
          if (options.method == 'POST') {
            return {
              'repartidor_id': ['El motorista ya no dispone de cupo.'],
            };
          }
          reads++;
          return {
            'conteo': reads == 1 ? 1 : 0,
            'pagina_siguiente': null,
            'pagina_anterior': null,
            'resultados': reads == 1
                ? [
                    {
                      ..._driver(),
                      'empresa_id': mode == AppMode.corporate
                          ? 'company'
                          : null,
                    },
                  ]
                : [],
          };
        }, rejectAssignment: true);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig(
                  mode: mode,
                  apiBaseUri: Uri.parse('http://localhost/api/v1/'),
                ),
              ),
              fleetRepositoryProvider.overrideWithValue(
                FleetRepositoryImpl(FleetApiService(client)),
              ),
              requestsRepositoryProvider.overrideWithValue(
                RequestsRepositoryImpl(RequestsApiService(client)),
              ),
            ],
            child: MaterialApp(
              home: AssignRequestView(
                request: ServiceRequestDetail.fromJson(_request(2)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls.single.queryParameters['cantidad_tubos'], 2);
        expect(calls.single.queryParameters['cantidad_frascos'], 0);
        expect(calls.single.queryParameters.containsKey('empresa_id'), isFalse);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Motorista Prueba · 2 tubos · 20 frascos libres').last,
        );
        await tester.pumpAndSettle();
        final button = find.widgetWithText(FilledButton, 'Asignar motorista');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(calls.where((call) => call.method == 'POST').single.data, {
          'repartidor_id': 'driver',
          'motivo': null,
        });
        expect(
          find.text('El motorista ya no dispone de cupo.'),
          findsOneWidget,
        );
        expect(reads, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'cantidades enteras y temperatura decimal sin reglas clínicas inventadas',
    () {
      for (final text in ['', '0', '-1', '1.5', '2147483648', 'NaN']) {
        expect(tubeCountError(text), isNotNull);
      }
      for (final text in ['1', '20', '2147483647']) {
        expect(tubeCountError(text), isNull);
      }
      for (final text in [
        '',
        'NaN',
        'Infinity',
        '10000',
        '-10000',
        '4.501',
        '1e2',
      ]) {
        expect(containerTemperatureError(text), isNotNull);
      }
      for (final text in ['-9999.99', '9999.99', '-12', '0', '4,50', '45.50']) {
        expect(containerTemperatureError(text), isNull);
      }
      expect(normalizeTemperature(' 4,50 '), '4.50');
    },
  );

  test('históricos conservan cantidad y temperatura desconocidas', () {
    expect(
      ServiceRequestDetail.fromJson(_request(null)).summary.tubeCount,
      isNull,
    );
    expect(OperationalEvidence.fromJson(_evidence(null)).temperatureC, isNull);
    expect(
      OperationalEvidence.fromJson(_evidence('4.50')).temperatureC,
      '4.50',
    );
    final driver = DriverProfile.fromJson(_driver());
    expect(driver.tubeLimit, 20);
    expect(driver.committedTubes, 18);
    expect(driver.availableTubes, 2);
    expect(driver.transportedTubes, 0);
    expect(driver.reservedTubes, 18);
  });

  test(
    'consulta disponibles por tubos y usa endpoints PATCH independientes',
    () async {
      final calls = <RequestOptions>[];
      final client = _client((options) {
        calls.add(options);
        if (options.method == 'GET') {
          return {
            'conteo': 1,
            'pagina_siguiente': null,
            'pagina_anterior': null,
            'resultados': [_driver()],
          };
        }
        return options.path.startsWith('organizaciones/')
            ? {
                'empresa_id': 'company',
                'alcance': 'EMPRESA',
                'limite_tubos': 30,
                'limite_solicitudes': 5,
              }
            : _request(3);
      });
      final fleet = FleetApiService(client);
      final eligible = await fleet.getAvailableDrivers(tubeCount: 2);
      expect(eligible.items.single.canReceiveRequests, isTrue);
      expect(eligible.items.single.availableTubes, 2);
      expect(calls.single.queryParameters, {
        'pagina': 1,
        'tamano_pagina': 100,
        'cantidad_tubos': 2,
      });
      await fleet.getAvailableDrivers(tubeCount: 0, flaskCount: 3);
      expect(calls.last.queryParameters['cantidad_frascos'], 3);
      await OrganizationsApiService(client).updateDriverLimits(
        'company',
        const UpdateDriverLimitsInput(
          tubeLimit: 30,
          reason: ' Contenedor nuevo ',
        ),
      );
      expect(calls.last.method, 'PATCH');
      expect(
        calls.last.path,
        'organizaciones/empresas/company/limites-motoristas/',
      );
      expect(calls.last.data, {
        'limite_tubos': 30,
        'motivo': 'Contenedor nuevo',
      });
      final detail = await RequestsApiService(client)
          .updateTubeCount('request', 3, ' Conteo real ');
      expect(detail.summary.tubeCount, 3);
      expect(calls.last.path, 'solicitudes/request/carga/');
      expect(calls.last.data, {'cantidad_tubos': 3, 'motivo': 'Conteo real'});
      await RequestsApiService(client).updateLoad(
        'request',
        const UpdateRequestLoadInput(
          tubeCount: 0,
          flaskCount: 4,
          reason: 'Conteo de frascos',
        ),
      );
      expect(calls.last.path, 'solicitudes/request/carga/');
      expect(calls.last.data, {
        'cantidad_tubos': 0,
        'cantidad_frascos': 4,
        'motivo': 'Conteo de frascos',
      });
    },
  );

  test(
    'multipart lleva temperatura solo en recolección, nunca fuente del cliente',
    () async {
      final temp = await Directory.systemTemp.createTemp('vitago-evidence-');
      addTearDown(() => temp.delete(recursive: true));
      final file = await File('${temp.path}/photo.jpg').writeAsBytes([1, 2, 3]);
      final calls = <RequestOptions>[];
      final service = EvidenceApiService(
        _client((options) {
          calls.add(options);
          return _evidence('4.50');
        }, status: 201),
      );
      EvidenceUploadInput input(String type) => EvidenceUploadInput(
        filePath: file.path,
        fileName: 'photo.jpg',
        latitude: '14',
        longitude: '-87',
        type: type,
        temperatureC: '4,50',
      );
      await service.uploadRequestEvidence('request', input('FOTO_RECOLECCION'));
      final fields = Map.fromEntries((calls.last.data as FormData).fields);
      expect(fields['temperatura_contenedor_c'], '4.50');
      expect(fields.containsKey('fuente_temperatura'), isFalse);
      expect((calls.last.data as FormData).files.single.key, 'archivo');
      for (final type in ['FOTO_ENTREGA', 'FOTO_INCIDENCIA']) {
        await service.uploadRequestEvidence('request', input(type));
        expect(
          Map.fromEntries((calls.last.data as FormData).fields)
              .containsKey('temperatura_contenedor_c'),
          isFalse,
        );
      }
      await service.uploadIncidentEvidence(
        'incident',
        input('FOTO_INCIDENCIA'),
      );
      expect(
        Map.fromEntries((calls.last.data as FormData).fields)
            .containsKey('temperatura_contenedor_c'),
        isFalse,
      );
    },
  );

  test('409 conserva el error de cupo asociado al motorista', () {
    final options = RequestOptions(path: 'solicitudes/request/asignaciones/');
    final failure = AppFailure.fromDio(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'repartidor_id': [
              'El motorista dispone de 2 tubos de cupo; la solicitud requiere 3.',
            ],
          },
        ),
      ),
    );
    expect(failure.isConflict, isTrue);
    expect(
      failure.fieldMessage('repartidor_id'),
      contains('dispone de 2 tubos'),
    );
    expect(failure.message, isNot(contains('conexión')));
  });

  test('solo administración regulariza null recogido; terminales y conocidos no cambian', () {
    final admin = _profile(['solicitud.asignar']);
    for (final status in [
      'PENDING',
      'ASSIGNED',
      'GOING_TO_PICKUP',
      'AT_PICKUP',
    ]) {
      expect(
        canUpdateRequestLoad(
          ServiceRequestDetail.fromJson(_request(3, status: status)),
          admin,
        ),
        isTrue,
      );
    }
    for (final status in ['PICKED_UP', 'IN_TRANSIT', 'AT_DESTINATION']) {
      expect(
        canUpdateRequestLoad(
          ServiceRequestDetail.fromJson(_request(null, status: status)),
          admin,
        ),
        isTrue,
      );
      expect(
        canUpdateRequestLoad(
          ServiceRequestDetail.fromJson(_request(3, status: status)),
          admin,
        ),
        isFalse,
      );
    }
    expect(
      canUpdateRequestLoad(
        ServiceRequestDetail.fromJson(_request(null, status: 'DELIVERED')),
        admin,
      ),
      isFalse,
    );
    expect(
      canUpdateRequestLoad(
        ServiceRequestDetail.fromJson(_request(null)),
        _profile([]),
      ),
      isFalse,
    );
  });

  testWidgets('motorista sin permiso no puede editar su límite', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://localhost/api/v1/'),
            ),
          ),
        ],
        child: MaterialApp(
          home: DriverLimitsView(companyId: 'company', profile: _profile([])),
        ),
      ),
    );
    expect(find.text('Sin acceso a cupos'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'editor conserva cantidad y motivo cuando el servidor rechaza cupo',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EditOperationalCountView(
            title: 'Corregir tubos',
            label: 'Cantidad de tubos',
            fieldName: 'cantidad_tubos',
            onSave: (count, reason) async {
              calls++;
              expect(count, 18);
              expect(reason, 'Conteo confirmado');
              throw const AppFailure(
                message: 'Revisa los datos ingresados.',
                statusCode: 400,
                fieldErrors: {
                  'cantidad_tubos': ['Supera el cupo disponible.'],
                },
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cantidad de tubos'),
        '18',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Motivo'),
        'Conteo confirmado',
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Supera el cupo disponible.'), findsWidgets);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Cantidad de tubos'),
            )
            .controller!
            .text,
        '18',
      );
      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Motivo'))
            .controller!
            .text,
        'Conteo confirmado',
      );
    },
  );

  for (final size in [const Size(320, 568), const Size(667, 375)]) {
    testWidgets('carga desconocida se identifica como parcial en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final driver = DriverProfile.fromJson({
        ..._driver(),
        'capacidad': 'FULL',
        'tubos_disponibles': 0,
        'solicitudes_sin_cantidad_tubos': 1,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: DriverTubeLoad(driver: driver),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Comprometidos conocidos (parcial)'),
        findsOneWidget,
      );
      expect(find.text('Disponibles: 0'), findsOneWidget);
      expect(find.text('Ocupado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

ApiClient _client(
  Map<String, dynamic> Function(RequestOptions) respond, {
  int status = 200,
  bool rejectAssignment = false,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final response = Response(
          requestOptions: options,
          statusCode: rejectAssignment && options.method == 'POST'
              ? 409
              : status,
          data: respond(options),
        );
        if (response.statusCode == 409) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
        } else {
          handler.resolve(response);
        }
      },
    ),
  );
  return ApiClient(
    dio: dio,
    readAuthorization: () async => null,
    refreshAuthorization: () async => null,
    invalidateAuthorization: () async {},
  );
}

Map<String, dynamic> _driver() => {
  'id': 'driver',
  'empresa_id': null,
  'usuario': {
    'id': 'user',
    'correo': 'driver@example.com',
    'nombres': 'Motorista',
    'apellidos': 'Prueba',
    'estado': 'ACTIVO',
  },
  'estado_operativo': 'ON_ROUTE',
  'capacidad': 'AVAILABLE_SPACE',
  'activo': true,
  'solicitudes_activas': 1,
  'limite_solicitudes': 5,
  'puede_recibir_solicitudes': true,
  'limite_tubos': 20,
  'tubos_comprometidos': 18,
  'tubos_en_transporte': 0,
  'tubos_reservados': 18,
  'tubos_disponibles': 2,
  'solicitudes_sin_cantidad_tubos': 0,
  'limite_frascos': 20,
  'frascos_comprometidos': 0,
  'frascos_en_transporte': 0,
  'frascos_reservados': 0,
  'frascos_disponibles': 20,
  'solicitudes_sin_cantidad_frascos': 0,
  'creado_en': '2026-10-27T12:00:00Z',
  'actualizado_en': '2026-10-27T12:00:00Z',
};
Map<String, dynamic> _request(int? tubes, {String status = 'PENDING'}) => {
  'id': 'request',
  'numero': 'SOL-39',
  'empresa_id': 'company',
  'solicitada_por_id': 'user',
  'cantidad_tubos': tubes,
  'cantidad_frascos': 0,
  'prioridad': 'NORMAL',
  'modalidad': 'ENTRE_SUCURSALES',
  'tipo_servicio': {'id': 'type', 'codigo': 'MUESTRAS', 'nombre': 'Muestras'},
  'origen': {'id': 'origin', 'nombre': 'Origen', 'direccion': 'Centro'},
  'presentacion_ruta': 'MAPA',
  'estado': status,
  'articulos': [],
  'eventos': [],
  'asignaciones': [],
  'creado_en': '2026-10-27T12:00:00Z',
  'actualizado_en': '2026-10-27T12:00:00Z',
};
Map<String, dynamic> _evidence(String? temperature) => {
  'id': 'evidence',
  'solicitud_id': 'request',
  'estado_solicitud': 'PICKED_UP',
  'tipo': 'FOTO_RECOLECCION',
  'temperatura_contenedor_c': temperature,
  'fuente_temperatura': temperature == null ? null : 'MANUAL',
  'tipo_contenido': 'image/jpeg',
  'tamano_bytes': 3,
  'latitud': '14',
  'longitud': '-87',
  'capturada_en': '2026-10-27T12:00:00Z',
  'creado_en': '2026-10-27T12:00:00Z',
  'archivo_disponible': true,
};
UserProfile _profile(List<String> permissions) => UserProfile(
  user: const ProfileUser(
    id: 'user',
    email: 'user@example.com',
    firstNames: 'Usuario',
    lastNames: 'Prueba',
    status: 'ACTIVO',
  ),
  roles: const [],
  permissions: permissions,
);
