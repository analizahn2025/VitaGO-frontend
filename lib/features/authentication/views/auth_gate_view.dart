import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/models/auth_state.dart';
import 'package:vitago_app/features/authentication/views/authenticated_home_view.dart';
import 'package:vitago_app/features/authentication/views/corporate_auth_view.dart';
import 'package:vitago_app/features/authentication/views/login_view.dart';

class AuthGateView extends ConsumerWidget {
  const AuthGateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authentication = ref.watch(authControllerProvider);

    return authentication.when(
      loading: () => const _LoadingView(),
      error: (error, stackTrace) => _BootstrapErrorView(
        onRetry: () => ref.invalidate(authControllerProvider),
      ),
      data: (authState) {
        return switch (authState.status) {
          AuthenticationStatus.unauthenticated => const LoginView(),
          AuthenticationStatus.corporateAuthenticationRequired =>
            const CorporateAuthView(),
          AuthenticationStatus.authenticated =>
            authState.session == null
                ? _BootstrapErrorView(
                    onRetry: () => ref.invalidate(authControllerProvider),
                  )
                : const AuthenticatedHomeView(),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No fue posible preparar la aplicación.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisa la conexión e inténtalo nuevamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
