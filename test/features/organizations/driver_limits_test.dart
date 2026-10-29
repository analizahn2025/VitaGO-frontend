import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/permissions/administrative_scope.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/organizations/models/driver_limits.dart';
import 'package:vitago_app/features/organizations/providers/organizations_providers.dart';
import 'package:vitago_app/features/organizations/repositories/organizations_repository.dart';
import 'package:vitago_app/features/organizations/services/organizations_api_service.dart';
import 'package:vitago_app/features/organizations/views/driver_limits_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

import '../../support/admin_contract_fixtures.dart';

void main() {
  for (final status in [400, 403, 409]) {
    test('servicio conserva campos de validación HTTP$status', () async {
      final api = ContractApi(
        (options) => (
          status: status,
          data: {
            'limite_tubos': [
              'La configuración no puede aplicarse a este alcance.',
            ],
          },
        ),
      );
      try {
        await OrganizationsApiService(api.client).updateDriverLimits(
          null,
          const UpdateDriverLimitsInput(tubeLimit: 10),
        );
        fail('Debía rechazar el cambio.');
      } on AppFailure catch (failure) {
        expect(failure.statusCode, status);
        expect(
          failure.fieldMessage('limite_tubos'),
          'La configuración no puede aplicarse a este alcance.',
        );
      }
    });
  }
  test(
    'empresa conserva límites efectivos y no inventa configuración incompleta',
    () {
      final company = Company.fromJson({
        'id': reportCompanyId,
        'nombre': 'Analiza',
        'estado': 'ACTIVO',
        'limites_motoristas': {
          'alcance': 'EMPRESA',
          'limite_tubos': 25,
          'limite_solicitudes': 3,
        },
      });
      expect(company.driverLimits!.tubeLimit, 25);
      expect(company.driverLimits!.requestLimit, 3);
      expect(
        () => DriverLimits.fromJson({'alcance': 'RED'}),
        throwsFormatException,
      );
      expect(
        () => DriverLimits.fromJson({
          'alcance': 'RED',
          'limite_tubos': 25,
          'limite_solicitudes': 6,
        }),
        throwsFormatException,
      );
    },
  );
  test('edición exige permiso del alcance completo, sin heredar repartidor.administrar', () {
    final corporate = administrativeProfile(
      permissions: ['empresa.ver', 'empresa.administrar'],
      scope: ScopeType.company,
    );
    expect(
      canEditDriverLimits(
        corporate,
        corporate: true,
        companyId: reportCompanyId,
      ),
      isTrue,
    );
    expect(
      canEditDriverLimits(corporate, corporate: true, companyId: 'otra'),
      isFalse,
    );
    expect(
      canEditDriverLimits(
        administrativeProfile(
          permissions: ['empresa.administrar'],
          scope: ScopeType.branch,
        ),
        corporate: true,
        companyId: reportCompanyId,
      ),
      isFalse,
    );
    expect(
      canEditDriverLimits(
        administrativeProfile(permissions: ['repartidor.administrar']),
        corporate: true,
        companyId: reportCompanyId,
      ),
      isFalse,
    );
    expect(
      canEditDriverLimits(
        administrativeProfile(permissions: ['configuracion.administrar']),
        corporate: false,
      ),
      isTrue,
    );
    expect(canEditDriverLimits(corporate, corporate: false), isFalse);
  });
  test(
    'GET/PATCH por empresa o red envían solo los límites elegidos',
    () async {
      final api = ContractApi(
        (options) => (
          status: 200,
          data: {
            'alcance': options.path.contains('empresas/') ? 'EMPRESA' : 'RED',
            if (options.path.contains('empresas/'))
              'empresa_id': reportCompanyId,
            'limite_tubos': 25,
            'limite_solicitudes': 3,
          },
        ),
      );
      final service = OrganizationsApiService(api.client);
      await service.getDriverLimits(reportCompanyId);
      expect(api.calls.last.method, 'GET');
      expect(
        api.calls.last.path,
        'organizaciones/empresas/$reportCompanyId/limites-motoristas/',
      );
      await service.updateDriverLimits(
        reportCompanyId,
        const UpdateDriverLimitsInput(requestLimit: 3),
      );
      expect(api.calls.last.method, 'PATCH');
      expect(api.calls.last.data, {'limite_solicitudes': 3});
      await service.getDriverLimits(null);
      expect(
        api.calls.last.path,
        'organizaciones/configuracion/limites-motoristas/',
      );
      await service.updateDriverLimits(
        null,
        const UpdateDriverLimitsInput(tubeLimit: 25, reason: ' Ajuste '),
      );
      expect(api.calls.last.data, {'limite_tubos': 25, 'motivo': 'Ajuste'});
      expect(
        api.calls.any((call) => call.path.startsWith('repartidores/')),
        isFalse,
      );
      final before = api.calls.length;
      await expectLater(
        service.updateDriverLimits(null, const UpdateDriverLimitsInput()),
        throwsA(isA<AppFailure>()),
      );
      expect(api.calls.length, before);
    },
  );
  for (final mode in AppMode.values) {
    testWidgets(
      'guarda límite compartido $mode sin cambio individual ni motivo obligatorio',
      (tester) async {
        final repository = _LimitsRepository(mode);
        final permissions = mode == AppMode.corporate
            ? ['empresa.ver', 'empresa.administrar']
            : ['configuracion.administrar'];
        await _open(
          tester,
          repository,
          administrativeProfile(permissions: permissions),
        );
        final tubes = find.widgetWithText(TextFormField, 'Límite de tubos');
        final requests = find.widgetWithText(
          TextFormField,
          'Límite de solicitudes',
        );
        for (final value in ['0', '6', '1.5']) {
          await tester.enterText(requests, value);
          await tester.tap(find.text('Guardar cupos'));
          await tester.pumpAndSettle();
          expect(repository.updates, isEmpty);
        }
        await tester.enterText(tubes, '25');
        await tester.enterText(requests, '3');
        await tester.tap(find.text('Guardar cupos'));
        await tester.pumpAndSettle();
        expect(repository.updates.single.toJson(), {
          'limite_tubos': 25,
          'limite_solicitudes': 3,
        });
        expect(
          repository.updatedCompany,
          mode == AppMode.corporate ? reportCompanyId : null,
        );
        expect(find.text('Abrir cupos'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'rol de sucursal consulta sin poder editar y el permiso antiguo no habilita',
    (tester) async {
      final repository = _LimitsRepository(AppMode.corporate);
      await _open(
        tester,
        repository,
        administrativeProfile(
          permissions: [
            'empresa.ver',
            'empresa.administrar',
            'repartidor.administrar',
          ],
          scope: ScopeType.branch,
        ),
      );
      expect(find.text('Guardar cupos'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Límite de tubos'),
            )
            .enabled,
        isFalse,
      );
      expect(repository.updates, isEmpty);
    },
  );
  for (final status in [400, 403, 409]) {
    testWidgets(
      'rechazo$status conserva límites propuestos y muestra el campo del servidor',
      (tester) async {
        final repository = _LimitsRepository(AppMode.corporate)
          ..failure = AppFailure(
            message: 'No se pudo aplicar el cambio.',
            statusCode: status,
            fieldErrors: const {
              'limite_tubos': [
                'Regulariza primero las cantidades desconocidas.',
              ],
            },
          );
        await _open(
          tester,
          repository,
          administrativeProfile(
            permissions: ['empresa.ver', 'empresa.administrar'],
          ),
        );
        final field = find.widgetWithText(TextFormField, 'Límite de tubos');
        await tester.enterText(field, '10');
        await tester.pump();
        await tester.tap(find.text('Guardar cupos'));
        await tester.pumpAndSettle();
        expect(
          find.text('Regulariza primero las cantidades desconocidas.'),
          findsOneWidget,
        );
        expect(tester.widget<TextFormField>(field).controller!.text, '10');
        expect(find.textContaining('conexión'), findsNothing);
      },
    );
  }
}

Future<void> _open(
  WidgetTester tester,
  _LimitsRepository repository,
  UserProfile profile,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            mode: repository.mode,
            apiBaseUri: Uri.parse('http://localhost/api/v1/'),
          ),
        ),
        organizationsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.forMode(repository.mode),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => DriverLimitsView(
                    profile: profile,
                    companyId: repository.mode == AppMode.corporate
                        ? reportCompanyId
                        : null,
                  ),
                ),
              ),
              child: const Text('Abrir cupos'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir cupos'));
  await tester.pumpAndSettle();
}

class _LimitsRepository implements OrganizationsRepository {
  _LimitsRepository(this.mode);
  final AppMode mode;
  AppFailure? failure;
  final updates = <UpdateDriverLimitsInput>[];
  String? updatedCompany;
  @override
  Future<DriverLimits> getDriverLimits(String? companyId) async => DriverLimits(
    scope: mode == AppMode.corporate ? 'EMPRESA' : 'RED',
    companyId: companyId,
    tubeLimit: 20,
    requestLimit: 5,
  );
  @override
  Future<DriverLimits> updateDriverLimits(
    String? companyId,
    UpdateDriverLimitsInput input,
  ) async {
    updates.add(input);
    updatedCompany = companyId;
    if (failure != null) throw failure!;
    return DriverLimits(
      scope: mode == AppMode.corporate ? 'EMPRESA' : 'RED',
      companyId: companyId,
      tubeLimit: input.tubeLimit ?? 20,
      requestLimit: input.requestLimit ?? 5,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
