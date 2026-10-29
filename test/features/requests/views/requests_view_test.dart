import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/core/network/api_client.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository_impl.dart';
import 'package:vitago_app/features/requests/services/requests_api_service.dart';
import 'package:vitago_app/features/requests/views/requests_view.dart';

const _company = '395be863-81e1-4196-a668-b698af836653';

void main() {
  testWidgets('lista resultados de otras cuentas y respeta la paginación', (
    tester,
  ) async {
    final api = _Api();
    await _open(tester, api);
    expect(api.calls.single.path, 'solicitudes/');
    expect(api.calls.single.queryParameters, {
      'empresa_id': _company,
      'pagina': 1,
      'tamano_pagina': 20,
    });
    expect(find.text('SOL-OTRO-0'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('Página siguiente'), 600);
    expect(find.text('21 registros · Página 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(api.calls.last.queryParameters['pagina'], 2);
    expect(api.calls.last.queryParameters['empresa_id'], _company);
    expect(find.text('SOL-OTRO-20'), findsOneWidget);
    expect(find.text('21 registros · Página 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Página anterior'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Estado'), -600);
    await tester.tap(
      find.ancestor(
        of: find.text('Estado'),
        matching: find.byType(DropdownButtonFormField<String?>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendiente').last);
    await tester.pumpAndSettle();
    expect(api.calls.last.queryParameters, {
      'empresa_id': _company,
      'pagina': 1,
      'tamano_pagina': 20,
      'estado': 'PENDING',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresca al volver al listado y al reanudar la app', (
    tester,
  ) async {
    final api = _Api();
    final active = await _open(tester, api);
    active.value = false;
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(1));
    api.updated = true;
    active.value = true;
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(2));
    expect(find.text('SOL-NUEVA-0'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(3));
    expect(api.calls.every((call) => call.path == 'solicitudes/'), isTrue);
  });

  testWidgets('administrador sin empresa conserva alcance del servidor', (
    tester,
  ) async {
    final api = _Api();
    await _open(tester, api, company: null);
    expect(api.calls.single.queryParameters, {
      'pagina': 1,
      'tamano_pagina': 20,
    });
    expect(find.text('SOL-OTRO-0'), findsOneWidget);
  });
}

Future<ValueNotifier<bool>> _open(
  WidgetTester tester,
  _Api api, {
  String? company = _company,
}) async {
  final active = ValueNotifier(true);
  addTearDown(active.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            mode: AppMode.corporate,
            apiBaseUri: Uri.parse('http://localhost/api/v1/'),
          ),
        ),
        requestsRepositoryProvider.overrideWithValue(api.repository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, child) => RequestsView(
              isActive: value,
              profile: UserProfile(
                user: const ProfileUser(
                  id: 'admin',
                  email: 'admin@example.com',
                  firstNames: 'Administradora',
                  lastNames: 'Prueba',
                  status: 'ACTIVO',
                ),
                roles: const [],
                permissions: const [AppPermissions.viewRequests],
                company: company == null
                    ? null
                    : ProfileOrganization(id: company, name: 'Empresa'),
                branch: const ProfileOrganization(
                  id: 'branch',
                  name: 'Sucursal',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return active;
}

class _Api {
  _Api() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          final secondPage = options.queryParameters['pagina'] == 2;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'conteo': 21,
                'pagina_siguiente': secondPage
                    ? null
                    : '/api/v1/solicitudes/?pagina=2',
                'pagina_anterior': secondPage
                    ? '/api/v1/solicitudes/?pagina=1'
                    : null,
                'resultados': [
                  for (
                    var i = secondPage ? 20 : 0;
                    i < (secondPage ? 21 : 20);
                    i++
                  )
                    {
                      'id': 'request-$i',
                      'numero': 'SOL-${updated ? 'NUEVA' : 'OTRO'}-$i',
                      'empresa_id': _company,
                      'solicitada_por_id': 'other-user-$i',
                      'prioridad': 'NORMAL',
                      'modalidad': 'ENTRE_SUCURSALES',
                      'tipo_servicio': {
                        'id': 'type',
                        'codigo': 'DOCUMENTO',
                        'nombre': 'Documento',
                      },
                      'origen': {
                        'id': 'origin',
                        'nombre': 'Origen',
                        'direccion': 'Centro',
                      },
                      'destino': {
                        'id': 'destination',
                        'nombre': 'Destino',
                        'direccion': 'Norte',
                      },
                      'presentacion_ruta': 'MAPA',
                      'estado': 'PENDING',
                      'creado_en': '2026-10-26T10:00:00Z',
                    },
                ],
              },
            ),
          );
        },
      ),
    );
    repository = RequestsRepositoryImpl(
      RequestsApiService(
        ApiClient(
          dio: dio,
          readAuthorization: () async => null,
          refreshAuthorization: () async => null,
          invalidateAuthorization: () async {},
        ),
      ),
    );
  }

  late final RequestsRepositoryImpl repository;
  final calls = <RequestOptions>[];
  bool updated = false;
}
