import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/config/identity_provider.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/fleet/views/create_vehicle_view.dart';
import 'package:vitago_app/features/fleet/views/vehicles_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

void main() {
  testWidgets('los filtros de vehículos no desbordan en pantalla angosta', (
    tester,
  ) async {
    _useNarrowScreen(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesControllerProvider(const VehicleQuery())
              .overrideWith((ref) async => _emptyVehicles()),
        ],
        child: MaterialApp(
          theme: AppTheme.forMode(AppMode.corporate),
          home: Scaffold(
            body: SafeArea(child: VehiclesView(profile: _profile())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Motocicletas'), findsOneWidget);
    expect(find.text('Tipo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario de vehículo no desborda en pantalla angosta', (
    tester,
  ) async {
    _useNarrowScreen(tester);
    final config = AppConfig(
      mode: AppMode.external,
      apiBaseUri: Uri.parse('http://127.0.0.1:8000/api/v1/'),
      identityProvider: IdentityProvider.local,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: MaterialApp(
          theme: AppTheme.forMode(AppMode.external),
          home: CreateVehicleView(profile: _profile()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Datos de la motocicleta'), findsOneWidget);
    expect(find.text('Tipo'), findsNothing);
    expect(find.textContaining('Capacidad'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

PaginatedResult<Vehicle> _emptyVehicles() {
  return const PaginatedResult(
    count: 0,
    items: [],
    hasNext: false,
    hasPrevious: false,
  );
}

UserProfile _profile() {
  return UserProfile(
    user: const ProfileUser(
      id: 'admin-id',
      email: 'admin@vitago.com',
      firstNames: 'Admin',
      lastNames: 'VitaGo',
      status: 'ACTIVO',
    ),
    roles: const [],
    permissions: const [
      AppPermissions.viewVehicles,
      AppPermissions.manageVehicles,
    ],
  );
}
