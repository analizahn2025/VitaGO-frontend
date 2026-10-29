import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/core/navigation/route_activity_observer.dart';
import 'package:vitago_app/features/authentication/views/auth_gate_view.dart';
import 'package:vitago_app/features/requests/views/request_route_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    observers: [ref.watch(routeActivityObserverProvider)],
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AuthGateView(),
      ),
      GoRoute(
        path: '/solicitudes/:requestId',
        name: 'request-detail',
        builder: (context, state) =>
            RequestRouteView(requestId: state.pathParameters['requestId']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
