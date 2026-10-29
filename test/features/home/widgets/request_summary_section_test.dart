import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/home/widgets/request_summary_section.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';
import 'package:vitago_app/features/requests/providers/requests_providers.dart';
import 'package:vitago_app/features/requests/repositories/requests_repository.dart';

void main() {
  for (final code in ['ADMINISTRADOR_CORPORATIVO', 'SUPERADMINISTRADOR']) {
    testWidgets('$code no limita el resumen a la sucursal del perfil', (
      tester,
    ) async {
      final repository = _SummaryRepository(_dailySummary());
      await _pumpSummary(
        tester,
        repository,
        profile: UserProfile(
          user: _profile.user,
          company: _profile.company,
          branch: _profile.branch,
          permissions: _profile.permissions,
          roles: [
            ScopedRole(
              code: code,
              name: code,
              scopeType: code == 'SUPERADMINISTRADOR'
                  ? ScopeType.global
                  : ScopeType.company,
            ),
          ],
        ),
      );
      expect(repository.queries.single.toQueryParameters(), {
        'empresa_id': 'company-id',
      });
      expect(
        tester.widget<Text>(find.byKey(const Key('daily_delivery_total'))).data,
        '2',
      );
    });
  }

  testWidgets('muestra carga pendiente, en progreso y entregas del día', (
    tester,
  ) async {
    final repository = _SummaryRepository(_dailySummary());

    await _pumpSummary(tester, repository);

    expect(find.text('Resumen de envíos'), findsOneWidget);
    expect(find.text('Entregadas hoy'), findsOneWidget);
    expect(find.byKey(const Key('daily_delivery_total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('daily_delivery_total'))).data,
      '2',
    );
    expect(find.text('SOL-HOY'), findsOneWidget);
    expect(find.text('SOL-HISTORICA'), findsNothing);
    expect(find.text('99'), findsNothing);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En progreso'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('pending_requests_total'))).data,
      '5',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('active_requests_total'))).data,
      '10',
    );
    expect(find.text('Actividad reciente'), findsNothing);
    expect(repository.queries.single.toQueryParameters(), {
      'empresa_id': 'company-id',
      'sucursal_id': 'branch-id',
    });
  });

  testWidgets(
    'usa la fecha operativa y la hora de entrega en su zona horaria',
    (tester) async {
      await _pumpSummary(tester, _SummaryRepository(_dailySummary()));

      expect(find.textContaining('22/10/2026'), findsWidgets);
      expect(find.textContaining('12:30'), findsOneWidget);
      expect(find.textContaining('21/10/2026'), findsNothing);
      expect(find.textContaining('18:30'), findsNothing);
    },
  );

  testWidgets('un día sin entregas no muestra el historial acumulado', (
    tester,
  ) async {
    await _pumpSummary(
      tester,
      _SummaryRepository(_dailySummary(count: 0, deliveries: [])),
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('daily_delivery_total'))).data,
      '0',
    );
    expect(find.text('Aún no hay entregas realizadas hoy.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('pending_requests_total'))).data,
      '5',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('active_requests_total'))).data,
      '10',
    );
    expect(find.text('SOL-HISTORICA'), findsNothing);
    expect(find.text('99'), findsNothing);
  });

  testWidgets('el contrato anterior no inventa cero y permite reintentar', (
    tester,
  ) async {
    final repository = _SummaryRepository(
      RequesterSummary.fromJson(_historicalSummaryJson()),
    );
    await _pumpSummary(tester, repository);

    expect(
      find.text('El resumen de hoy aún no está disponible.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('daily_delivery_total')), findsNothing);
    expect(find.text('SOL-HISTORICA'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);

    repository.summary = _dailySummary();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(2));
    expect(find.text('SOL-HOY'), findsOneWidget);
    expect(find.byKey(const Key('daily_delivery_total')), findsOneWidget);
  });

  testWidgets('se adapta a una pantalla pequeña con texto grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSummary(
      tester,
      _SummaryRepository(_dailySummary()),
      textScale: 2,
    );

    expect(find.text('Resumen de envíos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('En progreso'), findsOneWidget);
    expect(find.text('Entregadas hoy'), findsOneWidget);
    expect(find.text('SOL-HOY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(667, 375), const Size(768, 1024)]) {
    testWidgets('adapta los contadores en $size con texto grande', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpSummary(
        tester,
        _SummaryRepository(_dailySummary()),
        textScale: 2,
      );
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('En progreso'), findsOneWidget);
      expect(find.text('Entregadas hoy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('refresca al volver y cada minuto solo en la pantalla activa', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    final repository = _SummaryRepository(_dailySummary());
    await _pumpSummary(tester, repository, active: active);
    expect(repository.queries, hasLength(1));

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(repository.queries, hasLength(2));

    active.value = false;
    await tester.pump();
    await tester.pump(const Duration(minutes: 1));
    expect(repository.queries, hasLength(2));

    active.value = true;
    await tester.pumpAndSettle();
    expect(repository.queries, hasLength(3));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 1));
    expect(repository.queries, hasLength(3));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.queries, hasLength(4));
  });

  testWidgets('no solapa peticiones mientras espera una actualización', (
    tester,
  ) async {
    final pending = Completer<RequesterSummary>();
    final repository = _SummaryRepository(_dailySummary())
      ..onGet = (call) => call == 1 ? null : pending.future;
    await _pumpSummary(tester, repository);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(repository.queries, hasLength(2));

    await tester.pump(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.queries, hasLength(2));

    pending.complete(_dailySummary());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSummary(
  WidgetTester tester,
  _SummaryRepository repository, {
  ValueNotifier<bool>? active,
  double textScale = 1,
  UserProfile? profile,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  Widget section(bool isActive) => RequestSummarySection(
    profile: profile ?? _profile,
    onOpenRequests: () {},
    isActive: isActive,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [requestsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.forMode(AppMode.corporate),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: active == null
                ? section(true)
                : ValueListenableBuilder<bool>(
                    valueListenable: active,
                    builder: (context, isActive, child) => section(isActive),
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SummaryRepository implements RequestsRepository {
  _SummaryRepository(this.summary);

  RequesterSummary summary;
  final queries = <RequesterSummaryQuery>[];
  Future<RequesterSummary>? Function(int call)? onGet;

  @override
  Future<RequesterSummary> getRequesterSummary(
    RequesterSummaryQuery query,
  ) async {
    queries.add(query);
    return onGet?.call(queries.length) ?? summary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RequesterSummary _dailySummary({
  int count = 2,
  List<Map<String, dynamic>>? deliveries,
}) => RequesterSummary.fromJson({
  ..._historicalSummaryJson(),
  'fecha_operativa': '2026-10-22',
  'zona_horaria_operativa': 'America/Tegucigalpa',
  'entregadas_del_dia': count,
  'entregas_recientes_del_dia': deliveries ?? [_deliveryJson()],
});

Map<String, dynamic> _historicalSummaryJson() => {
  'total': 120,
  'pendientes': 5,
  'activas': 10,
  'entregadas': 99,
  'fallidas': 1,
  'canceladas': 5,
  'recientes': [
    {..._deliveryJson(), 'id': 'historical-id', 'numero': 'SOL-HISTORICA'},
  ],
};

Map<String, dynamic> _deliveryJson() => {
  'id': 'daily-id',
  'numero': 'SOL-HOY',
  'empresa_id': 'company-id',
  'solicitada_por_id': 'requester-id',
  'prioridad': 'NORMAL',
  'modalidad': 'ENTRE_SUCURSALES',
  'tipo_servicio': {'id': 'service-id', 'codigo': 'ENVIO', 'nombre': 'Envío'},
  'origen': {
    'id': 'origin-id',
    'nombre': 'Sucursal de origen',
    'direccion': 'Dirección de origen',
  },
  'destino': {
    'id': 'destination-id',
    'nombre': 'Sucursal de destino',
    'direccion': 'Dirección de destino',
  },
  'presentacion_ruta': 'MAPA',
  'estado': 'DELIVERED',
  'creado_en': '2026-10-21T20:00:00Z',
  'entregada_en': '2026-10-22T18:30:00Z',
};

final _profile = UserProfile(
  user: const ProfileUser(
    id: 'requester-id',
    email: 'solicitante@example.com',
    firstNames: 'Steven',
    lastNames: 'Rivera',
    status: 'ACTIVO',
  ),
  company: const ProfileOrganization(id: 'company-id', name: 'Analiza'),
  branch: const ProfileOrganization(
    id: 'branch-id',
    name: 'Sucursal principal',
  ),
  roles: const [],
  permissions: const ['solicitud.ver'],
);
