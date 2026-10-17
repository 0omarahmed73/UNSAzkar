import 'package:flutter/material.dart';

/// P0 design tokens — single source of truth for color, radii, spacing.
abstract final class AppColors {
  static const navy = Color(0xFF0A1B2D);
  static const gold = Color(0xFFD8B75A);
  static const ivory = Color(0xFFF7F4EE);
  static const cardDark = Color(0xFF18334B);

  static const error = Color(0xFFB3261E);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFED6C02);

  static const lightTextPrimary = Color(0xFF1A1C1E);
  static const lightTextSecondary = Color(0xFF5B5E63);
  static const darkTextPrimary = Color(0xFFF5F2EA);
  static const darkTextSecondary = Color(0xFFB9BFC9);
}

abstract final class AppRadii {
  static const card = 24.0;
  static const button = 16.0;
  static const pill = 24.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
