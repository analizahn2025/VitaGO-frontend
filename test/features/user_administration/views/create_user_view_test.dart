import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/models/scoped_role.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/branch.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/user_administration/controllers/users_controller.dart';
import 'package:vitago_app/features/user_administration/models/assignable_role.dart';
import 'package:vitago_app/features/user_administration/models/create_user_input.dart';
import 'package:vitago_app/features/user_administration/views/create_user_view.dart';

void main() {
  testWidgets('solicita seleccionar una sucursal antes de cargar roles', (
    tester,
  ) async {
    await _pumpCreateUser(tester, branches: const [_branch]);
    await _selectBranchScope(tester);

    expect(find.text('Selecciona una sucursal primero.'), findsOneWidget);
    expect(find.text('Cargando roles…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informa cuando la empresa no tiene sucursales', (tester) async {
    await _pumpCreateUser(tester, branches: const []);
    await _selectBranchScope(tester);

    expect(
      find.text('Esta empresa no tiene sucursales disponibles.'),
      findsOneWidget,
    );
    expect(find.text('Selecciona una sucursal primero.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valida los datos ingresados antes de crear el usuario', (
    tester,
  ) async {
    await _pumpCreateUser(tester, branches: const [_branch]);

    final phoneField = find.byKey(const Key('create-user-phone'));
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, 'teléfono-inválido');

    final createButton = find.widgetWithText(FilledButton, 'Crear usuario');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));
    expect(
      find.text('Usa entre 8 y 15 dígitos; el prefijo + es opcional.'),
      findsOneWidget,
    );
    expect(find.text('Ingresa una contraseña temporal.'), findsOneWidget);
    expect(find.text('Selecciona un rol.'), findsOneWidget);
    expect(
      find.text('Revisa los campos marcados antes de continuar.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCreateUser(
  WidgetTester tester, {
  required List<Branch> branches,
}) {
  const companyRoleQuery = AssignableRolesQuery(
    scopeType: ScopeType.company,
    companyId: 'company-id',
  );

  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        branchSelectionControllerProvider('company-id')
            .overrideWith((ref) async => _branchPage(branches)),
        assignableRolesControllerProvider(companyRoleQuery).overrideWith(
          (ref) async => const [
            AssignableRole(
              code: 'ADMINISTRADOR_CORPORATIVO',
              name: 'Administrador corporativo',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        home: CreateUserView(
          profile: _profile(),
          usesLocalAuthentication: true,
        ),
      ),
    ),
  );
}

Future<void> _selectBranchScope(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final scopeField = find.byType(DropdownButtonFormField<ScopeType>);
  await tester.ensureVisible(scopeField);
  await tester.tap(scopeField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sucursal').last);
  await tester.pumpAndSettle();
}

PaginatedResult<Branch> _branchPage(List<Branch> branches) {
  return PaginatedResult(
    count: branches.length,
    items: branches,
    hasNext: false,
    hasPrevious: false,
  );
}

UserProfile _profile() {
  return UserProfile(
    user: const ProfileUser(
      id: 'admin-id',
      email: 'admin@empresa.com',
      firstNames: 'Admin',
      lastNames: 'VitaGo',
      status: 'ACTIVO',
    ),
    company: const ProfileOrganization(
      id: 'company-id',
      name: 'Empresa de prueba',
    ),
    roles: const [
      ScopedRole(
        code: 'ADMINISTRADOR_CORPORATIVO',
        name: 'Administrador corporativo',
        scopeType: ScopeType.company,
        companyId: 'company-id',
      ),
    ],
    permissions: const [
      AppPermissions.viewBranches,
      AppPermissions.manageUsers,
      AppPermissions.assignRoles,
    ],
  );
}

const _branch = Branch(
  id: 'branch-id',
  companyId: 'company-id',
  name: 'Sucursal Centro',
  status: 'ACTIVO',
);
