import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/features/home/models/app_section.dart';
import 'package:vitago_app/features/home/views/home_overview_view.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';

void main() {
  testWidgets('muestra el contexto operativo corporativo', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = UserProfile.fromJson({
      'usuario': {
        'id': 'user-id',
        'correo': 'steven@analiza.com',
        'nombres': 'Steven',
        'apellidos': 'Rivera',
        'telefono': null,
        'estado': 'ACTIVO',
      },
      'empresa': {'id': 'company-id', 'nombre': 'Analiza'},
      'sucursal': {'id': 'branch-id', 'nombre': 'Sucursal principal'},
      'roles': [
        {
          'codigo': 'CORPORATE_ADMIN',
          'nombre': 'Administrador corporativo',
          'tipo_alcance': 'EMPRESA',
          'empresa_id': 'company-id',
          'sucursal_id': null,
        },
      ],
      'permisos': ['empresa.ver', 'usuario.ver', 'ubicacion.ver'],
    });
    final config = AppConfig(mode: AppMode.corporate, apiBaseUri: _testApiUri);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forMode(AppMode.corporate),
        home: Scaffold(
          body: HomeOverviewView(
            config: config,
            profile: profile,
            availableSections: AvailableAppSections.forProfile(profile),
            onSelectSection: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Hola, Steven'), findsOneWidget);
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Lugares'), findsOneWidget);
    await expectLater(
      find.byType(HomeOverviewView),
      matchesGoldenFile('goldens/corporate_home.png'),
    );
  });
}

final Uri _testApiUri = Uri.parse('https://api.example.com/api/v1/');
