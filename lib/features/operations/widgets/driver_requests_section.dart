import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/operations/models/driver_delivery_board.dart';
import 'package:vitago_app/features/operations/widgets/delivery_request_tile.dart';

class DriverRequestsSection extends StatelessWidget {
  const DriverRequestsSection({
    required this.board,
    required this.onRetry,
    required this.onOpenRequest,
    this.showHistory = false,
    this.title = 'Servicios de hoy',
    super.key,
  });

  final AsyncValue<DriverDeliveryBoard> board;
  final bool showHistory;
  final String title;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              onPressed: onRetry,
              tooltip: 'Actualizar servicios',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        board.when(
          loading: () => const _DeliveryLoading(),
          error: (error, stackTrace) => _DeliveryError(onRetry: onRetry),
          data: (value) {
            final requests = showHistory ? value.history : value.inProgress;
            if (requests.isEmpty) {
              return _DeliveryEmpty(showHistory: showHistory);
            }
            final colors = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.surface),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < requests.length; index++) ...[
                    if (index > 0) const Divider(),
                    DeliveryRequestTile(
                      request: requests[index],
                      onTap: () => onOpenRequest(requests[index].id),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DeliveryLoading extends StatelessWidget {
  const _DeliveryLoading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: const Row(
        children: [
          Icon(Icons.delivery_dining_outlined),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Consultando servicios asignados…')),
        ],
      ),
    );
  }
}

class _DeliveryError extends StatelessWidget {
  const _DeliveryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_outlined, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No fue posible cargar tus servicios.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _DeliveryEmpty extends StatelessWidget {
  const _DeliveryEmpty({required this.showHistory});

  final bool showHistory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            showHistory ? Icons.history : Icons.inventory_2_outlined,
            size: 40,
            color: colors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            showHistory
                ? 'No hay servicios finalizados visibles.'
                : 'No tienes servicios en curso.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
