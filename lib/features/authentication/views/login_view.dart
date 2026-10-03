import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/config/app_config.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/views/widgets/auth_error_banner.dart';
import 'package:vitago_app/features/authentication/views/widgets/login_brand_header.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authControllerProvider).value;
    final isProcessing = authState?.isProcessing ?? false;
    final emailApiError = authState?.fieldErrors['correo']?.firstOrNull;
    final passwordApiError = authState?.fieldErrors['contrasena']?.firstOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final formMinHeight = math.max(
            0.0,
            constraints.maxHeight - AppSizes.loginHeroHeight,
          );

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: LoginBrandHeader(
                  appName: config.appName,
                  isCorporate: config.isCorporate,
                ),
              ),
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: formMinHeight),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadii.surface),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: keyboardInset),
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSizes.loginContentMaxWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xl,
                                AppSpacing.lg,
                                AppSpacing.lg,
                              ),
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Bienvenido de nuevo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Ingresa tus datos para continuar.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      if (authState?.message
                                          case final message?) ...[
                                        const SizedBox(height: AppSpacing.lg),
                                        AuthErrorBanner(message: message),
                                      ],
                                      const SizedBox(height: AppSpacing.xl),
                                      TextFormField(
                                        controller: _emailController,
                                        enabled: !isProcessing,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.username,
                                        ],
                                        autocorrect: false,
                                        maxLength: 254,
                                        decoration: InputDecoration(
                                          labelText: 'Correo electrónico',
                                          hintText: 'usuario@empresa.com',
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                          errorText: emailApiError,
                                          counterText: '',
                                        ),
                                        validator: _validateEmail,
                                        onTapOutside: (_) => _dismissKeyboard(),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextFormField(
                                        controller: _passwordController,
                                        enabled: !isProcessing,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        maxLength: 128,
                                        decoration: InputDecoration(
                                          labelText: 'Contraseña',
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          errorText: passwordApiError,
                                          counterText: '',
                                          suffixIcon: IconButton(
                                            onPressed: isProcessing
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    });
                                                  },
                                            tooltip: _obscurePassword
                                                ? 'Mostrar contraseña'
                                                : 'Ocultar contraseña',
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                        validator: _validatePassword,
                                        onFieldSubmitted: (_) =>
                                            _submit(isProcessing),
                                        onTapOutside: (_) => _dismissKeyboard(),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      FilledButton(
                                        onPressed: isProcessing
                                            ? null
                                            : () => _submit(isProcessing),
                                        child: isProcessing
                                            ? SizedBox.square(
                                                dimension: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          colorScheme.onPrimary,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('Iniciar sesión'),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_person_outlined,
                                            size: 18,
                                            color: colorScheme.outline,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Flexible(
                                            child: Text(
                                              'Acceso protegido en este dispositivo',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.outline,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    return null;
  }

  void _submit(bool isProcessing) {
    if (isProcessing || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
