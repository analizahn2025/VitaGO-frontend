import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    required this.message,
    this.supportingText,
    this.icon = Icons.error_outline,
    super.key,
  });

  final String message;
  final String? supportingText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                    if (supportingText case final text?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
