import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';
import 'package:vitago_app/features/requests/views/widgets/request_route_tile.dart';

class RequestSummarySection extends ConsumerWidget {
  const RequestSummarySection({
    required this.profile,
    required this.onOpenRequests,
    super.key,
  });

  final UserProfile profile;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = RequesterSummaryQuery(
      companyId: profile.company?.id,
      branchId: profile.branch?.id,
    );
    final summary = ref.watch(requesterSummaryControllerProvider(query));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Solicitudes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: onOpenRequests,
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          summary.when(
            loading: () => const _SummaryLoading(),
            error: (error, stackTrace) => _SummaryError(
              onRetry: () =>
                  ref.invalidate(requesterSummaryControllerProvider(query)),
            ),
            data: (value) => _SummaryContent(
              summary: value,
              onOpenRequest: (requestId) async {
                await context.pushNamed<void>(
                  'request-detail',
                  pathParameters: {'requestId': requestId},
                );
                ref.invalidate(requesterSummaryControllerProvider(query));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary, required this.onOpenRequest});

  final RequesterSummary summary;
  final ValueChanged<String> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.total}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'solicitudes visibles',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        (constraints.maxWidth - AppSpacing.md) / 3;
                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.md,
                      children: [
                        _Metric(
                          width: itemWidth,
                          value: summary.pending,
                          label: 'Pendientes',
                        ),
                        _Metric(
                          width: itemWidth,
                          value: summary.active,
                          label: 'Activas',
                        ),
                        _Metric(
                          width: itemWidth,
                          value: summary.delivered,
                          label: 'Entregadas',
                        ),
                        _Metric(
                          width: itemWidth,
                          value: summary.failed,
                          label: 'Fallidas',
                        ),
                        _Metric(
                          width: itemWidth,
                          value: summary.cancelled,
                          label: 'Canceladas',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (summary.recent.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'Actividad reciente',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var index = 0; index < summary.recent.length; index++) ...[
              if (index > 0)
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              RequestRouteTile(
                request: summary.recent[index],
                onTap: () => onOpenRequest(summary.recent[index].id),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 112,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Cargando resumen de solicitudes…',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.onRetry});

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
              'No fue posible cargar el resumen.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
