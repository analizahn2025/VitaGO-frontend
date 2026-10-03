import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/core/widgets/async_state_view.dart';
import 'package:vitago_app/features/authentication/controllers/auth_controller.dart';
import 'package:vitago_app/features/authentication/models/auth_state.dart';
import 'package:vitago_app/features/authentication/views/corporate_auth_view.dart';
import 'package:vitago_app/features/authentication/views/login_view.dart';
import 'package:vitago_app/features/profile/controllers/profile_controller.dart';
import 'package:vitago_app/features/requests/views/request_detail_view.dart';

/// Authentication-aware entry point for request links and notifications.
class RequestRouteView extends ConsumerWidget {
  const RequestRouteView({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authentication = ref.watch(authControllerProvider);
    return authentication.when(
      loading: () => const Scaffold(
        body: SafeArea(child: AppLoadingView(label: 'Preparando solicitud…')),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
        ),
      ),
      data: (state) => switch (state.status) {
        AuthenticationStatus.unauthenticated => const LoginView(),
        AuthenticationStatus.corporateAuthenticationRequired =>
          const CorporateAuthView(),
        AuthenticationStatus.authenticated => _ProfileRequestRoute(
          requestId: requestId,
        ),
      },
    );
  }
}

class _ProfileRequestRoute extends ConsumerWidget {
  const _ProfileRequestRoute({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return profile.when(
      loading: () => const Scaffold(
        body: SafeArea(child: AppLoadingView(label: 'Cargando tu perfil…')),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: AppErrorView(
            error: error,
            onRetry: () =>
                ref.read(profileControllerProvider.notifier).refreshProfile(),
          ),
        ),
      ),
      data: (value) => RequestDetailView(requestId: requestId, profile: value),
    );
  }
}
