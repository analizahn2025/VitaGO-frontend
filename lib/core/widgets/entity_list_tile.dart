import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

class EntityListTile extends StatelessWidget {
  const EntityListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360 || textScale > 1.25;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      if (compact && status != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _EntityStatusBadge(status: status!),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact && status != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _EntityStatusBadge(status: status!),
                ],
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxs),
                    child: Icon(Icons.chevron_right),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EntityStatusBadge extends StatelessWidget {
  const _EntityStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = status.toUpperCase();
    final active = normalized == 'ACTIVO' || normalized == 'APROBADO';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: active ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? colors.onPrimaryContainer : colors.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
