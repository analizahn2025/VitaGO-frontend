import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';
import 'package:vitago_app/features/routes/models/driver_route.dart';
import 'package:vitago_app/features/routes/providers/routes_providers.dart';

class DriverRouteSection extends ConsumerStatefulWidget {
  const DriverRouteSection({
    required this.canCalculate,
    required this.onOpenRequest,
    super.key,
  });

  final bool canCalculate;
  final ValueChanged<String> onOpenRequest;

  @override
  ConsumerState<DriverRouteSection> createState() => _DriverRouteSectionState();
}

class _DriverRouteSectionState extends ConsumerState<DriverRouteSection> {
  bool _calculating = false;
  String? _actionError;
  RoadRoute? _freshCalculation;

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
    final road = _freshCalculation ?? route.roadRoute;
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
                              : '${route.stops.length} parada${route.stops.length == 1 ? '' : 's'} en orden de asignación',
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
                    FilledButton.icon(
                      onPressed: route.navigation == null
                          ? null
                          : () => _openNavigation(route.navigation!),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Navegar'),
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
              if (road.motorcycleWarning case final warning?
                  when warning.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _InfoNote(icon: Icons.two_wheeler_outlined, text: warning),
              ],
              if (road.attribution case final attribution?
                  when attribution.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  attribution,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              if (road.metricsInResponse &&
                  road.estimatedDistanceMeters != null &&
                  road.estimatedDurationSeconds != null) ...[
                const SizedBox(height: AppSpacing.md),
                _EphemeralEstimate(road: road),
              ],
              if (widget.canCalculate &&
                  route.currentVersion != null &&
                  (road.canCalculate || road.canRetry)) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _calculating
                      ? null
                      : () => _confirmCalculation(route, road.canRetry),
                  icon: _calculating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.map_outlined),
                  label: Text(
                    road.canRetry ? 'Reintentar cálculo' : 'Calcular ruta vial',
                  ),
                ),
              ],
              if (_actionError case final message?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: TextStyle(color: colors.error),
                  semanticsLabel: 'Error: $message',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNavigation(RouteNavigation navigation) async {
    setState(() => _actionError = null);
    final opened = await launchUrl(
      navigation.url,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() {
        _actionError = 'No fue posible abrir la navegación en este teléfono.';
      });
    }
  }

  Future<void> _confirmCalculation(DriverRoute route, bool retry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.route_outlined),
        title: Text(retry ? 'Reintentar cálculo' : 'Calcular ruta vial'),
        content: const Text(
          'Se calculará una estimación para el itinerario actual. No cambia el orden ni el estado de tus solicitudes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Calcular'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _calculating = true;
      _actionError = null;
    });
    try {
      final result = await ref
          .read(calculateRouteProvider)
          .calculate(
            CalculateRouteInput(
              currentVersion: route.currentVersion!,
              retry: retry,
            ),
          );
      if (mounted) setState(() => _freshCalculation = result);
    } on AppFailure catch (failure) {
      if (failure.serverCode == 'VERSION_DESACTUALIZADA' ||
          failure.serverCode == 'ITINERARIO_CAMBIO' ||
          failure.serverCode == 'CALCULO_EN_CURSO' ||
          failure.serverCode == 'INTENTO_REEMPLAZADO') {
        ref.invalidate(myRouteProvider);
      }
      if (mounted) setState(() => _actionError = failure.message);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
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
            child: Text(
              '${stop.actionLabel} · ${stop.title}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      'NO_CONFIGURADA' => ('Navegación', colors.secondary),
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

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _EphemeralEstimate extends StatelessWidget {
  const _EphemeralEstimate({required this.road});

  final RoadRoute road;

  @override
  Widget build(BuildContext context) {
    final kilometers = road.estimatedDistanceMeters! / 1000;
    final minutes = (road.estimatedDurationSeconds! / 60).round();
    return _InfoNote(
      icon: Icons.info_outline,
      text:
          'Estimación del recorrido completo: ${kilometers.toStringAsFixed(1)} km · $minutes min. No es una llegada en vivo.',
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
