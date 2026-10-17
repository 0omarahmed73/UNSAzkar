import 'package:flutter/material.dart';

import 'tokens.dart';

const _arabicFont = 'Almarai';

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF8A6D1B),
    surface: AppColors.ivory,
    onSurface: AppColors.lightTextPrimary,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ivory,
    fontFamily: _arabicFont,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.gold,
    surface: AppColors.cardDark,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.navy,
    fontFamily: _arabicFont,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}

ThemeData buildAmoledTheme() {
  final base = buildDarkTheme();
  final scheme = base.colorScheme.copyWith(
    surface: Colors.black,
    surfaceContainerLowest: Colors.black,
    surfaceContainerLow: Colors.black,
    surfaceContainer: const Color(0xFF0A0A0A),
    surfaceContainerHigh: const Color(0xFF111111),
  );
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: scheme,
    cardTheme: base.cardTheme.copyWith(
      color: const Color(0xFF0D1620),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: Color(0xFF1A2733)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
    ),
  );
}
