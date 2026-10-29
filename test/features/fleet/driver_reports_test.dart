import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/administrative_scope.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/fleet/models/driver_report.dart';
import 'package:vitago_app/features/fleet/providers/driver_reports_providers.dart';
import 'package:vitago_app/features/fleet/repositories/driver_reports_repository.dart';
import 'package:vitago_app/features/fleet/services/driver_reports_api_service.dart';
import 'package:vitago_app/features/fleet/views/driver_reports_view.dart';

import '../../support/admin_contract_fixtures.dart';

void main() {
  test('DTO conserva fecha, zona, hitos, carga actual, cero y pendientes', () {
    final json = driverReportFixture();
    (json['kilometraje'] as Map)['kilometros_medidos'] = null;
    (json['kilometraje'] as Map)['kilometros_consolidados'] = '0.000';
    (json['kilometraje'] as Map)['completo'] = false;
    (json['temperaturas'] as Map)['minima_c'] = '0.00';
    (json['temperaturas'] as Map)['promedio_c'] = null;
    final report = DriverDailyReport.fromJson(json);
    expect(report.date, '2026-10-27');
    expect(report.zone, 'America/Tegucigalpa');
    expect(report.assigned, 2);
    expect(report.delivered, 2);
    expect(report.pickedUp, 2);
    expect(report.measuredKm, isNull);
    expect(report.consolidatedKm, '0.000');
    expect(report.minC, '0.00');
    expect(report.averageC, isNull);
    expect(report.currentLoad.tubeLimit, 20);
    expect(report.recentReadings, hasLength(2));
  });
  test(
    'fecha opcional no toma el calendario del dispositivo y valida formato',
    () {
      expect(const DriverReportQuery().toJson(), {
        'pagina': 1,
        'tamano_pagina': 20,
      });
      expect(
        const DriverReportQuery(
          active: false,
          date: '2026-10-27',
          companyId: reportCompanyId,
          page: 2,
        ).toJson(),
        {
          'pagina': 2,
          'tamano_pagina': 20,
          'activo': false,
          'fecha_operativa': '2026-10-27',
          'empresa_id': reportCompanyId,
        },
      );
      for (final invalid in [
        '2026-02-30',
        '27/10/2026',
        '9999-12-31',
        '0000-01-01',
      ]) {
        expect(operationalDateError(invalid), isNotNull);
      }
      expect(operationalDateError(''), isNull);
      expect(operationalDateError('2024-02-29'), isNull);
    },
  );
  test('reportes requieren todos los permisos y alcance de empresa/global', () {
    for (final permission in reportPermissions) {
      expect(
        canViewDriverReports(
          administrativeProfile(
            permissions: reportPermissions
                .where((p) => p != permission)
                .toList(),
          ),
          corporate: true,
        ),
        isFalse,
      );
    }
    expect(
      canViewDriverReports(
        administrativeProfile(scope: ScopeType.branch),
        corporate: true,
        companyId: reportCompanyId,
      ),
      isFalse,
    );
    expect(
      canViewDriverReports(
        administrativeProfile(scope: ScopeType.company),
        corporate: false,
      ),
      isFalse,
    );
    expect(
      canViewDriverReports(
        administrativeProfile(scope: ScopeType.company),
        corporate: true,
        companyId: reportCompanyId,
      ),
      isTrue,
    );
    expect(
      canViewDriverReports(administrativeProfile(), corporate: false),
      isTrue,
    );
  });
  test('los tres endpoints son GET, respetan paginación y null sin filtro por creador', () async {
    final reading = {
      ...(driverReportFixture()['temperaturas']['ultimas_lecturas'] as List)
              .first
          as Map<String, dynamic>,
      'temperatura_contenedor_c': null,
      'fuente_temperatura': null,
    };
    final api = ContractApi(
      (options) => (
        status: 200,
        data: options.path.endsWith('/resumen/')
            ? driverReportFixture()
            : {
                'conteo': 1,
                'pagina_siguiente': null,
                'pagina_anterior': null,
                'resultados': [
                  options.path.endsWith('/temperaturas/')
                      ? reading
                      : driverReportFixture(),
                ],
              },
      ),
    );
    final service = DriverReportsApiService(api.client);
    final list = await service.getReports(
      const DriverReportQuery(companyId: reportCompanyId),
    );
    expect(list.items, hasLength(1));
    expect(api.calls.last.path, 'repartidores/resumenes/');
    expect(
      api.calls.last.queryParameters.containsKey('solicitada_por_id'),
      isFalse,
    );
    final detail = await service.getReport(
      list.items.single.driverId,
      '2026-10-27',
    );
    expect(api.calls.last.path, 'repartidores/${detail.driverId}/resumen/');
    final readings = await service.getTemperatures(
      detail.driverId,
      detail.date,
      2,
    );
    expect(readings.items.single.temperature, isNull);
    expect(api.calls.last.queryParameters, {
      'fecha_operativa': '2026-10-27',
      'pagina': 2,
      'tamano_pagina': 20,
    });
    expect(api.calls.every((call) => call.method == 'GET'), isTrue);
  });
  for (final status in [400, 403, 404]) {
    test(
      'API de reportes conserva HTTP$status sin llamarlo conexión',
      () async {
        final api = ContractApi(
          (options) => (
            status: status,
            data: status == 400
                ? {
                    'fecha_operativa': ['Fecha inválida.'],
                  }
                : {'detail': 'Reporte fuera de alcance o no disponible.'},
          ),
        );
        try {
          await DriverReportsApiService(api.client)
              .getReports(const DriverReportQuery());
          fail('Debía rechazar la respuesta.');
        } on AppFailure catch (failure) {
          expect(failure.statusCode, status);
          if (status == 400) {
            expect(failure.fieldMessage('fecha_operativa'), 'Fecha inválida.');
          }
          expect(failure.message, isNot(contains('conexión')));
        }
      },
    );
  }
  testWidgets(
    'lista incluye inactivos, pagina y fija fecha del servidor al abrir detalle',
    (tester) async {
      final repository = _Reports();
      await _pump(
        tester,
        repository,
        DriverReportsView(profile: administrativeProfile()),
      );
      expect(repository.queries.single.date, isNull);
      expect(repository.queries.single.active, isNull);
      expect(repository.queries.single.companyId, isNull);
      await _scrollUntilVisible(
        tester,
        find.byTooltip('Página siguiente'),
        300,
      );
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(repository.queries.last.page, 2);
      expect(find.textContaining('Inactivo'), findsOneWidget);
      await tester.tap(find.text('Motorista De prueba'));
      await tester.pumpAndSettle();
      expect(repository.details.single.date, '2026-10-27');
      expect(find.text('Actividad del día'), findsOneWidget);
    },
  );
  testWidgets(
    'fecha imposible no dispara consulta ni sustituye fecha del servidor',
    (tester) async {
      final repository = _Reports();
      await _pump(
        tester,
        repository,
        DriverReportsView(profile: administrativeProfile()),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha operativa (opcional)'),
        '2026-02-30',
      );
      await tester.tap(find.text('Consultar reporte'));
      await tester.pumpAndSettle();
      expect(repository.queries, hasLength(1));
      expect(find.text('La fecha no existe.'), findsOneWidget);
    },
  );
  for (final mode in AppMode.values) {
    testWidgets('alcance de sucursal/cliente no consulta reportes de $mode', (
      tester,
    ) async {
      final repository = _Reports();
      await _pump(
        tester,
        repository,
        DriverReportsView(
          profile: administrativeProfile(
            scope: mode == AppMode.corporate
                ? ScopeType.branch
                : ScopeType.company,
          ),
        ),
        mode: mode,
      );
      expect(find.text('Sin acceso a reportes'), findsOneWidget);
      expect(repository.queries, isEmpty);
    });
  }
  testWidgets(
    'detalle distingue km pendientes, cero grados y carga actual; temperaturas paginadas',
    (tester) async {
      final repository = _Reports()..incomplete = true;
      await _pump(
        tester,
        repository,
        DriverReportDetailView(
          profile: administrativeProfile(),
          driverId: 'driver',
          companyId: reportCompanyId,
          date: '2026-10-27',
        ),
      );
      expect(find.text('Actividad del día'), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        find.text('Km de jornadas cerradas'),
        300,
      );
      expect(find.text('Medidos: Sin medición'), findsOneWidget);
      expect(find.text('Consolidados: 0.000 km'), findsOneWidget);
      expect(find.text('Medición incompleta o pendiente'), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        find.text('Ver todas las lecturas'),
        300,
      );
      expect(find.textContaining('0.00 °C'), findsWidgets);
      await tester.tap(find.text('Ver todas las lecturas'));
      await tester.pumpAndSettle();
      expect(repository.temperatures.single.date, '2026-10-27');
      expect(find.textContaining('Sin registrar'), findsOneWidget);
      expect(find.textContaining('08:00'), findsOneWidget);
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(repository.temperatures.last.page, 2);
      expect(find.textContaining('0.00 °C'), findsOneWidget);
    },
  );
  for (final size in [const Size(320, 568), const Size(667, 375)]) {
    testWidgets(
      'reporte largo en $size con texto grande conserva carga parcial',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(
          tester,
          _Reports()..incomplete = true,
          DriverReportDetailView(
            profile: administrativeProfile(),
            driverId: 'driver',
            companyId: reportCompanyId,
          ),
          textScale: 2,
          dark: size.width > size.height,
        );

        await _scrollUntilVisible(tester, find.text('Carga actual'), 300);
        expect(find.textContaining('Estado al consultar'), findsOneWidget);
        await _scrollUntilVisible(
          tester,
          find.textContaining('Comprometidos conocidos (parcial)'),
          300,
        );
        expect(find.text('Disponibles: 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Reports repository,
  Widget view, {
  AppMode mode = AppMode.corporate,
  double textScale = 1,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            mode: mode,
            apiBaseUri: Uri.parse('http://localhost/api/v1/'),
          ),
        ),
        driverReportsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.forMode(mode),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: view,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Reports implements DriverReportsRepository {
  final queries = <DriverReportQuery>[];
  final details = <({String id, String? date})>[];
  final temperatures = <({String date, int page})>[];
  bool incomplete = false;
  DriverDailyReport _report({bool active = true}) {
    final json = driverReportFixture();
    (json['repartidor'] as Map)['activo'] = active;
    if (incomplete) {
      (json['kilometraje'] as Map<String, dynamic>).addAll({
        'kilometros_medidos': null,
        'kilometros_consolidados': '0.000',
        'completo': false,
        'jornadas_sin_cierre_en_periodo': 1,
      });
      (json['temperaturas'] as Map)['minima_c'] = '0.00';
      (json['carga_actual'] as Map<String, dynamic>).addAll({
        'tubos_comprometidos': 18,
        'solicitudes_sin_cantidad_tubos': 1,
        'tubos_disponibles': 0,
        'capacidad': 'FULL',
      });
    }
    return DriverDailyReport.fromJson(json);
  }

  @override
  Future<PaginatedResult<DriverDailyReport>> getReports(
    DriverReportQuery query,
  ) async {
    queries.add(query);
    return PaginatedResult(
      count: 2,
      items: [_report(active: query.page == 1)],
      hasNext: query.page == 1,
      hasPrevious: query.page == 2,
    );
  }

  @override
  Future<DriverDailyReport> getReport(String id, String? date) async {
    details.add((id: id, date: date));
    return _report();
  }

  @override
  Future<PaginatedResult<DriverTemperatureReading>> getTemperatures(
    String id,
    String date,
    int page,
  ) async {
    temperatures.add((date: date, page: page));
    return PaginatedResult(
      count: 2,
      items: [
        DriverTemperatureReading(
          id: 'reading',
          requestId: 'request',
          number: 'SOL-HISTORICA',
          capturedAt: DateTime.utc(2026, 10, 27, 14),
          temperature: page == 1 ? null : '0.00',
          source: page == 1 ? null : 'MANUAL',
        ),
      ],
      hasNext: page == 1,
      hasPrevious: page == 2,
    );
  }
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  double delta,
) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}
