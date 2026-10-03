import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/core/models/paginated_result.dart';
import 'package:vitago_app/core/permissions/app_permissions.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location.dart';
import 'package:vitago_app/features/locations/views/locations_view.dart';
import 'package:vitago_app/features/organizations/controllers/organizations_controller.dart';
import 'package:vitago_app/features/organizations/models/company.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

void main() {
  testWidgets('muestra el encabezado y la orientación cuando no hay lugares', (
    tester,
  ) async {
    await _pumpLocations(tester, locations: const []);
    await tester.pumpAndSettle();

    expect(find.text('Lugares'), findsOneWidget);
    expect(find.text('Empresa de prueba'), findsOneWidget);
    expect(find.text('Registrar lugar'), findsOneWidget);
    expect(find.text('No hay lugares registrados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'muestra los lugares en una pantalla móvil sin errores de layout',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpLocations(tester, locations: const [_companyLocation]);
      await tester.pumpAndSettle();

      expect(find.text('Lugares'), findsOneWidget);
      expect(find.text('Bodega principal'), findsOneWidget);
      expect(find.textContaining('Origen y Destino'), findsOneWidget);
      expect(find.text('APROBADO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el superadministrador puede seleccionar empresa sin pantalla en blanco',
    (tester) async {
      const query = (companyId: 'company-id', page: 1, pageSize: 20);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companySelectionControllerProvider.overrideWith(
              (ref) async => _companyPage(const [_company]),
            ),
            locationsControllerProvider(query)
                .overrideWith((ref) async => _page(const [_companyLocation])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LocationsView(
                profile: _profile(const [
                  AppPermissions.viewLocations,
                  AppPermissions.createLocations,
                  AppPermissions.viewCompanies,
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Bodega principal'), findsOneWidget);
      expect(find.text('Registrar lugar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('informa cuando el perfil no puede consultar lugares', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: LocationsView(profile: _profile(const []))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso a ubicaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLocations(
  WidgetTester tester, {
  required List<CompanyLocation> locations,
}) {
  const query = (companyId: 'company-id', page: 1, pageSize: 20);

  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        locationsControllerProvider(query)
            .overrideWith((ref) async => _page(locations)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LocationsView(
            profile: _profile(const [
              AppPermissions.viewLocations,
              AppPermissions.createLocations,
            ]),
          ),
        ),
      ),
    ),
  );
}

PaginatedResult<CompanyLocation> _page(List<CompanyLocation> locations) {
  return PaginatedResult(
    count: locations.length,
    items: locations,
    hasNext: false,
    hasPrevious: false,
  );
}

PaginatedResult<Company> _companyPage(List<Company> companies) {
  return PaginatedResult(
    count: companies.length,
    items: companies,
    hasNext: false,
    hasPrevious: false,
  );
}

UserProfile _profile(List<String> permissions) {
  return UserProfile(
    user: const ProfileUser(
      id: 'user-id',
      email: 'admin@empresa.com',
      firstNames: 'Admin',
      lastNames: 'VitaGo',
      status: 'ACTIVO',
    ),
    company: const ProfileOrganization(
      id: 'company-id',
      name: 'Empresa de prueba',
    ),
    roles: const [],
    permissions: permissions,
  );
}

const _companyLocation = CompanyLocation(
  id: 'company-location-id',
  companyId: 'company-id',
  allowsOrigin: true,
  allowsDestination: true,
  status: 'APROBADO',
  location: Location(
    id: 'location-id',
    name: 'Bodega principal',
    source: 'MANUAL',
    address: 'Avenida principal, Tegucigalpa',
    status: 'ACTIVO',
    verified: true,
  ),
);

const _company = Company(
  id: 'company-id',
  name: 'Empresa de prueba',
  status: 'ACTIVO',
  country: Country(
    id: 'country-id',
    iso2: 'HN',
    name: 'Honduras',
    currencyCode: 'HNL',
    defaultTimeZone: 'America/Tegucigalpa',
  ),
);
