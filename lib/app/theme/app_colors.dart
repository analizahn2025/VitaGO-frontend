import 'package:flutter/material.dart';
import 'package:vitago_app/app/config/app_mode.dart';

/// Colores de marca centralizados por producto.
///
/// Para actualizar una identidad visual solo deben cambiarse los valores HEX
/// de la paleta correspondiente; las vistas no deben declarar colores de marca.
abstract final class AppColors {
  static const corporate = AppPalette(
    primary: Color(0xFF2D4B77),
    secondary: Color(0xFFD1393D),
    accent: Color(0xFFE94A51),
    neutral: Color(0xFF6E6F70),
    background: Color(0xFFF7F8FA),
  );

  // Paleta general provisional. Puede sustituirse aquí cuando sea definida.
  static const general = AppPalette(
    primary: Color(0xFF0B6E69),
    secondary: Color(0xFF087F78),
    accent: Color(0xFF31AFA7),
    neutral: Color(0xFF56615F),
    background: Color(0xFFF7F9F9),
  );

  static AppPalette forMode(AppMode mode) {
    return switch (mode) {
      AppMode.corporate => corporate,
      AppMode.external => general,
    };
  }
}

@immutable
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.neutral,
    required this.background,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color neutral;
  final Color background;
}
