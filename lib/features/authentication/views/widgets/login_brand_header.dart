import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/app/widgets/product_brand_mark.dart';

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({
    required this.appName,
    required this.isCorporate,
    super.key,
  });

  final String appName;
  final bool isCorporate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        height: AppSizes.loginHeroHeight,
        color: colorScheme.primary,
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isCorporate
                          ? 'Logística clínica, en movimiento.'
                          : 'Tu operación logística, en movimiento.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: AppSpacing.lg,
                child: _BrandMark(isCorporate: isCorporate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.isCorporate});

  final bool isCorporate;

  @override
  Widget build(BuildContext context) {
    return ProductBrandMark(
      isCorporate: isCorporate,
      size: AppSizes.loginBrandMark,
      padding: AppSpacing.xs,
      borderWidth: 4,
      showShadow: true,
    );
  }
}
