import 'package:flutter/material.dart';

class ProductBrandMark extends StatelessWidget {
  const ProductBrandMark({
    required this.isCorporate,
    required this.size,
    this.padding = 2,
    this.borderWidth = 2,
    this.showShadow = false,
    super.key,
  });

  final bool isCorporate;
  final double size;
  final double padding;
  final double borderWidth;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cacheSize = size > 64 ? 384 : 144;

    return RepaintBoundary(
      child: Semantics(
        image: true,
        label: isCorporate
            ? 'Gota de VitaGo en motocicleta'
            : 'Camión de VitaGo Network',
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCorporate ? colorScheme.secondary : colorScheme.primary,
              width: borderWidth,
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: isCorporate
                ? Image.asset(
                    'assets/branding/corporate/app_icon.png',
                    key: const Key('corporate_brand_mark'),
                    cacheWidth: cacheSize,
                    cacheHeight: cacheSize,
                    filterQuality: FilterQuality.medium,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  )
                : ColoredBox(
                    color: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.local_shipping_outlined,
                      key: const Key('network_brand_mark'),
                      size: size * 0.45,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
