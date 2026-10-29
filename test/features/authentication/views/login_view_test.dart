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

  for (final scenario in [
    (
      name: 'vertical pequena',
      size: const Size(360, 640),
      keyboardHeight: 280.0,
      expandedKeyboardHeight: 320.0,
    ),
    (
      name: 'horizontal',
      size: const Size(640, 400),
      keyboardHeight: 180.0,
      expandedKeyboardHeight: 220.0,
    ),
  ]) {
    testWidgets(
      'mantiene visibles la clave y el acceso con teclado en pantalla '
      '${scenario.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.size;
        addTearDown(() {
          tester.view.resetViewInsets();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await _pumpLogin(tester, AppMode.corporate);

        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;

        // Focus first, then let Flutter react to the keyboard opening.
        await tester.showKeyboard(emailField);
        tester.view.viewInsets = FakeViewPadding(
          bottom: scenario.keyboardHeight,
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(emailField).bottom,
          lessThanOrEqualTo(scenario.size.height - scenario.keyboardHeight + 1),
        );

        await tester.enterText(emailField, 'motorista@vitago.com');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        final passwordInput = tester.widget<EditableText>(
          find.descendant(
            of: passwordField,
            matching: find.byType(EditableText),
          ),
        );
        expect(passwordInput.focusNode.hasFocus, isTrue);
        _expectLoginControlsAboveKeyboard(
          tester,
          unobscuredHeight: scenario.size.height - scenario.keyboardHeight,
        );

        // Suggestion rows and keyboard mode changes must also scroll the form.
        tester.view.viewInsets = FakeViewPadding(
          bottom: scenario.expandedKeyboardHeight,
        );
        await tester.pumpAndSettle();
        _expectLoginControlsAboveKeyboard(
          tester,
          unobscuredHeight:
              scenario.size.height - scenario.expandedKeyboardHeight,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('se adapta a pantalla angosta con texto grande', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpLogin(
      tester,
      AppMode.corporate,
      textScaler: const TextScaler.linear(1.5),
    );

    final tagline = tester.getRect(
      find.text('Logística clínica, en movimiento.'),
    );
    final brand = tester.getRect(find.byKey(const Key('corporate_brand_mark')));
    expect(tagline.bottom, lessThan(brand.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra y bloquea la espera indicada por un 429', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpLogin(
      tester,
      AppMode.corporate,
      textScaler: const TextScaler.linear(1.5),
      initialState: const AuthState.unauthenticated(
        message: 'Se alcanzó el límite de intentos de inicio de sesión.',
        loginRetryAfterSeconds: 125,
      ),
    );

    expect(
      find.text('Se alcanzó el límite de intentos de inicio de sesión.'),
      findsOneWidget,
    );
    expect(
      find.text('Podrás volver a intentarlo en 2 min 5 s.'),
      findsOneWidget,
    );
    expect(find.text('Espera 02:05'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

void _expectLoginControlsAboveKeyboard(
  WidgetTester tester, {
  required double unobscuredHeight,
}) {
  final passwordRect = tester.getRect(find.byType(TextFormField).last);
  final submitRect = tester.getRect(find.byType(FilledButton));

  expect(passwordRect.top, greaterThanOrEqualTo(0));
  expect(passwordRect.bottom, lessThanOrEqualTo(unobscuredHeight + 1));
  expect(submitRect.top, greaterThanOrEqualTo(0));
  expect(submitRect.bottom, lessThanOrEqualTo(unobscuredHeight + 1));
  expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
}

Future<void> _pumpLogin(
  WidgetTester tester,
  AppMode mode, {
  TextScaler textScaler = TextScaler.noScaling,
  AuthState initialState = const AuthState.unauthenticated(),
}) async {
  final config = AppConfig(
    mode: mode,
    apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authControllerProvider.overrideWith(
          () => _FakeAuthController(initialState),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.forMode(mode),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
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
  _FakeAuthController(this.initialState);

  final AuthState initialState;

  @override
  Future<AuthState> build() async => initialState;
}
