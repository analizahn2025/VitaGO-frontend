import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/config/identity_provider.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/authentication/views/authenticated_home_view.dart';
import 'package:vitago_app/features/profile/controllers/profile_controller.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/managed_user.dart';
import 'package:vitago_app/features/user_administration/views/users_view.dart';

void main() {
  testWidgets('mantiene visible el encabezado mientras carga', (tester) async {
    final pending = Completer<PaginatedResult<ManagedUser>>();

    await _pumpUsers(
      tester,
      profile: _superAdminProfile(),
      loadUsers: () => pending.future,
    );

    expect(find.text('Cargando usuarios…'), findsOneWidget);
  });

  testWidgets('muestra una orientación cuando no existen usuarios', (
    tester,
  ) async {
    await _pumpUsers(
      tester,
      profile: _superAdminProfile(),
      loadUsers: () async => _page(const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay usuarios visibles'), findsOneWidget);
    expect(find.text('Crear usuario'), findsOneWidget);
  });

  testWidgets('muestra los usuarios recibidos', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = ManagedUser(
      id: 'managed-user-id',
      email: 'persona@empresa.com',
      firstNames: 'Ana',
      lastNames: 'López',
      status: 'ACTIVO',
      roles: [
        ScopedRole(
          code: 'ADMINISTRADOR_CORPORATIVO',
          name: 'Administrador corporativo',
          scopeType: ScopeType.company,
        ),
        ScopedRole(
          code: 'SUPERADMINISTRADOR',
          name: 'Superadministrador',
          scopeType: ScopeType.global,
        ),
      ],
    );

    await _pumpUsers(
      tester,
      profile: _superAdminProfile(),
      loadUsers: () async => _page(const [user]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana López'), findsOneWidget);
    expect(find.textContaining('Administrador corporativo'), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
  });

  testWidgets('muestra el error sin ocultar el encabezado', (tester) async {
    await _pumpUsers(
      tester,
      profile: _superAdminProfile(),
      loadUsers: () async =>
          throw const AppFailure(message: 'No fue posible consultar usuarios.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('No fue posible consultar usuarios.'), findsOneWidget);
  });

  testWidgets('oculta Crear si faltan permisos administrativos', (
    tester,
  ) async {
    await _pumpUsers(
      tester,
      profile: _profileWithPermissions(const [AppPermissions.viewUsers]),
      loadUsers: () async => _page(const [
        ManagedUser(
          id: 'managed-user-id',
          email: 'persona@empresa.com',
          firstNames: 'Ana',
          lastNames: 'López',
          status: 'ACTIVO',
          roles: [],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear'), findsNothing);
    expect(find.text('Ana López'), findsOneWidget);
  });

  testWidgets('la navegación autenticada monta el contenido de Usuarios', (
    tester,
  ) async {
    final profile = _superAdminProfile();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://127.0.0.1:8001/api/v1/'),
              identityProvider: IdentityProvider.local,
            ),
          ),
          profileControllerProvider.overrideWith(
            () => _ResolvedProfileController(profile),
          ),
          usersControllerProvider(1)
              .overrideWith((ref) async => _page(const [])),
        ],
        child: const MaterialApp(home: AuthenticatedHomeView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Usuarios'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usuarios'), findsNWidgets(2));
    expect(find.text('No hay usuarios visibles'), findsOneWidget);
  });

  testWidgets('limita la barra inferior a cinco destinos en pantalla angosta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = _profileWithPermissions(const [
      AppPermissions.viewCompanies,
      AppPermissions.viewUsers,
      AppPermissions.viewLocations,
      AppPermissions.viewRequests,
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://127.0.0.1:8001/api/v1/'),
              identityProvider: IdentityProvider.local,
            ),
          ),
          profileControllerProvider.overrideWith(
            () => _ResolvedProfileController(profile),
          ),
        ],
        child: const MaterialApp(home: AuthenticatedHomeView()),
      ),
    );
    await tester.pumpAndSettle();

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((item) => item.label)
        .toList(growable: false);
    expect(destinations, [
      'Inicio',
      'Solicitudes',
      'Usuarios',
      'Lugares',
      'Cuenta',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conserva el desplazamiento al cambiar de pestaña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final users = List.generate(
      30,
      (index) => ManagedUser(
        id: 'user-$index',
        email: 'persona$index@empresa.com',
        firstNames: 'Persona',
        lastNames: '$index',
        status: 'ACTIVO',
        roles: const [],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              mode: AppMode.corporate,
              apiBaseUri: Uri.parse('http://127.0.0.1:8001/api/v1/'),
              identityProvider: IdentityProvider.local,
            ),
          ),
          profileControllerProvider.overrideWith(
            () => _ResolvedProfileController(_superAdminProfile()),
          ),
          usersControllerProvider(1).overrideWith((ref) async => _page(users)),
        ],
        child: const MaterialApp(home: AuthenticatedHomeView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Usuarios'),
      ),
    );
    await tester.pumpAndSettle();

    Finder usersScrollable() => find.descendant(
      of: find.byType(UsersView),
      matching: find.byType(Scrollable),
    );
    await tester.drag(usersScrollable(), const Offset(0, -500));
    await tester.pumpAndSettle();
    final previousOffset = tester
        .state<ScrollableState>(usersScrollable())
        .position
        .pixels;
    expect(previousOffset, greaterThan(0));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cuenta'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Usuarios'),
      ),
    );
    await tester.pumpAndSettle();

    final restoredOffset = tester
        .state<ScrollableState>(usersScrollable())
        .position
        .pixels;
    expect(restoredOffset, closeTo(previousOffset, 0.1));
    expect(tester.takeException(), isNull);
  });
}

class _ResolvedProfileController extends ProfileController {
  _ResolvedProfileController(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> build() async => profile;
}

Future<void> _pumpUsers(
  WidgetTester tester, {
  required UserProfile profile,
  required Future<PaginatedResult<ManagedUser>> Function() loadUsers,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        usersControllerProvider(1).overrideWith((ref) => loadUsers()),
      ],
      child: MaterialApp(
        home: Scaffold(body: UsersView(profile: profile)),
      ),
    ),
  );
}

PaginatedResult<ManagedUser> _page(List<ManagedUser> users) {
  return PaginatedResult(
    count: users.length,
    items: users,
    hasNext: false,
    hasPrevious: false,
  );
}

UserProfile _superAdminProfile() => _profileWithPermissions(const [
  AppPermissions.viewUsers,
  AppPermissions.manageUsers,
  AppPermissions.assignRoles,
]);

UserProfile _profileWithPermissions(List<String> permissions) {
  return UserProfile(
    user: const ProfileUser(
      id: 'admin-id',
      email: 'admin@vitago.com',
      firstNames: 'Admin',
      lastNames: 'VitaGo',
      status: 'ACTIVO',
    ),
    roles: const [
      ScopedRole(
        code: 'SUPERADMINISTRADOR',
        name: 'Superadministrador',
        scopeType: ScopeType.global,
      ),
    ],
    permissions: permissions,
  );
}
