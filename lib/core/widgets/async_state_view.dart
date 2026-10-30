import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/core/errors/app_failure.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({this.label = 'Cargando…', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class AppErrorView extends StatefulWidget {
  const AppErrorView({
    required this.error,
    required this.onRetry,
    this.title = 'No pudimos cargar esta información',
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;
  final String title;

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  Timer? _retryTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startWait();
  }

  @override
  void didUpdateWidget(covariant AppErrorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.error, widget.error)) _startWait();
  }

  void _startWait() {
    _retryTimer?.cancel();
    final failure = widget.error;
    _remainingSeconds =
        failure is AppFailure && failure.isOperationalRecoveryPending
        ? failure.retryAfterSeconds ?? 5
        : 0;
    if (_remainingSeconds > 0) {
      _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final failure = widget.error;
    final preparing =
        failure is AppFailure && failure.isOperationalRecoveryPending;
    final message = failure is AppFailure
        ? failure.message
        : 'Inténtalo nuevamente.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                preparing
                    ? Icons.hourglass_top_outlined
                    : Icons.cloud_off_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                preparing ? 'Preparando el servicio' : widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: _remainingSeconds > 0 ? null : widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  _remainingSeconds > 0
                      ? 'Reintentar en $_remainingSeconds s'
                      : 'Reintentar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
