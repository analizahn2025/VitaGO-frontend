import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitago_app/app/config/app_mode.dart';
import 'package:vitago_app/app/theme/app_colors.dart';
import 'package:vitago_app/app/theme/app_design_tokens.dart';
import 'package:vitago_app/app/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('usa la paleta de Analiza en el modo corporativo', () {
      final palette = AppColors.forMode(AppMode.corporate);

      expect(palette.primary, const Color(0xFF2D4B77));
      expect(palette.secondary, const Color(0xFFD1393D));
      expect(palette.accent, const Color(0xFFE94A51));
      expect(palette.neutral, const Color(0xFF6E6F70));
    });

    test('mantiene una paleta general independiente', () {
      expect(AppColors.forMode(AppMode.external), same(AppColors.general));
      expect(AppColors.forMode(AppMode.corporate), same(AppColors.corporate));
    });
  });

  group('AppTheme', () {
    test('construye el tema a partir de la paleta seleccionada', () {
      final theme = AppTheme.forMode(AppMode.corporate);

      expect(theme.colorScheme.primary, AppColors.corporate.primary);
      expect(theme.colorScheme.secondary, AppColors.corporate.secondary);
      expect(theme.colorScheme.tertiary, AppColors.corporate.accent);
      expect(theme.colorScheme.outline, AppColors.corporate.neutral);
      expect(theme.scaffoldBackgroundColor, AppColors.corporate.background);
      expect(theme.appBarTheme.backgroundColor, AppColors.corporate.secondary);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
      expect(theme.appBarTheme.titleTextStyle?.color, Colors.white);
      expect(
        theme.appBarTheme.systemOverlayStyle?.statusBarColor,
        AppColors.corporate.secondary,
      );

      final focusedBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, AppColors.corporate.secondary);
      expect(
        focusedBorder.borderRadius,
        BorderRadius.circular(AppRadii.control),
      );

      final buttonStyle = theme.filledButtonTheme.style!;
      expect(
        buttonStyle.minimumSize?.resolve({}),
        const Size(double.infinity, AppSizes.controlHeight),
      );
    });

    test('mantiene la cabecera independiente de Network', () {
      final theme = AppTheme.forMode(AppMode.external);

      expect(theme.appBarTheme.backgroundColor, AppColors.general.background);
      expect(theme.appBarTheme.foregroundColor, AppColors.general.primary);
      expect(
        theme.appBarTheme.titleTextStyle?.color,
        AppColors.general.primary,
      );
      expect(theme.appBarTheme.systemOverlayStyle, isNull);
    });
  });
}
