import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/features/tracking/providers/tracking_providers.dart';

class RequiredGpsBody extends ConsumerWidget {
  const RequiredGpsBody({
    required this.child,
    this.enabled = true,
    this.onReportProblem,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onReportProblem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;
    final service = ref.watch(locationServiceEnabledProvider);
    return service.when(
      data: (isEnabled) =>
          isEnabled ? child : _GpsUnavailable(onReportProblem: onReportProblem),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _GpsUnavailable(onReportProblem: onReportProblem),
    );
  }
}

class _GpsUnavailable extends ConsumerWidget {
  const _GpsUnavailable({this.onReportProblem});

  final VoidCallback? onReportProblem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 38,
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'GPS apagado',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No puedes continuar porque tienes el GPS apagado.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(deviceLocationServiceProvider)
                        .openLocationSettings();
                    ref.invalidate(locationServiceEnabledProvider);
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Abrir configuración del GPS'),
                ),
                if (onReportProblem != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onReportProblem,
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Reportar un problema'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
