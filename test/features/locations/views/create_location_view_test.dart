import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/features/locations/controllers/locations_controller.dart';
import 'package:vitago_app/features/locations/models/location_type.dart';
import 'package:vitago_app/features/locations/views/create_location_view.dart';
import 'package:vitago_app/features/organizations/models/company.dart';

void main() {
  testWidgets('muestra los cuatro campos territoriales del contrato', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_corporateConfig),
          locationTypesControllerProvider.overrideWith(
            (ref) async => const [
              LocationType(
                id: 'branch-type-id',
                code: 'SUCURSAL',
                name: 'Sucursal',
              ),
              LocationType(
                id: 'transport-type-id',
                code: 'EMPRESA_TRANSPORTE',
                name: 'Empresa de transporte',
              ),
              LocationType(
                id: 'hospital-type-id',
                code: 'HOSPITAL',
                name: 'Hospital',
              ),
              LocationType(
                id: 'pharmacy-type-id',
                code: 'FARMACIA',
                name: 'Farmacia',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: CreateLocationView(company: _company)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Departamento'), findsOneWidget);
    expect(find.text('Municipio'), findsOneWidget);
    expect(find.text('Ciudad'), findsOneWidget);
    expect(find.text('Colonia'), findsOneWidget);
    expect(find.textContaining('nivel administrativo'), findsNothing);
    expect(find.text('Localidad'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Sucursal'), findsOneWidget);
    expect(find.text('Empresa de transporte'), findsOneWidget);
    expect(find.text('Hospital'), findsNothing);
    expect(find.text('Farmacia'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _corporateConfig = AppConfig(
  mode: AppMode.corporate,
  apiBaseUri: Uri.parse('https://corporate.example.com/api/v1/'),
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
