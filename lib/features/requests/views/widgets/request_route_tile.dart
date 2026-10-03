import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/formatters/app_date_format.dart';
import 'package:vitago_app/core/widgets/status_badge.dart';
import 'package:vitago_app/features/requests/models/request_models.dart';

class RequestRouteTile extends StatelessWidget {
  const RequestRouteTile({
    required this.request,
    required this.onTap,
    super.key,
  });

  final ServiceRequestSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RouteRail(isPriority: request.isPriority),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(status: request.status),
                    ],
                  ),
                  if (request.isPriority) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Servicio prioritario',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    requestModalityLabel(request.modality),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    request.origin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    request.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${request.serviceType.name} · ${AppDateFormat.dateTime(request.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxs),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRail extends StatelessWidget {
  const _RouteRail({required this.isPriority});

  final bool isPriority;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final routeColor = isPriority ? colors.error : colors.primary;
    return SizedBox(
      width: 18,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 2, color: routeColor.withValues(alpha: 0.45)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: routeColor, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Icon(Icons.location_on, size: 18, color: routeColor),
          ),
        ],
      ),
    );
  }
}
