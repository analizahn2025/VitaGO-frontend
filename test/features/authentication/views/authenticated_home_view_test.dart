import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_colors.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/authentication/views/authenticated_home_view.dart';
import 'package:vitago_app/features/fleet/controllers/fleet_controller.dart';
import 'package:vitago_app/features/fleet/models/fleet_models.dart';
import 'package:vitago_app/features/notifications/controllers/notifications_controller.dart';
import 'package:vitago_app/features/notifications/models/driver_notification.dart';
import 'package:vitago_app/features/operations/controllers/driver_delivery_controller.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/profile/controllers/profile_controller.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/shifts/controllers/shifts_controller.dart';

void main() {
  testWidgets('el shell delivery hereda la cabecera corporativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://127.0.0.1:8001/api/v1/'),
            ),
          ),
          profileControllerProvider.overrideWith(
            () => _ResolvedProfileController(_driverProfile()),
          ),
          driverDeliveryControllerProvider.overrideWith(
            (ref) async =>
                const DriverDeliveryBoard(inProgress: [], history: []),
          ),
          activeShiftControllerProvider.overrideWith((ref) async => null),
          ownDriverProfileControllerProvider.overrideWith(
            (ref) async => _driverOperationProfile(),
          ),
          driverNotificationsControllerProvider.overrideWith(
            (ref) async => const DriverNotificationFeed(count: 0, items: []),
          ),
          unreadNotificationCountControllerProvider.overrideWith(
            (ref) async => 0,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.forMode(AppMode.corporate),
          home: const AuthenticatedHomeView(),
        ),
      ),
    );
    await tester.pump();

    final theme = Theme.of(tester.element(find.byType(AppBar)));
    expect(theme.appBarTheme.backgroundColor, AppColors.corporate.secondary);
    expect(theme.appBarTheme.foregroundColor, Colors.white);
    expect(theme.appBarTheme.titleTextStyle?.color, Colors.white);
    expect(
      theme.appBarTheme.systemOverlayStyle?.statusBarColor,
      AppColors.corporate.secondary,
    );
    expect(find.text('VitaGo Corporate'), findsOneWidget);

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((destination) => destination.label)
        .toList(growable: false);
    expect(destinations, ['Hoy', 'Historial', 'Cuenta']);
  });
}

class _ResolvedProfileController extends ProfileController {
  _ResolvedProfileController(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> build() async => profile;
}

UserProfile _driverProfile() {
  return UserProfile(
    user: const ProfileUser(
      id: 'driver-id',
      email: 'delivery@vitago.com',
      firstNames: 'Mario',
      lastNames: 'Rider',
      status: 'ACTIVO',
    ),
    roles: const [
      ScopedRole(
        code: 'REPARTIDOR_CORPORATIVO',
        name: 'Repartidor corporativo',
        scopeType: ScopeType.company,
      ),
    ],
    permissions: const [],
  );
}

DriverProfile _driverOperationProfile() {
  return DriverProfile(
    id: 'driver-id',
    user: const DriverUser(
      id: 'driver-id',
      email: 'delivery@vitago.com',
      firstNames: 'Mario',
      lastNames: 'Rider',
      status: 'ACTIVO',
    ),
    operationalStatus: 'AVAILABLE',
    capacity: 'AVAILABLE_SPACE',
    active: true,
    createdAt: DateTime.utc(2026, 9, 30),
    updatedAt: DateTime.utc(2026, 9, 30),
  );
}
