import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';
import 'package:vitago_app/features/routes/views/driver_route_map_view.dart';

class DriverRouteSection extends ConsumerStatefulWidget {
  const DriverRouteSection({
    required this.canCalculate,
    required this.onOpenRequest,
    this.profile,
    super.key,
  });

  final bool canCalculate;
  final ValueChanged<String> onOpenRequest;
  final UserProfile? profile;

  @override
  ConsumerState<DriverRouteSection> createState() => _DriverRouteSectionState();
}

class _DriverRouteSectionState extends ConsumerState<DriverRouteSection> {
  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(myRouteProvider);
    return routeState.when(
      loading: () => const _RouteLoadingCard(),
      error: (error, stackTrace) =>
          _RouteErrorCard(onRetry: () => ref.invalidate(myRouteProvider)),
      data: _buildRoute,
    );
  }

  Widget _buildRoute(DriverRoute route) {
    final colors = Theme.of(context).colorScheme;
    final road = route.roadRoute;
    final next = route.nextStop;
    final nextAddress = next?.location?.address;
    return Semantics(
      container: true,
      label: 'Tu ruta de trabajo',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.surface),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.route_outlined, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi ruta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          route.stops.isEmpty
                              ? 'No tienes paradas pendientes.'
                              : '${route.stops.length} parada${route.stops.length == 1 ? '' : 's'} en el orden de tu ruta',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _RouteStatusPill(status: road.status),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'SIGUIENTE PARADA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  next.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${next.actionLabel} · ${next.requestNumber}${nextAddress == null || nextAddress.isEmpty ? '' : ' · $nextAddress'}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (route.map.showMap &&
                        route.map.mode == 'INTEGRADO' &&
                        route.map.provider == 'GOOGLE_MAPS')
                      FilledButton.icon(
                        onPressed: () => _openMap(route, road),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver mapa'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onOpenRequest(next.requestId),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Ver solicitud'),
                    ),
                  ],
                ),
              ],
              if (route.stops.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                for (final stop in route.stops.skip(1).take(3))
                  _CompactStop(stop: stop),
                if (route.stops.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      '+ ${route.stops.length - 4} paradas más',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMap(DriverRoute route, RoadRoute roadRoute) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'driver-route-map'),
        builder: (context) => DriverRouteMapView(
          route: route,
          roadRoute: roadRoute,
          canCalculate: widget.canCalculate,
          profile: widget.profile,
        ),
      ),
    );
  }
}

class _CompactStop extends StatelessWidget {
  const _CompactStop({required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text('${stop.order}'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stop.actionLabel} · ${stop.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tubos: ${stop.tubeCount ?? 'Sin declarar'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Frascos: ${stop.flaskCount ?? 'No registrado'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStatusPill extends StatelessWidget {
  const _RouteStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'CALCULADA' => ('Calculada', colors.primary),
      'CALCULANDO' => ('Calculando', colors.tertiary),
      'NO_CONFIGURADA' => ('Sin trazado', colors.secondary),
      'SIN_PARADAS' => ('Sin paradas', colors.outline),
      'SOLO_KILOMETROS' => ('Especial', colors.secondary),
      'FALLIDA' => ('No disponible', colors.error),
      'VENCIDA' => ('Vencida', colors.error),
      'ITINERARIO_CAMBIO' => ('Actualizada', colors.tertiary),
      _ => ('Pendiente', colors.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RouteLoadingCard extends StatelessWidget {
  const _RouteLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 104,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RouteErrorCard extends StatelessWidget {
  const _RouteErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.route_outlined),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('No fue posible consultar tu ruta.')),
            IconButton(
              onPressed: onRetry,
              tooltip: 'Reintentar',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
