import 'package:flutter/material.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';

/// Places related form fields side by side only when they have enough room.
///
/// Large accessibility text intentionally switches the fields to a vertical
/// layout, even on a wide screen, so labels and validation messages can wrap.
class AdaptiveFormRow extends StatelessWidget {
  const AdaptiveFormRow({
    required this.children,
    this.flex,
    this.spacing = AppSpacing.sm,
    this.minimumChildWidth = 180,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  final List<Widget> children;
  final List<int>? flex;
  final double spacing;
  final double minimumChildWidth;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final requiredWidth =
            (minimumChildWidth * children.length) +
            (spacing * (children.length - 1));
        final shouldStack =
            constraints.maxWidth < requiredWidth || textScale > 1.25;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSpacing(children, SizedBox(height: spacing)),
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: _withSpacing([
            for (var index = 0; index < children.length; index++)
              Expanded(flex: flex?[index] ?? 1, child: children[index]),
          ], SizedBox(width: spacing)),
        );
      },
    );
  }

  List<Widget> _withSpacing(List<Widget> items, Widget gap) {
    return [
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0) gap,
        items[index],
      ],
    ];
  }
}
