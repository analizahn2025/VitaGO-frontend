import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_theme.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/models/auth_state.dart';
import 'package:vitago_app/features/authentication/views/login_view.dart';

void main() {
  testWidgets('muestra la identidad visual corporativa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpLogin(tester, AppMode.corporate);

    expect(find.text('VitaGo Corporate'), findsOneWidget);
    expect(find.text('Logística clínica, en movimiento.'), findsOneWidget);
    expect(find.byKey(const Key('corporate_brand_mark')), findsOneWidget);
    expect(find.byKey(const Key('network_brand_mark')), findsNothing);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    final brandImage = tester.widget<Image>(
      find.byKey(const Key('corporate_brand_mark')),
    );
    final resizedImage = brandImage.image as ResizeImage;
    expect(resizedImage.width, 384);
    expect(resizedImage.height, 384);

    await expectLater(
      find.byType(LoginView),
      matchesGoldenFile('goldens/corporate_login.png'),
    );
  });

  testWidgets('mantiene una identidad independiente para Network', (
    tester,
  ) async {
    await _pumpLogin(tester, AppMode.external);

    expect(find.text('VitaGo Network'), findsOneWidget);
    expect(find.byKey(const Key('network_brand_mark')), findsOneWidget);
    expect(find.byKey(const Key('corporate_brand_mark')), findsNothing);
  });

  testWidgets('mantiene el formulario desplazable con el teclado visible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetViewInsets();
    });

    await _pumpLogin(tester, AppMode.corporate);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}

Future<void> _pumpLogin(WidgetTester tester, AppMode mode) async {
  final config = AppConfig(
    mode: mode,
    apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authControllerProvider.overrideWith(_FakeAuthController.new),
      ],
      child: MaterialApp(
        theme: AppTheme.forMode(mode),
        home: const LoginView(),
      ),
    ),
  );
  await tester.pump();
  if (mode == AppMode.corporate) {
    final context = tester.element(find.byType(LoginView));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/corporate/app_icon.png'),
        context,
      ),
    );
  }
  await tester.pumpAndSettle();
}

class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}
