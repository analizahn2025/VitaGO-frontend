import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class DeliveryRequestTile extends StatelessWidget {
  const DeliveryRequestTile({
    required this.request,
    required this.onTap,
    super.key,
  });

  final ServiceRequestSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final routeColor = request.isPriority ? colors.error : colors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 104,
            decoration: BoxDecoration(
              color: routeColor,
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.number,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(status: request.status),
                  ],
                ),
                if (request.isPriority) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Servicio prioritario',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _RouteLine(icon: Icons.trip_origin, value: request.origin.name),
                const SizedBox(height: AppSpacing.xs),
                _RouteLine(
                  icon: Icons.location_on,
                  value: request.destinationName,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      requestTransitionActionLabelForStatus(request.status) ??
                          'Ver servicio',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
