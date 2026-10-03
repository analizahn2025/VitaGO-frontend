import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/models/auth_session.dart';
import 'package:vitago_app/features/authentication/models/auth_state.dart';
import 'package:vitago_app/features/authentication/models/auth_user.dart';
import 'package:vitago_app/features/authentication/models/token_bundle.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/profile/views/profile_view.dart';

void main() {
  testWidgets('oculta diagnóstico y permisos a un usuario normal', (
    tester,
  ) async {
    await _pumpProfile(tester, _profile(master: false));

    expect(find.text('Información de organización'), findsOneWidget);
    expect(find.text('Conectividad'), findsNothing);
    expect(find.text('Permisos vigentes'), findsNothing);
    await expectLater(
      find.byType(ProfileView),
      matchesGoldenFile('goldens/corporate_profile.png'),
    );
  });

  testWidgets('muestra permisos únicamente al administrador maestro', (
    tester,
  ) async {
    await _pumpProfile(tester, _profile(master: true));

    expect(find.text('Permisos vigentes'), findsOneWidget);
  });
}

Future<void> _pumpProfile(WidgetTester tester, UserProfile profile) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(_FakeAuthController.new)],
      child: MaterialApp(
        theme: AppTheme.forMode(AppMode.corporate),
        home: Scaffold(body: ProfileView(profile: profile)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

UserProfile _profile({required bool master}) {
  return UserProfile.fromJson({
    'usuario': {
      'id': 'user-id',
      'correo': 'steven@analiza.com',
      'nombres': 'Steven',
      'apellidos': 'Rivera',
      'telefono': '+504 9999-9999',
      'estado': 'ACTIVO',
    },
    'empresa': {'id': 'company-id', 'nombre': 'Analiza'},
    'sucursal': {'id': 'branch-id', 'nombre': 'Sucursal principal'},
    'roles': [
      {
        'codigo': master ? 'SUPERADMINISTRADOR' : 'CORPORATE_ADMIN',
        'nombre': master
            ? 'Administrador maestro'
            : 'Administrador corporativo',
        'tipo_alcance': master ? 'GLOBAL' : 'EMPRESA',
        'empresa_id': master ? null : 'company-id',
        'sucursal_id': null,
      },
    ],
    'permisos': ['usuario.ver', 'empresa.ver', 'ubicacion.ver'],
  });
}

AuthSession _session() {
  return AuthSession(
    tokens: TokenBundle(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      accessTokenExpiresAt: DateTime.utc(2026, 9, 25),
      refreshTokenExpiresAt: DateTime.utc(2026, 10),
      sessionId: 'session-id',
    ),
    user: const AuthUser(
      id: 'user-id',
      email: 'steven@analiza.com',
      firstNames: 'Steven',
      lastNames: 'Rivera',
    ),
  );
}

class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async => AuthState.authenticated(_session());
}
