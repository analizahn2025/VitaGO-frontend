import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/permissions/scope_type.dart';
import 'package:vitago_app/core/widgets/adaptive_form_row.dart';
import 'package:vitago_app/features/profile/models/user_profile.dart';
import 'package:vitago_app/features/requests/controllers/requests_controller.dart';
import 'package:vitago_app/features/requests/models/request_inputs.dart';
import 'package:vitago_app/features/requests/models/requester_summary.dart';
import 'package:vitago_app/features/requests/views/widgets/request_route_tile.dart';

class RequestSummarySection extends ConsumerStatefulWidget {
  const RequestSummarySection({
    required this.profile,
    required this.onOpenRequests,
    this.isActive = true,
    super.key,
  });

  final UserProfile profile;
  final VoidCallback onOpenRequests;
  final bool isActive;

  @override
  ConsumerState<RequestSummarySection> createState() =>
      _RequestSummarySectionState();
}

class _RequestSummarySectionState extends ConsumerState<RequestSummarySection>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isResumed = true;

  RequesterSummaryQuery get _query => RequesterSummaryQuery(
    companyId: widget.profile.company?.id,
    branchId:
        widget.profile.isMasterAdmin ||
            widget.profile.roles.any(
              (role) => role.scopeType != ScopeType.branch,
            )
        ? null
        : widget.profile.branch?.id,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    _isResumed =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant RequestSummarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _scheduleRefresh();
      if (widget.isActive && _isResumed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.isActive && _isResumed) _refresh();
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasResumed = _isResumed;
    _isResumed = state == AppLifecycleState.resumed;
    _scheduleRefresh();
    if (!wasResumed && _isResumed && widget.isActive) _refresh();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (widget.isActive && _isResumed) {
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _refresh(),
      );
    }
  }

  void _refresh() {
    final provider = requesterSummaryControllerProvider(_query);
    if (!ref.read(provider).isLoading) ref.invalidate(provider);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text(
                'Resumen de envíos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: widget.onOpenRequests,
                child: const Text('Ver solicitudes'),
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
            data: (value) => value.hasDailySummary
                ? _SummaryContent(
                    summary: value,
                    onOpenRequest: (requestId) async {
                      await context.pushNamed<void>(
                        'request-detail',
                        pathParameters: {'requestId': requestId},
                      );
                      if (!mounted) return;
                      ref.invalidate(requesterSummaryControllerProvider(query));
                    },
                  )
                : _SummaryError(
                    message: 'El resumen de hoy aún no está disponible.',
                    onRetry: _refresh,
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
                AdaptiveFormRow(
                  minimumChildWidth: 120,
                  children: [
                    _OperationalMetric(
                      label: 'Pendientes',
                      value: summary.pending,
                      valueKey: const Key('pending_requests_total'),
                      icon: Icons.hourglass_empty_rounded,
                    ),
                    _OperationalMetric(
                      label: 'En progreso',
                      value: summary.active,
                      valueKey: const Key('active_requests_total'),
                      icon: Icons.delivery_dining_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Entregadas hoy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.deliveredToday}',
                  key: const Key('daily_delivery_total'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  summary.deliveredToday == 1
                      ? 'entrega realizada hoy'
                      : 'entregas realizadas hoy',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _displayDate(summary.operationalDate!),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                if (summary.deliveredToday == 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Aún no hay entregas realizadas hoy.'),
                ],
              ],
            ),
          ),
          if (summary.recentDeliveredToday.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'Últimas entregas de hoy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (
              var index = 0;
              index < summary.recentDeliveredToday.length;
              index++
            ) ...[
              if (index > 0)
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              RequestRouteTile(
                request: summary.recentDeliveredToday[index].request,
                deliveredAt: summary.recentDeliveredToday[index].deliveredAt,
                operationalTimeZone: summary.operationalTimeZone,
                onTap: () => onOpenRequest(
                  summary.recentDeliveredToday[index].request.id,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _displayDate(String date) {
    final parts = date.split('-');
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _OperationalMetric extends StatelessWidget {
  const _OperationalMetric({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.icon,
  });

  final String label;
  final int value;
  final Key valueKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: colors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$value',
              key: valueKey,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
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
              'Cargando resumen de envíos…',
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
  const _SummaryError({
    required this.onRetry,
    this.message = 'No fue posible cargar el resumen de envíos.',
  });

  final VoidCallback onRetry;
  final String message;

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
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
